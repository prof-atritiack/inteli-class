# Script de Deploy Automatizado para Azure (PowerShell)
# Uso: .\deploy-azure.ps1

# Configurações - AJUSTE AQUI SE NECESSÁRIO
$resourceGroup = "motor-api-rg"
$location = "eastus"
$acrName = "motorapiregistry"  # Deve ser único globalmente (apenas letras minúsculas e números)
$appName = "motor-prediction-api"  # Deve ser único globalmente
$imageName = "motor-prediction-api"

Write-Host "=== Deploy na Azure ===" -ForegroundColor Cyan
Write-Host ""

# Verificar se Azure CLI está instalado
try {
    $azVersion = az --version 2>&1 | Select-Object -First 1
    Write-Host "Azure CLI encontrado: $azVersion" -ForegroundColor Green
} catch {
    Write-Host "ERRO: Azure CLI não encontrado!" -ForegroundColor Red
    Write-Host "Instale em: https://docs.microsoft.com/cli/azure/install-azure-cli" -ForegroundColor Yellow
    exit 1
}

# Login
Write-Host "Fazendo login na Azure..." -ForegroundColor Yellow
az login
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERRO: Falha no login" -ForegroundColor Red
    exit 1
}

# Criar Resource Group
Write-Host ""
Write-Host "Criando Resource Group: $resourceGroup..." -ForegroundColor Yellow
az group create --name $resourceGroup --location $location
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERRO: Falha ao criar Resource Group" -ForegroundColor Red
    exit 1
}

# Criar ACR
Write-Host ""
Write-Host "Criando Azure Container Registry: $acrName..." -ForegroundColor Yellow
Write-Host "NOTA: O nome do ACR deve ser único globalmente. Se falhar, escolha outro nome." -ForegroundColor Gray
az acr create --resource-group $resourceGroup `
  --name $acrName `
  --sku Basic `
  --admin-enabled true
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERRO: Falha ao criar ACR. Tente outro nome." -ForegroundColor Red
    exit 1
}

# Login no ACR
Write-Host ""
Write-Host "Fazendo login no ACR..." -ForegroundColor Yellow
az acr login --name $acrName
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERRO: Falha ao fazer login no ACR" -ForegroundColor Red
    exit 1
}

# Build e Push
Write-Host ""
Write-Host "Construindo imagem Docker..." -ForegroundColor Yellow
Set-Location api
docker build -t "${acrName}.azurecr.io/${imageName}:latest" .
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERRO: Falha ao construir imagem Docker" -ForegroundColor Red
    Set-Location ..
    exit 1
}

Write-Host "Fazendo push da imagem para ACR..." -ForegroundColor Yellow
docker push "${acrName}.azurecr.io/${imageName}:latest"
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERRO: Falha ao fazer push da imagem" -ForegroundColor Red
    Set-Location ..
    exit 1
}
Set-Location ..

# Criar App Service Plan
Write-Host ""
Write-Host "Criando App Service Plan..." -ForegroundColor Yellow
az appservice plan create `
  --name "${appName}-plan" `
  --resource-group $resourceGroup `
  --location $location `
  --is-linux `
  --sku B1
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERRO: Falha ao criar App Service Plan" -ForegroundColor Red
    exit 1
}

# Criar Web App
Write-Host ""
Write-Host "Criando Web App: $appName..." -ForegroundColor Yellow
Write-Host "NOTA: O nome da app deve ser único globalmente. Se falhar, escolha outro nome." -ForegroundColor Gray
az webapp create `
  --resource-group $resourceGroup `
  --plan "${appName}-plan" `
  --name $appName `
  --deployment-container-image-name "${acrName}.azurecr.io/${imageName}:latest"
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERRO: Falha ao criar Web App. Tente outro nome." -ForegroundColor Red
    exit 1
}

# Obter credenciais do ACR
Write-Host ""
Write-Host "Configurando credenciais do ACR..." -ForegroundColor Yellow
$acrUsername = az acr credential show --name $acrName --query "username" --output tsv
$acrPassword = az acr credential show --name $acrName --query "passwords[0].value" --output tsv

if (-not $acrUsername -or -not $acrPassword) {
    Write-Host "ERRO: Falha ao obter credenciais do ACR" -ForegroundColor Red
    exit 1
}

# Configurar container
az webapp config container set `
  --name $appName `
  --resource-group $resourceGroup `
  --docker-custom-image-name "${acrName}.azurecr.io/${imageName}:latest" `
  --docker-registry-server-url "https://${acrName}.azurecr.io" `
  --docker-registry-server-user $acrUsername `
  --docker-registry-server-password $acrPassword
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERRO: Falha ao configurar container" -ForegroundColor Red
    exit 1
}

# Configurar porta
Write-Host ""
Write-Host "Configurando porta da aplicação..." -ForegroundColor Yellow
az webapp config appsettings set `
  --resource-group $resourceGroup `
  --name $appName `
  --settings WEBSITES_PORT=5000
if ($LASTEXITCODE -ne 0) {
    Write-Host "AVISO: Falha ao configurar porta (pode não ser crítico)" -ForegroundColor Yellow
}

# Obter URL
Write-Host ""
Write-Host "Obtendo URL da aplicação..." -ForegroundColor Yellow
$url = az webapp show --resource-group $resourceGroup `
  --name $appName `
  --query defaultHostName --output tsv

if (-not $url) {
    Write-Host "ERRO: Falha ao obter URL" -ForegroundColor Red
    exit 1
}

# Aguardar alguns segundos para a app iniciar
Write-Host ""
Write-Host "Aguardando aplicação iniciar (30 segundos)..." -ForegroundColor Yellow
Start-Sleep -Seconds 30

# Testar health endpoint
Write-Host ""
Write-Host "Testando health endpoint..." -ForegroundColor Yellow
try {
    $healthResponse = Invoke-RestMethod -Uri "https://$url/health" -Method Get -TimeoutSec 10
    Write-Host "Health check: OK" -ForegroundColor Green
} catch {
    Write-Host "AVISO: Health check falhou (aplicação pode estar ainda iniciando)" -ForegroundColor Yellow
}

# Resultado final
Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "=== Deploy Concluído com Sucesso! ===" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "URL da API: https://$url" -ForegroundColor Cyan
Write-Host "Endpoint de predição: https://$url/predict" -ForegroundColor Cyan
Write-Host "Health check: https://$url/health" -ForegroundColor Cyan
Write-Host ""
Write-Host "Para ver logs:" -ForegroundColor Yellow
Write-Host "  az webapp log tail --name $appName --resource-group $resourceGroup" -ForegroundColor Gray
Write-Host ""
Write-Host "Para deletar recursos:" -ForegroundColor Yellow
Write-Host "  az group delete --name $resourceGroup --yes" -ForegroundColor Gray
Write-Host ""

