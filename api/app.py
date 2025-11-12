"""
API de Predição de Anomalias em Motores
Endpoint: /predict
Método: POST
"""

from flask import Flask, request, jsonify
from flask_cors import CORS
import numpy as np
import os

app = Flask(__name__)
CORS(app)  # Permite requisições de qualquer origem

# Modelo simples baseado em regras (substitua por modelo ML treinado)
def predict_anomaly(motor_temp, vibration_rms, current):
    """
    Prediz anomalia baseado em regras simples.
    Substitua esta função por seu modelo de ML treinado.
    
    Args:
        motor_temp: Temperatura do motor em °C
        vibration_rms: Vibração RMS em mm/s
        current: Corrente elétrica em A
    
    Returns:
        tuple: (prediction, probability)
    """
    # Regras simples para detecção de anomalia
    # Ajuste os thresholds conforme necessário
    
    temp_threshold = 100.0  # °C
    vibration_threshold = 5.0  # mm/s
    current_threshold = 35.0  # A
    
    # Calcular score de anomalia
    score = 0.0
    
    if motor_temp > temp_threshold:
        score += 0.4
    elif motor_temp > 85:
        score += 0.2
    
    if vibration_rms > vibration_threshold:
        score += 0.4
    elif vibration_rms > 4.0:
        score += 0.2
    
    if current > current_threshold:
        score += 0.4
    elif current > 30:
        score += 0.2
    
    # Normalizar score para probabilidade
    probability = min(score, 1.0)
    prediction = 1 if probability > 0.5 else 0
    
    return prediction, probability

@app.route('/predict', methods=['POST'])
def predict():
    """
    Endpoint principal para predição de anomalias.
    
    Request body:
    {
        "motor_temp": float,
        "vibration_rms": float,
        "current": float
    }
    
    Response:
    {
        "prediction": int (0 ou 1),
        "probability": float (0.0 a 1.0),
        "status": str ("normal" ou "anomalia")
    }
    """
    try:
        # Validar entrada
        if not request.is_json:
            return jsonify({'error': 'Content-Type deve ser application/json'}), 400
        
        data = request.get_json()
        
        # Validar campos obrigatórios
        required_fields = ['motor_temp', 'vibration_rms', 'current']
        for field in required_fields:
            if field not in data:
                return jsonify({'error': f'Campo obrigatório ausente: {field}'}), 400
        
        # Converter para float
        try:
            motor_temp = float(data['motor_temp'])
            vibration_rms = float(data['vibration_rms'])
            current = float(data['current'])
        except (ValueError, TypeError):
            return jsonify({'error': 'Valores devem ser numéricos'}), 400
        
        # Validar ranges razoáveis
        if not (0 <= motor_temp <= 200):
            return jsonify({'error': 'motor_temp deve estar entre 0 e 200'}), 400
        if not (0 <= vibration_rms <= 20):
            return jsonify({'error': 'vibration_rms deve estar entre 0 e 20'}), 400
        if not (0 <= current <= 100):
            return jsonify({'error': 'current deve estar entre 0 e 100'}), 400
        
        # Fazer predição
        prediction, probability = predict_anomaly(motor_temp, vibration_rms, current)
        
        status = "anomalia" if prediction == 1 else "normal"
        
        return jsonify({
            'prediction': int(prediction),
            'probability': round(float(probability), 3),
            'status': status,
            'input': {
                'motor_temp': motor_temp,
                'vibration_rms': vibration_rms,
                'current': current
            }
        }), 200
        
    except Exception as e:
        return jsonify({
            'error': 'Erro interno do servidor',
            'message': str(e)
        }), 500

@app.route('/health', methods=['GET'])
def health():
    """Endpoint de health check"""
    return jsonify({
        'status': 'ok',
        'service': 'motor-prediction-api'
    }), 200

@app.route('/', methods=['GET'])
def root():
    """Endpoint raiz com informações da API"""
    return jsonify({
        'service': 'Motor Prediction API',
        'version': '1.0.0',
        'endpoints': {
            'predict': 'POST /predict',
            'health': 'GET /health'
        },
        'example_request': {
            'motor_temp': 65.0,
            'vibration_rms': 2.5,
            'current': 24.0
        }
    }), 200

if __name__ == '__main__':
    # Porta padrão ou variável de ambiente
    port = int(os.environ.get('PORT', 5000))
    
    # Para desenvolvimento local
    app.run(host='0.0.0.0', port=port, debug=True)
    
    # Para produção, use gunicorn:
    # gunicorn app:app --bind 0.0.0.0:5000

