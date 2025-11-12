#!/bin/bash

# Script de teste para a API
# Uso: ./test_api.sh [URL]
# Exemplo: ./test_api.sh http://localhost:5000

API_URL=${1:-http://localhost:5000}

echo "Testando API em: $API_URL"
echo ""

# Teste 1: Health Check
echo "=== Teste 1: Health Check ==="
curl -X GET "$API_URL/health" -w "\nStatus: %{http_code}\n"
echo ""

# Teste 2: Root endpoint
echo "=== Teste 2: Root Endpoint ==="
curl -X GET "$API_URL/" -w "\nStatus: %{http_code}\n"
echo ""

# Teste 3: Predição Normal
echo "=== Teste 3: Predição Normal ==="
curl -X POST "$API_URL/predict" \
  -H "Content-Type: application/json" \
  -d '{
    "motor_temp": 65.0,
    "vibration_rms": 2.5,
    "current": 24.0
  }' \
  -w "\nStatus: %{http_code}\n"
echo ""

# Teste 4: Predição Anomalia (temperatura alta)
echo "=== Teste 4: Predição Anomalia (Temp Alta) ==="
curl -X POST "$API_URL/predict" \
  -H "Content-Type: application/json" \
  -d '{
    "motor_temp": 110.0,
    "vibration_rms": 2.5,
    "current": 24.0
  }' \
  -w "\nStatus: %{http_code}\n"
echo ""

# Teste 5: Predição Anomalia (vibração alta)
echo "=== Teste 5: Predição Anomalia (Vibração Alta) ==="
curl -X POST "$API_URL/predict" \
  -H "Content-Type: application/json" \
  -d '{
    "motor_temp": 65.0,
    "vibration_rms": 6.0,
    "current": 24.0
  }' \
  -w "\nStatus: %{http_code}\n"
echo ""

# Teste 6: Predição Anomalia (corrente alta)
echo "=== Teste 6: Predição Anomalia (Corrente Alta) ==="
curl -X POST "$API_URL/predict" \
  -H "Content-Type: application/json" \
  -d '{
    "motor_temp": 65.0,
    "vibration_rms": 2.5,
    "current": 40.0
  }' \
  -w "\nStatus: %{http_code}\n"
echo ""

# Teste 7: Erro - campo faltando
echo "=== Teste 7: Erro - Campo Faltando ==="
curl -X POST "$API_URL/predict" \
  -H "Content-Type: application/json" \
  -d '{
    "motor_temp": 65.0,
    "vibration_rms": 2.5
  }' \
  -w "\nStatus: %{http_code}\n"
echo ""

# Teste 8: Erro - valor inválido
echo "=== Teste 8: Erro - Valor Inválido ==="
curl -X POST "$API_URL/predict" \
  -H "Content-Type: application/json" \
  -d '{
    "motor_temp": "abc",
    "vibration_rms": 2.5,
    "current": 24.0
  }' \
  -w "\nStatus: %{http_code}\n"
echo ""

echo "=== Testes Concluídos ==="

