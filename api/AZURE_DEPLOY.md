# Deploy na Azure - Guia Completo

Este guia mostra como fazer deploy da API na Azure usando Docker.

## Pré-requisitos

1. **Conta Azure** (https://azure.microsoft.com/free/)
2. **Azure CLI instalado** ([Download](https://docs.microsoft.com/cli/azure/install-azure-cli))
3. **Docker instalado** (já temos isso)

## Opção 1: Azure Container Instances (ACI) - Mais Simples

### Passo 1: Login na Azure

```bash
az login
```

### Passo 2: Criar Grupo de Recursos

```bash
az group create --name motor-api-rg --location eastus
```

### Passo 3: Criar Container Registry (ACR)

```bash
# Criar registry (nome deve ser único globalmente)
az acr create --resource-group motor-api-rg \
  --name motorapiregistry \
  --sku Basic \
  --admin-enabled true
```

### Passo 4: Fazer Login no Registry

```bash
az acr login --name motorapiregistry
```

### Passo 5: Construir e Fazer Push da Imagem

```bash
cd api

# Tag da imagem
docker tag motor-prediction-api motorapiregistry.azurecr.io/motor-prediction-api:latest

# Push para ACR
docker push motorapiregistry.azurecr.io/motor-prediction-api:latest
```

### Passo 6: Criar Container Instance

```bash
az container create \
  --resource-group motor-api-rg \
  --name motor-prediction-api \
  --image motorapiregistry.azurecr.io/motor-prediction-api:latest \
  --registry-login-server motorapiregistry.azurecr.io \
  --registry-username motorapiregistry \
  --registry-password $(az acr credential show --name motorapiregistry --query "passwords[0].value" --output tsv) \
  --dns-name-label motor-api \
  --ports 5000 \
  --cpu 1 \
  --memory 1
```

### Passo 7: Obter URL da API

```bash
az container show --resource-group motor-api-rg \
  --name motor-prediction-api \
  --query ipAddress.fqdn --output tsv
```

A URL será: `http://motor-api.eastus.azurecontainer.io:5000`

---

## Opção 2: Azure App Service - Recomendado para Produção

### Passo 1: Criar App Service Plan

```bash
az appservice plan create \
  --name motor-api-plan \
  --resource-group motor-api-rg \
  --location eastus \
  --is-linux \
  --sku B1
```

### Passo 2: Criar Web App com Container

```bash
az webapp create \
  --resource-group motor-api-rg \
  --plan motor-api-plan \
  --name motor-prediction-api \
  --deployment-container-image-name motorapiregistry.azurecr.io/motor-prediction-api:latest
```

### Passo 3: Configurar Credenciais do Registry

```bash
# Obter credenciais do ACR
ACR_USERNAME=$(az acr credential show --name motorapiregistry --query "username" --output tsv)
ACR_PASSWORD=$(az acr credential show --name motorapiregistry --query "passwords[0].value" --output tsv)

# Configurar no App Service
az webapp config container set \
  --name motor-prediction-api \
  --resource-group motor-api-rg \
  --docker-custom-image-name motorapiregistry.azurecr.io/motor-prediction-api:latest \
  --docker-registry-server-url https://motorapiregistry.azurecr.io \
  --docker-registry-server-user $ACR_USERNAME \
  --docker-registry-server-password $ACR_PASSWORD
```

### Passo 4: Configurar Porta

```bash
az webapp config appsettings set \
  --resource-group motor-api-rg \
  --name motor-prediction-api \
  --settings WEBSITES_PORT=5000
```

### Passo 5: Obter URL

```bash
az webapp show --resource-group motor-api-rg \
  --name motor-prediction-api \
  --query defaultHostName --output tsv
```

A URL será: `https://motor-prediction-api.azurewebsites.net`

---

## Opção 3: Azure Container Apps - Moderno e Serverless

### Passo 1: Criar Container Apps Environment

```bash
az containerapp env create \
  --name motor-api-env \
  --resource-group motor-api-rg \
  --location eastus
```

### Passo 2: Criar Container App

```bash
az containerapp create \
  --name motor-prediction-api \
  --resource-group motor-api-rg \
  --environment motor-api-env \
  --image motorapiregistry.azurecr.io/motor-prediction-api:latest \
  --registry-server motorapiregistry.azurecr.io \
  --registry-username motorapiregistry \
  --registry-password $(az acr credential show --name motorapiregistry --query "passwords[0].value" --output tsv) \
  --target-port 5000 \
  --ingress external \
  --cpu 0.5 \
  --memory 1.0Gi
```

### Passo 3: Obter URL

```bash
az containerapp show \
  --name motor-prediction-api \
  --resource-group motor-api-rg \
  --query properties.configuration.ingress.fqdn \
  --output tsv
```

---

## Script Automatizado (Bash)

Crie um arquivo `deploy-azure.sh`:

```bash
#!/bin/bash

# Configurações
RESOURCE_GROUP="motor-api-rg"
LOCATION="eastus"
ACR_NAME="motorapiregistry"
APP_NAME="motor-prediction-api"
IMAGE_NAME="motor-prediction-api"

echo "=== Deploy na Azure ==="

# Login
echo "Fazendo login na Azure..."
az login

# Criar Resource Group
echo "Criando Resource Group..."
az group create --name $RESOURCE_GROUP --location $LOCATION

# Criar ACR
echo "Criando Azure Container Registry..."
az acr create --resource-group $RESOURCE_GROUP \
  --name $ACR_NAME \
  --sku Basic \
  --admin-enabled true

# Login no ACR
echo "Fazendo login no ACR..."
az acr login --name $ACR_NAME

# Build e Push
echo "Construindo e fazendo push da imagem..."
cd api
docker build -t $ACR_NAME.azurecr.io/$IMAGE_NAME:latest .
docker push $ACR_NAME.azurecr.io/$IMAGE_NAME:latest
cd ..

# Criar App Service
echo "Criando App Service Plan..."
az appservice plan create \
  --name ${APP_NAME}-plan \
  --resource-group $RESOURCE_GROUP \
  --location $LOCATION \
  --is-linux \
  --sku B1

echo "Criando Web App..."
az webapp create \
  --resource-group $RESOURCE_GROUP \
  --plan ${APP_NAME}-plan \
  --name $APP_NAME \
  --deployment-container-image-name $ACR_NAME.azurecr.io/$IMAGE_NAME:latest

# Configurar credenciais
echo "Configurando credenciais..."
ACR_USERNAME=$(az acr credential show --name $ACR_NAME --query "username" --output tsv)
ACR_PASSWORD=$(az acr credential show --name $ACR_NAME --query "passwords[0].value" --output tsv)

az webapp config container set \
  --name $APP_NAME \
  --resource-group $RESOURCE_GROUP \
  --docker-custom-image-name $ACR_NAME.azurecr.io/$IMAGE_NAME:latest \
  --docker-registry-server-url https://$ACR_NAME.azurecr.io \
  --docker-registry-server-user $ACR_USERNAME \
  --docker-registry-server-password $ACR_PASSWORD

# Configurar porta
az webapp config appsettings set \
  --resource-group $RESOURCE_GROUP \
  --name $APP_NAME \
  --settings WEBSITES_PORT=5000

# Obter URL
URL=$(az webapp show --resource-group $RESOURCE_GROUP \
  --name $APP_NAME \
  --query defaultHostName --output tsv)

echo ""
echo "=== Deploy Concluído! ==="
echo "URL da API: https://$URL"
echo "Endpoint de predição: https://$URL/predict"
```

---

## Script Automatizado (PowerShell)

Crie um arquivo `deploy-azure.ps1`:

```powershell
# Configurações
$resourceGroup = "motor-api-rg"
$location = "eastus"
$acrName = "motorapiregistry"
$appName = "motor-prediction-api"
$imageName = "motor-prediction-api"

Write-Host "=== Deploy na Azure ===" -ForegroundColor Cyan

# Login
Write-Host "Fazendo login na Azure..." -ForegroundColor Yellow
az login

# Criar Resource Group
Write-Host "Criando Resource Group..." -ForegroundColor Yellow
az group create --name $resourceGroup --location $location

# Criar ACR
Write-Host "Criando Azure Container Registry..." -ForegroundColor Yellow
az acr create --resource-group $resourceGroup `
  --name $acrName `
  --sku Basic `
  --admin-enabled true

# Login no ACR
Write-Host "Fazendo login no ACR..." -ForegroundColor Yellow
az acr login --name $acrName

# Build e Push
Write-Host "Construindo e fazendo push da imagem..." -ForegroundColor Yellow
Set-Location api
docker build -t "${acrName}.azurecr.io/${imageName}:latest" .
docker push "${acrName}.azurecr.io/${imageName}:latest"
Set-Location ..

# Criar App Service
Write-Host "Criando App Service Plan..." -ForegroundColor Yellow
az appservice plan create `
  --name "${appName}-plan" `
  --resource-group $resourceGroup `
  --location $location `
  --is-linux `
  --sku B1

Write-Host "Criando Web App..." -ForegroundColor Yellow
az webapp create `
  --resource-group $resourceGroup `
  --plan "${appName}-plan" `
  --name $appName `
  --deployment-container-image-name "${acrName}.azurecr.io/${imageName}:latest"

# Configurar credenciais
Write-Host "Configurando credenciais..." -ForegroundColor Yellow
$acrUsername = az acr credential show --name $acrName --query "username" --output tsv
$acrPassword = az acr credential show --name $acrName --query "passwords[0].value" --output tsv

az webapp config container set `
  --name $appName `
  --resource-group $resourceGroup `
  --docker-custom-image-name "${acrName}.azurecr.io/${imageName}:latest" `
  --docker-registry-server-url "https://${acrName}.azurecr.io" `
  --docker-registry-server-user $acrUsername `
  --docker-registry-server-password $acrPassword

# Configurar porta
az webapp config appsettings set `
  --resource-group $resourceGroup `
  --name $appName `
  --settings WEBSITES_PORT=5000

# Obter URL
$url = az webapp show --resource-group $resourceGroup `
  --name $appName `
  --query defaultHostName --output tsv

Write-Host ""
Write-Host "=== Deploy Concluído! ===" -ForegroundColor Green
Write-Host "URL da API: https://$url" -ForegroundColor Green
Write-Host "Endpoint de predição: https://$url/predict" -ForegroundColor Green
```

---

## Testar Localmente Primeiro

Antes de fazer deploy, teste localmente:

```bash
cd api
docker-compose up --build
```

Em outro terminal, teste:

```bash
# Windows PowerShell
.\test_api.ps1

# Linux/Mac
chmod +x test_api.sh && ./test_api.sh
```

---

## Atualizar Imagem no Azure

Quando fizer alterações no código:

```bash
# 1. Reconstruir imagem
cd api
docker build -t motorapiregistry.azurecr.io/motor-prediction-api:latest .

# 2. Push para ACR
docker push motorapiregistry.azurecr.io/motor-prediction-api:latest

# 3. Reiniciar App Service
az webapp restart --name motor-prediction-api --resource-group motor-api-rg
```

---

## Monitoramento

### Ver Logs

```bash
# App Service
az webapp log tail --name motor-prediction-api --resource-group motor-api-rg

# Container Instance
az container logs --name motor-prediction-api --resource-group motor-api-rg
```

### Ver Status

```bash
az webapp show --name motor-prediction-api --resource-group motor-api-rg
```

---

## Limpar Recursos

Para deletar tudo e evitar custos:

```bash
az group delete --name motor-api-rg --yes --no-wait
```

---

## Custos Estimados

- **Azure Container Instances**: ~$0.000012/GB-segundo + armazenamento
- **App Service B1**: ~$13/mês
- **Container Registry Basic**: ~$5/mês
- **Container Apps**: Pay-per-use (muito barato para começar)

**Total estimado para começar**: ~$18-20/mês (App Service + ACR)

---

## Troubleshooting

### Erro: Registry não encontrado
- Verifique se o ACR foi criado: `az acr list`

### Erro: Imagem não encontrada
- Verifique se o push foi feito: `az acr repository list --name motorapiregistry`

### App não inicia
- Verifique logs: `az webapp log tail --name motor-prediction-api --resource-group motor-api-rg`

### Porta incorreta
- Verifique configuração: `az webapp config appsettings list --name motor-prediction-api --resource-group motor-api-rg`

---

## Próximos Passos

1. Configurar domínio personalizado (opcional)
2. Adicionar SSL/HTTPS (já vem por padrão no App Service)
3. Configurar autenticação Azure AD (opcional)
4. Adicionar Application Insights para monitoramento
5. Configurar CI/CD com Azure DevOps ou GitHub Actions

