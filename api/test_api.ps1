# Script de teste para a API (PowerShell)
# Uso: .\test_api.ps1 [URL]
# Exemplo: .\test_api.ps1 http://localhost:5000

param(
    [string]$ApiUrl = "http://localhost:5000"
)

Write-Host "Testando API em: $ApiUrl" -ForegroundColor Cyan
Write-Host ""

# Teste 1: Health Check
Write-Host "=== Teste 1: Health Check ===" -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "$ApiUrl/health" -Method Get
    Write-Host ($response | ConvertTo-Json)
    Write-Host "Status: 200" -ForegroundColor Green
} catch {
    Write-Host "Erro: $_" -ForegroundColor Red
}
Write-Host ""

# Teste 2: Root endpoint
Write-Host "=== Teste 2: Root Endpoint ===" -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "$ApiUrl/" -Method Get
    Write-Host ($response | ConvertTo-Json)
    Write-Host "Status: 200" -ForegroundColor Green
} catch {
    Write-Host "Erro: $_" -ForegroundColor Red
}
Write-Host ""

# Teste 3: Predição Normal
Write-Host "=== Teste 3: Predição Normal ===" -ForegroundColor Yellow
try {
    $body = @{
        motor_temp = 65.0
        vibration_rms = 2.5
        current = 24.0
    } | ConvertTo-Json
    
    $response = Invoke-RestMethod -Uri "$ApiUrl/predict" -Method Post -Body $body -ContentType "application/json"
    Write-Host ($response | ConvertTo-Json)
    Write-Host "Status: 200" -ForegroundColor Green
} catch {
    Write-Host "Erro: $_" -ForegroundColor Red
}
Write-Host ""

# Teste 4: Predição Anomalia (temperatura alta)
Write-Host "=== Teste 4: Predição Anomalia (Temp Alta) ===" -ForegroundColor Yellow
try {
    $body = @{
        motor_temp = 110.0
        vibration_rms = 2.5
        current = 24.0
    } | ConvertTo-Json
    
    $response = Invoke-RestMethod -Uri "$ApiUrl/predict" -Method Post -Body $body -ContentType "application/json"
    Write-Host ($response | ConvertTo-Json)
    Write-Host "Status: 200" -ForegroundColor Green
} catch {
    Write-Host "Erro: $_" -ForegroundColor Red
}
Write-Host ""

# Teste 5: Predição Anomalia (vibração alta)
Write-Host "=== Teste 5: Predição Anomalia (Vibração Alta) ===" -ForegroundColor Yellow
try {
    $body = @{
        motor_temp = 65.0
        vibration_rms = 6.0
        current = 24.0
    } | ConvertTo-Json
    
    $response = Invoke-RestMethod -Uri "$ApiUrl/predict" -Method Post -Body $body -ContentType "application/json"
    Write-Host ($response | ConvertTo-Json)
    Write-Host "Status: 200" -ForegroundColor Green
} catch {
    Write-Host "Erro: $_" -ForegroundColor Red
}
Write-Host ""

# Teste 6: Predição Anomalia (corrente alta)
Write-Host "=== Teste 6: Predição Anomalia (Corrente Alta) ===" -ForegroundColor Yellow
try {
    $body = @{
        motor_temp = 65.0
        vibration_rms = 2.5
        current = 40.0
    } | ConvertTo-Json
    
    $response = Invoke-RestMethod -Uri "$ApiUrl/predict" -Method Post -Body $body -ContentType "application/json"
    Write-Host ($response | ConvertTo-Json)
    Write-Host "Status: 200" -ForegroundColor Green
} catch {
    Write-Host "Erro: $_" -ForegroundColor Red
}
Write-Host ""

# Teste 7: Erro - campo faltando
Write-Host "=== Teste 7: Erro - Campo Faltando ===" -ForegroundColor Yellow
try {
    $body = @{
        motor_temp = 65.0
        vibration_rms = 2.5
    } | ConvertTo-Json
    
    $response = Invoke-RestMethod -Uri "$ApiUrl/predict" -Method Post -Body $body -ContentType "application/json"
    Write-Host ($response | ConvertTo-Json)
} catch {
    Write-Host "Erro esperado: $_" -ForegroundColor Yellow
}
Write-Host ""

Write-Host "=== Testes Concluídos ===" -ForegroundColor Cyan

