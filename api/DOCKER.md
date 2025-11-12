# Guia Docker - API de Predição de Motores

Este guia explica como usar Docker para executar e fazer deploy da API.

## Pré-requisitos

- Docker instalado ([Download Docker](https://www.docker.com/get-started))
- Docker Compose (geralmente vem com Docker Desktop)

## Comandos Básicos

### Construir a Imagem

```bash
docker build -t motor-prediction-api .
```

### Executar Container

```bash
docker run -p 5000:5000 motor-prediction-api
```

### Executar em Background

```bash
docker run -d -p 5000:5000 --name motor-api motor-prediction-api
```

### Ver Logs

```bash
docker logs motor-api
# ou em tempo real
docker logs -f motor-api
```

### Parar Container

```bash
docker stop motor-api
```

### Remover Container

```bash
docker rm motor-api
```

## Docker Compose

### Iniciar Serviços

```bash
docker-compose up
```

### Iniciar em Background

```bash
docker-compose up -d
```

### Parar Serviços

```bash
docker-compose down
```

### Reconstruir e Iniciar

```bash
docker-compose up --build
```

### Ver Logs

```bash
docker-compose logs -f
```

## Testando a API

Após iniciar o container, teste com:

```bash
# Linux/Mac
curl -X POST http://localhost:5000/predict \
  -H "Content-Type: application/json" \
  -d '{"motor_temp": 65.0, "vibration_rms": 2.5, "current": 24.0}'

# Windows PowerShell
Invoke-RestMethod -Uri http://localhost:5000/predict -Method Post `
  -Body '{"motor_temp": 65.0, "vibration_rms": 2.5, "current": 24.0}' `
  -ContentType "application/json"
```

Ou use os scripts de teste:

```bash
# Linux/Mac
chmod +x test_api.sh
./test_api.sh

# Windows
.\test_api.ps1
```

## Deploy na Cloud com Docker

### 1. Docker Hub

```bash
# Login
docker login

# Tag da imagem
docker tag motor-prediction-api seu-usuario/motor-prediction-api:latest

# Push
docker push seu-usuario/motor-prediction-api:latest
```

### 2. Railway

1. Conecte seu repositório GitHub no Railway
2. Railway detecta automaticamente o Dockerfile
3. Deploy automático a cada push

### 3. Render

1. Crie novo Web Service
2. Conecte repositório
3. Selecione "Docker" como ambiente
4. Render usa Dockerfile automaticamente

### 4. Fly.io

```bash
# Instalar flyctl
# https://fly.io/docs/getting-started/installing-flyctl/

# Login
flyctl auth login

# Launch (cria fly.toml)
flyctl launch

# Deploy
flyctl deploy
```

### 5. Google Cloud Run

```bash
# Instalar gcloud CLI
# https://cloud.google.com/sdk/docs/install

# Build e push para Google Container Registry
gcloud builds submit --tag gcr.io/SEU-PROJETO/motor-prediction-api

# Deploy
gcloud run deploy motor-prediction-api \
  --image gcr.io/SEU-PROJETO/motor-prediction-api \
  --platform managed \
  --region us-central1 \
  --allow-unauthenticated
```

### 6. AWS ECS/Fargate

1. Push imagem para Amazon ECR
2. Criar task definition no ECS
3. Criar serviço Fargate
4. Configurar Application Load Balancer

### 7. DigitalOcean App Platform

1. Conecte repositório GitHub
2. Selecione "Docker" como tipo de app
3. DigitalOcean detecta Dockerfile automaticamente
4. Deploy automático

## Variáveis de Ambiente

Para usar variáveis de ambiente no Docker:

```bash
# Docker run
docker run -p 5000:5000 -e PORT=5000 motor-prediction-api

# Docker Compose (edite docker-compose.yml)
services:
  api:
    environment:
      - PORT=5000
      - FLASK_ENV=production
```

## Troubleshooting

### Porta já em uso

```bash
# Use outra porta
docker run -p 8080:5000 motor-prediction-api
```

### Ver processos rodando

```bash
docker ps
```

### Entrar no container

```bash
docker exec -it motor-api /bin/bash
```

### Limpar imagens não usadas

```bash
docker system prune -a
```

## Otimizações

### Multi-stage Build (para produção)

O Dockerfile atual já está otimizado, mas você pode adicionar multi-stage build se necessário:

```dockerfile
# Stage 1: Build
FROM python:3.11-slim as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --user -r requirements.txt

# Stage 2: Runtime
FROM python:3.11-slim
WORKDIR /app
COPY --from=builder /root/.local /root/.local
COPY app.py .
ENV PATH=/root/.local/bin:$PATH
CMD ["gunicorn", "app:app", "--bind", "0.0.0.0:5000"]
```

### Cache de Layers

O Dockerfile está organizado para maximizar cache:
1. Instala dependências do sistema
2. Copia requirements.txt
3. Instala dependências Python
4. Copia código da aplicação

Isso permite que mudanças no código não reconstruam as dependências.

