# Guia: Criando API de Predição na Cloud

Este guia apresenta os passos para criar e deployar a API de predição de anomalias em motores na cloud.

## Formato da API

### Entrada (Request)
A API recebe requisições POST no endpoint `/predict` com o seguinte formato JSON:

```json
{
  "motor_temp": 65.0,
  "vibration_rms": 2.5,
  "current": 24.0
}
```

### Saída (Response)
A API deve retornar uma predição, por exemplo:

```json
{
  "prediction": 0,
  "probability": 0.15,
  "status": "normal"
}
```

ou

```json
{
  "prediction": 1,
  "probability": 0.87,
  "status": "anomalia"
}
```

## Opções de Deploy na Cloud

### Opção 1: Google Colab + ngrok (Desenvolvimento/Teste)

**Vantagens**: Gratuito, rápido para testes, fácil de configurar
**Desvantagens**: Temporário, requer sessão ativa, não é produção

#### Passos:

1. **Criar notebook no Google Colab**
   - Acesse https://colab.research.google.com
   - Crie um novo notebook

2. **Instalar dependências**
   ```python
   !pip install flask flask-cors ngrok pyngrok scikit-learn pandas numpy
   ```

3. **Criar API Flask**
   ```python
   from flask import Flask, request, jsonify
   from flask_cors import CORS
   import pickle
   import numpy as np
   
   app = Flask(__name__)
   CORS(app)
   
   # Carregar modelo (se tiver um modelo treinado)
   # model = pickle.load(open('modelo.pkl', 'rb'))
   
   @app.route('/predict', methods=['POST'])
   def predict():
       try:
           data = request.get_json()
           
           motor_temp = float(data['motor_temp'])
           vibration_rms = float(data['vibration_rms'])
           current = float(data['current'])
           
           # Preparar features
           features = np.array([[motor_temp, vibration_rms, current]])
           
           # Fazer predição (exemplo com regras simples)
           # prediction = model.predict(features)[0]
           # probability = model.predict_proba(features)[0][1]
           
           # Exemplo com regras simples (substitua pelo seu modelo)
           if motor_temp > 100 or vibration_rms > 5 or current > 35:
               prediction = 1
               probability = 0.85
               status = "anomalia"
           else:
               prediction = 0
               probability = 0.15
               status = "normal"
           
           return jsonify({
               'prediction': int(prediction),
               'probability': float(probability),
               'status': status
           })
       except Exception as e:
           return jsonify({'error': str(e)}), 400
   
   if __name__ == '__main__':
       from pyngrok import ngrok
       
       # Criar túnel ngrok
       public_url = ngrok.connect(5000)
       print(f"API disponível em: {public_url}")
       
       app.run(port=5000)
   ```

4. **Executar a célula**
   - O ngrok gerará uma URL pública
   - Copie a URL e atualize no Node-RED

---

### Opção 2: Heroku (Recomendado para Produção)

**Vantagens**: Gratuito (tier básico), fácil deploy, escalável
**Desvantagens**: Requer conta Heroku, pode ter cold start

#### Passos:

1. **Instalar Heroku CLI**
   - Baixe em: https://devcenter.heroku.com/articles/heroku-cli

2. **Criar estrutura do projeto**
   ```
   api-motor-prediction/
   ├── app.py
   ├── requirements.txt
   ├── Procfile
   └── modelo.pkl (se tiver modelo treinado)
   ```

3. **Criar app.py**
   ```python
   from flask import Flask, request, jsonify
   from flask_cors import CORS
   import pickle
   import numpy as np
   import os
   
   app = Flask(__name__)
   CORS(app)
   
   # Carregar modelo
   try:
       model = pickle.load(open('modelo.pkl', 'rb'))
   except:
       model = None
       print("Modelo não encontrado, usando regras simples")
   
   @app.route('/predict', methods=['POST'])
   def predict():
       try:
           data = request.get_json()
           
           motor_temp = float(data['motor_temp'])
           vibration_rms = float(data['vibration_rms'])
           current = float(data['current'])
           
           features = np.array([[motor_temp, vibration_rms, current]])
           
           if model:
               prediction = model.predict(features)[0]
               probability = model.predict_proba(features)[0][1]
           else:
               # Regras simples como fallback
               if motor_temp > 100 or vibration_rms > 5 or current > 35:
                   prediction = 1
                   probability = 0.85
               else:
                   prediction = 0
                   probability = 0.15
           
           status = "anomalia" if prediction == 1 else "normal"
           
           return jsonify({
               'prediction': int(prediction),
               'probability': float(probability),
               'status': status
           })
       except Exception as e:
           return jsonify({'error': str(e)}), 400
   
   @app.route('/health', methods=['GET'])
   def health():
       return jsonify({'status': 'ok'})
   
   if __name__ == '__main__':
       port = int(os.environ.get('PORT', 5000))
       app.run(host='0.0.0.0', port=port)
   ```

4. **Criar requirements.txt**
   ```
   Flask==2.3.3
   flask-cors==4.0.0
   scikit-learn==1.3.0
   numpy==1.24.3
   pandas==2.0.3
   gunicorn==21.2.0
   ```

5. **Criar Procfile**
   ```
   web: gunicorn app:app
   ```

6. **Deploy no Heroku**
   ```bash
   # Login
   heroku login
   
   # Criar app
   heroku create api-motor-prediction
   
   # Deploy
   git init
   git add .
   git commit -m "Initial commit"
   git push heroku main
   
   # Ver logs
   heroku logs --tail
   ```

7. **Obter URL**
   - A URL será: `https://api-motor-prediction.herokuapp.com/predict`
   - Atualize no Node-RED

---

### Opção 3: Railway (Alternativa Moderna)

**Vantagens**: Gratuito (tier básico), fácil, moderno, sem cold start
**Desvantagens**: Requer conta GitHub

#### Passos:

1. **Criar conta no Railway**
   - Acesse https://railway.app
   - Faça login com GitHub

2. **Criar projeto**
   - Clique em "New Project"
   - Selecione "Deploy from GitHub repo"
   - Conecte seu repositório

3. **Estrutura do projeto** (mesma do Heroku)

4. **Configurar variáveis de ambiente** (se necessário)
   - No dashboard do Railway, vá em Variables

5. **Deploy automático**
   - Railway detecta automaticamente e faz deploy
   - URL será gerada automaticamente

---

### Opção 4: Render (Simples e Gratuito)

**Vantagens**: Muito simples, gratuito, bom para começar
**Desvantagens**: Cold start pode ser lento

#### Passos:

1. **Criar conta no Render**
   - Acesse https://render.com
   - Faça login com GitHub

2. **Criar novo Web Service**
   - Clique em "New +" > "Web Service"
   - Conecte seu repositório GitHub

3. **Configurar**
   - Build Command: `pip install -r requirements.txt`
   - Start Command: `gunicorn app:app`
   - Environment: Python 3

4. **Deploy**
   - Render faz deploy automático
   - URL será: `https://seu-app.onrender.com/predict`

---

### Opção 5: AWS Lambda + API Gateway

**Vantagens**: Escalável, pay-per-use, profissional
**Desvantagens**: Mais complexo, requer conta AWS

#### Passos:

1. **Instalar Serverless Framework**
   ```bash
   npm install -g serverless
   ```

2. **Criar estrutura**
   ```
   lambda-api/
   ├── handler.py
   ├── requirements.txt
   └── serverless.yml
   ```

3. **Criar handler.py**
   ```python
   import json
   import pickle
   import numpy as np
   
   def lambda_handler(event, context):
       try:
           body = json.loads(event['body'])
           
           motor_temp = float(body['motor_temp'])
           vibration_rms = float(body['vibration_rms'])
           current = float(body['current'])
           
           # Lógica de predição
           if motor_temp > 100 or vibration_rms > 5 or current > 35:
               prediction = 1
               probability = 0.85
           else:
               prediction = 0
               probability = 0.15
           
           return {
               'statusCode': 200,
               'headers': {
                   'Content-Type': 'application/json',
                   'Access-Control-Allow-Origin': '*'
               },
               'body': json.dumps({
                   'prediction': prediction,
                   'probability': probability,
                   'status': 'anomalia' if prediction == 1 else 'normal'
               })
           }
       except Exception as e:
           return {
               'statusCode': 400,
               'body': json.dumps({'error': str(e)})
           }
   ```

4. **Criar serverless.yml**
   ```yaml
   service: motor-prediction-api
   
   provider:
     name: aws
     runtime: python3.9
     region: us-east-1
   
   functions:
     predict:
       handler: handler.lambda_handler
       events:
         - http:
             path: predict
             method: post
             cors: true
   ```

5. **Deploy**
   ```bash
   serverless deploy
   ```

---

## Recomendação por Caso de Uso

- **Desenvolvimento/Teste**: Google Colab + ngrok
- **Projeto Pequeno/Médio**: Render ou Railway
- **Projeto Médio/Grande**: Heroku
- **Projeto Empresarial**: AWS Lambda ou Google Cloud Functions

## Atualizando Node-RED

Após criar a API, atualize a URL no Node-RED:

1. Abra o fluxo `fluxo_NODERED_02.json`
2. No nó "HTTP – Chama API Colab"
3. Altere a URL para sua nova API:
   - Heroku: `https://seu-app.herokuapp.com/predict`
   - Railway: `https://seu-app.railway.app/predict`
   - Render: `https://seu-app.onrender.com/predict`

## Testando a API

Use curl ou Postman para testar:

```bash
curl -X POST https://sua-api.com/predict \
  -H "Content-Type: application/json" \
  -d '{
    "motor_temp": 65.0,
    "vibration_rms": 2.5,
    "current": 24.0
  }'
```

## Próximos Passos

1. Treinar modelo de ML com o dataset `motor_min_sintetico.csv`
2. Salvar modelo treinado (pickle ou joblib)
3. Integrar modelo na API
4. Adicionar logging e monitoramento
5. Implementar autenticação (se necessário)

