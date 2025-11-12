# Quick Start - API Docker

Guia rápido para executar a API com Docker.

## Teste Local Rápido

### 1. Construir e Executar

```bash
cd api
docker-compose up --build
```

A API estará disponível em: `http://localhost:5000`

### 2. Testar a API

**Linux/Mac:**
```bash
curl -X POST http://localhost:5000/predict \
  -H "Content-Type: application/json" \
  -d '{"motor_temp": 65.0, "vibration_rms": 2.5, "current": 24.0}'
```

**Windows PowerShell:**
```powershell
Invoke-RestMethod -Uri http://localhost:5000/predict -Method Post `
  -Body '{"motor_temp": 65.0, "vibration_rms": 2.5, "current": 24.0}' `
  -ContentType "application/json"
```

**Ou use o script de teste:**
```bash
# Linux/Mac
chmod +x test_api.sh && ./test_api.sh

# Windows
.\test_api.ps1
```

### 3. Parar o Container

```bash
docker-compose down
```

## Deploy Rápido na Cloud

### Azure (Recomendado)

**Pré-requisito**: Instalar Azure CLI ([Download](https://docs.microsoft.com/cli/azure/install-azure-cli))

**Opção 1: Script Automatizado (Mais Fácil)**
```powershell
# Execute o script de deploy
.\deploy-azure.ps1
```

**Opção 2: Manual**
Veja o guia completo em `AZURE_DEPLOY.md`

### Outras Opções

**Railway:**
1. Acesse https://railway.app
2. Login com GitHub
3. "New Project" > "Deploy from GitHub repo"
4. Railway detecta Dockerfile automaticamente

**Render:**
1. Acesse https://render.com
2. "New +" > "Web Service"
3. Selecione "Docker" como ambiente

## Atualizar Node-RED

Após fazer deploy, atualize a URL no Node-RED:

1. Abra `fluxo_NODERED_02.json` no Node-RED
2. No nó "HTTP – Chama API Colab"
3. Altere a URL para: `https://sua-api.railway.app/predict` (ou sua URL)

## Próximos Passos

- Ver documentação completa: `DOCKER.md`
- Ver guia de deploy: `../GUIA_API_CLOUD.md`
- Integrar modelo de ML treinado no `app.py`

