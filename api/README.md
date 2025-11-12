# API de Predição de Anomalias em Motores

API Flask para predição de anomalias em motores elétricos baseada em dados de sensores.

## Estrutura

```
api/
├── app.py              # Código principal da API
├── requirements.txt    # Dependências Python
├── Procfile           # Configuração para Heroku/Railway
├── Dockerfile         # Configuração Docker
├── docker-compose.yml # Orquestração Docker
├── .dockerignore      # Arquivos ignorados no build
└── README.md          # Este arquivo
```

## Instalação Local

### Opção 1: Docker (Recomendado)

1. **Construir e executar com Docker Compose**
   ```bash
   docker-compose up --build
   ```

2. **Ou apenas com Docker**
   ```bash
   # Construir imagem
   docker build -t motor-prediction-api .
   
   # Executar container
   docker run -p 5000:5000 motor-prediction-api
   ```

3. **Testar**
   ```bash
   curl -X POST http://localhost:5000/predict \
     -H "Content-Type: application/json" \
     -d '{
       "motor_temp": 65.0,
       "vibration_rms": 2.5,
       "current": 24.0
     }'
   ```

### Opção 2: Python Local

1. **Criar ambiente virtual**
   ```bash
   python -m venv venv
   source venv/bin/activate  # Linux/Mac
   # ou
   venv\Scripts\activate  # Windows
   ```

2. **Instalar dependências**
   ```bash
   pip install -r requirements.txt
   ```

3. **Executar API**
   ```bash
   python app.py
   ```

4. **Testar**
   ```bash
   curl -X POST http://localhost:5000/predict \
     -H "Content-Type: application/json" \
     -d '{
       "motor_temp": 65.0,
       "vibration_rms": 2.5,
       "current": 24.0
     }'
   ```

## Deploy na Cloud

### Docker Hub + Qualquer Plataforma

1. **Construir e fazer push para Docker Hub**
   ```bash
   docker build -t seu-usuario/motor-prediction-api .
   docker push seu-usuario/motor-prediction-api
   ```

2. **Deploy em plataformas que suportam Docker:**
   - **Railway**: Conecte repositório, Railway detecta Dockerfile automaticamente
   - **Render**: Selecione "Docker" como ambiente
   - **Fly.io**: `flyctl launch` e configure Dockerfile
   - **DigitalOcean App Platform**: Conecte repositório com Dockerfile
   - **AWS ECS/Fargate**: Use imagem do Docker Hub
   - **Google Cloud Run**: `gcloud run deploy --image seu-usuario/motor-prediction-api`

### Heroku (sem Docker)

```bash
heroku create sua-api-motor
git push heroku main
```

### Railway (com Docker)

1. Conecte seu repositório GitHub
2. Railway detecta Dockerfile automaticamente e faz deploy

### Render (com Docker)

1. Crie novo Web Service
2. Conecte repositório
3. Selecione "Docker" como ambiente
4. Render usa Dockerfile automaticamente

## Endpoints

### POST /predict

Prediz anomalia baseado em dados do motor.

**Request:**
```json
{
  "motor_temp": 65.0,
  "vibration_rms": 2.5,
  "current": 24.0
}
```

**Response:**
```json
{
  "prediction": 0,
  "probability": 0.2,
  "status": "normal",
  "input": {
    "motor_temp": 65.0,
    "vibration_rms": 2.5,
    "current": 24.0
  }
}
```

### GET /health

Health check da API.

**Response:**
```json
{
  "status": "ok",
  "service": "motor-prediction-api"
}
```

## Melhorias Futuras

1. Integrar modelo de ML treinado (scikit-learn, TensorFlow, etc.)
2. Adicionar autenticação (API keys)
3. Implementar rate limiting
4. Adicionar logging estruturado
5. Implementar cache de predições
6. Adicionar métricas e monitoramento

