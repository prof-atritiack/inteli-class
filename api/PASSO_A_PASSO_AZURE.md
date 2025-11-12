# Passo a Passo - Teste Local e Deploy Azure

Guia simplificado para testar localmente e fazer deploy na Azure.

## PARTE 1: Teste Local com Docker

### Passo 1: Verificar Docker

```powershell
docker --version
docker-compose --version
```

Se não tiver instalado: [Download Docker Desktop](https://www.docker.com/products/docker-desktop)

### Passo 2: Navegar para a pasta da API

```powershell
cd api
```

### Passo 3: Construir e Executar

```powershell
docker-compose up --build
```

Aguarde até ver: `Booting worker with pid: X`

### Passo 4: Testar (em outro terminal PowerShell)

```powershell
# Teste simples
Invoke-RestMethod -Uri http://localhost:5000/health -Method Get

# Ou use o script completo
.\test_api.ps1
```

### Passo 5: Parar o Container

No terminal onde está rodando, pressione `Ctrl+C` ou:

```powershell
docker-compose down
```

---

## PARTE 2: Deploy na Azure

### Passo 1: Instalar Azure CLI

Baixe e instale: https://docs.microsoft.com/cli/azure/install-azure-cli

Verifique instalação:
```powershell
az --version
```

### Passo 2: Login na Azure

```powershell
az login
```

Isso abrirá o navegador para autenticação.

### Passo 3: Executar Script de Deploy

```powershell
# Certifique-se de estar na pasta api
cd api

# Execute o script
.\deploy-azure.ps1
```

O script vai:
1. Criar Resource Group
2. Criar Container Registry (ACR)
3. Construir e fazer push da imagem
4. Criar App Service
5. Configurar tudo automaticamente
6. Mostrar a URL final

**IMPORTANTE**: 
- O nome do ACR deve ser único (apenas letras minúsculas e números)
- O nome da App também deve ser único
- Se falhar, edite o script e escolha outros nomes

### Passo 4: Aguardar Deploy

O deploy leva cerca de 3-5 minutos. O script aguarda automaticamente.

### Passo 5: Testar API na Azure

Após o deploy, você receberá uma URL como:
`https://motor-prediction-api.azurewebsites.net`

Teste:
```powershell
# Health check
Invoke-RestMethod -Uri "https://SUA-URL.azurewebsites.net/health" -Method Get

# Predição
$body = @{
    motor_temp = 65.0
    vibration_rms = 2.5
    current = 24.0
} | ConvertTo-Json

Invoke-RestMethod -Uri "https://SUA-URL.azurewebsites.net/predict" `
  -Method Post -Body $body -ContentType "application/json"
```

---

## PARTE 3: Atualizar Node-RED

### Passo 1: Abrir Fluxo Node-RED

1. Abra o Node-RED
2. Importe o fluxo `fluxo_NODERED_02.json` (se ainda não tiver)

### Passo 2: Atualizar URL da API

1. Clique no nó "HTTP – Chama API Colab"
2. No campo "URL", altere para:
   ```
   https://SUA-URL.azurewebsites.net/predict
   ```
3. Clique em "Deploy"

### Passo 3: Testar Fluxo

Envie uma mensagem MQTT e verifique se a API responde corretamente.

---

## Troubleshooting

### Docker não inicia
- Verifique se o Docker Desktop está rodando
- Reinicie o Docker Desktop

### Erro: "porta já em uso"
```powershell
# Ver o que está usando a porta 5000
netstat -ano | findstr :5000

# Ou use outra porta no docker-compose.yml
```

### Erro no deploy Azure: "nome já existe"
- Edite `deploy-azure.ps1` e escolha nomes únicos:
  - `$acrName = "seu-nome-unico-acr"`
  - `$appName = "seu-nome-unico-app"`

### App não responde após deploy
```powershell
# Ver logs
az webapp log tail --name motor-prediction-api --resource-group motor-api-rg

# Ver status
az webapp show --name motor-prediction-api --resource-group motor-api-rg
```

### Re-fazer deploy após mudanças no código

```powershell
cd api

# Reconstruir imagem
docker build -t motorapiregistry.azurecr.io/motor-prediction-api:latest .

# Push
docker push motorapiregistry.azurecr.io/motor-prediction-api:latest

# Reiniciar app
az webapp restart --name motor-prediction-api --resource-group motor-api-rg
```

---

## Limpar Recursos (Evitar Custos)

Para deletar tudo na Azure:

```powershell
az group delete --name motor-api-rg --yes
```

Isso remove todos os recursos criados e para a cobrança.

---

## Resumo dos Comandos Principais

```powershell
# Teste local
cd api
docker-compose up --build

# Deploy Azure
.\deploy-azure.ps1

# Ver logs Azure
az webapp log tail --name motor-prediction-api --resource-group motor-api-rg

# Deletar tudo
az group delete --name motor-api-rg --yes
```

---

## Próximos Passos

1. ✅ Testar localmente
2. ✅ Deploy na Azure
3. ✅ Atualizar Node-RED
4. Integrar modelo de ML (opcional)
5. Configurar CI/CD (opcional)
6. Adicionar monitoramento (opcional)

