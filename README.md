# Inteli Class - Monitoramento de Motores com ESP32

Projeto de monitoramento de motores elétricos utilizando ESP32, MQTT e Node-RED para coleta, transmissão e análise de dados de sensores em tempo real.

## Descrição

Este projeto implementa um sistema de monitoramento de motores que coleta dados de sensores (temperatura, vibração e corrente) através de um ESP32, transmite os dados via protocolo MQTT e processa as informações através de um fluxo Node-RED que integra com uma API de predição.

## Componentes do Sistema

### 1. ESP32 (Firmware)
- **Placa**: DOIT ESP32 DEVKIT V1
- **Funcionalidade**: Simula dados de sensores e publica via MQTT
- **Dados coletados**:
  - Temperatura do motor (motor_temp) em °C
  - Vibração RMS (vibration_rms) em mm/s
  - Corrente elétrica (current) em A

### 2. Node-RED (Fluxo de Processamento)
- **Broker MQTT**: HiveMQ (broker.hivemq.com)
- **Tópico**: `INTELI/ESP32/SENSOR`
- **Funcionalidade**: Recebe dados MQTT, formata e envia para API de predição

### 3. Dados Sintéticos
- Arquivo CSV com dados simulados de múltiplos motores para análise e treinamento de modelos

## Estrutura do Projeto

```
inteli-class/
├── ESP32_001/
│   └── ESP32_001.ino          # Código do firmware ESP32
├── fluxo_NODERED_02.json      # Fluxo Node-RED para processamento
├── motor_min_sintetico.csv    # Dataset sintético de motores
└── README.md                   # Este arquivo
```

## Requisitos

### Hardware
- ESP32 (DOIT ESP32 DEVKIT V1)
- Conexão Wi-Fi disponível

### Software
- Arduino IDE com suporte para ESP32
- Node-RED instalado e configurado
- Bibliotecas Arduino necessárias:
  - WiFi (incluída no core ESP32)
  - PubSubClient
  - ArduinoJson

## Configuração

### ESP32

1. Instale as bibliotecas necessárias no Arduino IDE:
   - PubSubClient
   - ArduinoJson

2. Configure as credenciais Wi-Fi no arquivo `ESP32_001.ino`:
   ```cpp
   const char* SSID     = "SEU_SSID";
   const char* PASSWORD = "SUA_SENHA";
   ```

3. O broker MQTT já está configurado para usar o HiveMQ público:
   - Broker: `broker.hivemq.com`
   - Porta: `1883`
   - Tópico: `INTELI/ESP32/SENSOR`

4. Faça o upload do código para o ESP32

### Node-RED

1. Importe o fluxo do arquivo `fluxo_NODERED_02.json` no Node-RED
2. Configure o broker MQTT no Node-RED apontando para `broker.hivemq.com:1883`
3. Ajuste a URL da API de predição no nó HTTP Request conforme necessário

## Funcionamento

### Coleta de Dados
- O ESP32 gera dados simulados a cada 10 segundos
- Os valores normais variam dentro de faixas predefinidas:
  - Temperatura: 40-120°C
  - Vibração: 0.2-10 mm/s
  - Corrente: 0-60 A

### Detecção de Anomalias
- A cada 5 envios, o sistema força uma anomalia simulada
- Anomalias também podem ser forçadas digitando 'A' no Monitor Serial
- Valores anômalos típicos:
  - Temperatura: 110°C
  - Vibração: 5.5 mm/s
  - Corrente: 40 A

### Transmissão MQTT
- Os dados são serializados em JSON e publicados no tópico MQTT
- Formato da mensagem:
  ```json
  {
    "motor_temp": 65.0,
    "vibration_rms": 2.5,
    "current": 24.0
  }
  ```

### Processamento Node-RED
1. Recebe mensagens do tópico MQTT
2. Converte JSON string para objeto
3. Formata dados para envio à API
4. Envia requisição HTTP POST para API de predição
5. Exibe resposta da API no debug

## Monitoramento

- O LED onboard (GPIO 2) pisca a cada envio de dados
- O Monitor Serial (115200 baud) exibe:
  - Status de conexão Wi-Fi e MQTT
  - Mensagens JSON enviadas
  - Confirmação de publicação MQTT

## Dataset

O arquivo `motor_min_sintetico.csv` contém dados sintéticos de múltiplos motores com as seguintes colunas:
- `timestamp`: Data e hora da leitura
- `device_id`: Identificador do motor
- `motor_temp`: Temperatura em °C
- `vibration_rms`: Vibração RMS em mm/s
- `current`: Corrente em A
- `alerta`: Flag binária indicando anomalia (0 ou 1)

## Fontes de Pesquisa

### Documentação e Tutoriais
- **ESP32 Documentation**: [Espressif ESP32 Official Docs](https://docs.espressif.com/projects/esp-idf/en/latest/esp32/)
- **ArduinoJson Library**: [ArduinoJson Documentation](https://arduinojson.org/)
- **PubSubClient Library**: [PubSubClient GitHub](https://github.com/knolleary/pubsubclient)
- **Node-RED Documentation**: [Node-RED Official Docs](https://nodered.org/docs/)
- **MQTT Protocol**: [MQTT.org Documentation](https://mqtt.org/)
- **HiveMQ Public Broker**: [HiveMQ Public MQTT Broker](https://www.hivemq.com/public-mqtt-broker/)

### Bibliotecas e Frameworks
- **Flask**: [Flask Documentation](https://flask.palletsprojects.com/)
- **FastAPI**: [FastAPI Documentation](https://fastapi.tiangolo.com/)
- **Docker**: [Docker Documentation](https://docs.docker.com/)
- **Azure Cloud Services**: [Azure Documentation](https://docs.microsoft.com/azure/)

### Uso de Inteligência Artificial
Este projeto utilizou assistentes de IA para auxiliar no desenvolvimento:
- **Código de geração**: Assistência na criação e otimização de código para ESP32, Node-RED e APIs
- **Documentação**: Apoio na estruturação e escrita de documentação técnica
- **Resolução de problemas**: Consulta para debugging e solução de problemas técnicos
- **Boas práticas**: Orientação sobre padrões de código e arquitetura de sistemas IoT

**Nota**: O uso de IA foi complementar ao desenvolvimento, servindo como ferramenta de apoio para acelerar o processo de desenvolvimento e garantir boas práticas de programação.

### Referências Adicionais
- **IoT Architecture Patterns**: Padrões de arquitetura para sistemas IoT
- **MQTT Best Practices**: Melhores práticas para implementação de protocolo MQTT
- **ESP32 WiFi Examples**: Exemplos oficiais de conexão Wi-Fi com ESP32
- **RESTful API Design**: Princípios de design de APIs REST

## Autor

André Tritiack

## Data

Projeto desenvolvido em 12/11/2025

## Licença

Este projeto é destinado a fins educacionais.

