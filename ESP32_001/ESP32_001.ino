/********************************************************************
 * Projeto: Envio de Dados MQTT com ESP32 - Aula Teste Inteli 12/11/2025
 * Autor: André Tritiack
 * Placa: DOIT ESP32 DEVKIT V1
 * 
 * Descrição:
 * Conecta o ESP32 a uma rede Wi-Fi e ao Broker MQTT.
 * A cada 10 segundos, envia um JSON contendo:
 *  - motor_temp (°C)
 *  - vibration_rms (mm/s)
 *  - current (A)
 * 
 * Extra: gera uma anomalia a cada 5 envios (e também ao digitar 'A' no Serial).
 ********************************************************************/

#include <WiFi.h>
#include <PubSubClient.h>
#include <ArduinoJson.h>

#define boardLED 2

// Wi-Fi
const char* SSID     = "iPhone de André";
const char* PASSWORD = "bellabella1302";

// Broker MQTT (HiveMQ público)
const char* BROKER_MQTT = "broker.hivemq.com";
const int   BROKER_PORT = 1883;

// Tópico MQTT
#define TOPICO_PUBLISH "INTELI/ESP32/SENSOR"

// Variáveis globais
WiFiClient espClient;
PubSubClient MQTT(espClient);
DynamicJsonDocument doc(128);
char buffer[128];

float motorTemp    = 65.0;
float vibrationRms = 2.5;
float currentAmp   = 24.0;

int   envioCount   = 0;    // contador de envios para forçar anomalia periódica
bool  triggerSerial = false; // se digitar 'A' no Serial, força 1 envio anômalo

void dadosSimulados(bool forcarAlarme); // protótipo

void initWiFi() {
  WiFi.begin(SSID, PASSWORD);
  Serial.print("Conectando ao Wi-Fi");
  while (WiFi.status() != WL_CONNECTED) {
    delay(1000);
    Serial.print(".");
  }
  Serial.println("\nConectado");
  Serial.print("SSID: ");
  Serial.println(SSID);
  Serial.print("IP Local: ");
  Serial.println(WiFi.localIP());
  Serial.print("MAC Address: ");
  Serial.println(WiFi.macAddress());
  Serial.print("Sinal (RSSI): ");
  Serial.print(WiFi.RSSI());
  Serial.println(" dBm");
  Serial.println("");
}

void reconectaWiFi() {
  if (WiFi.status() != WL_CONNECTED) {
    initWiFi();
  }
}

// Conexão MQTT
void initMQTT() {
  MQTT.setServer(BROKER_MQTT, BROKER_PORT);
  while (!MQTT.connected()) {
    Serial.println("Conectando ao Broker MQTT...");
    if (MQTT.connect("ESP32_Aula")) {
      Serial.println("Conectado ao Broker!");
    } else {
      Serial.print("Falha. Estado: ");
      Serial.println(MQTT.state());
      delay(2000);
    }
  }
}

void verificaConexoesWiFiEMQTT() {
  reconectaWiFi();
  if (!MQTT.connected()) {
    initMQTT();
  }
  MQTT.loop();
}

// Função para enviar o MQTT
void enviaMQTT() {
  MQTT.publish(TOPICO_PUBLISH, buffer);
  Serial.println("Mensagem publicada!");
}

void piscaLed() {
  digitalWrite(boardLED, HIGH);
  delay(200);
  digitalWrite(boardLED, LOW);
}

// Funções de simulação
float ruido(float amplitude) {
  return (random(-100, 101) / 100.0f) * amplitude;
}

float limitarValor(float valor, float minimo, float maximo) {
  if (valor < minimo) return minimo;
  if (valor > maximo) return maximo;
  return valor;
}

void setup() {
  Serial.begin(115200);
  pinMode(boardLED, OUTPUT);
  randomSeed(analogRead(0));
  initWiFi();
  initMQTT();
}

void loop() {
  verificaConexoesWiFiEMQTT();

  // teclado do Monitor Serial: digite 'A' para forçar anomalia no próximo envio
  if (Serial.available()) {
    char c = Serial.read();
    if (c == 'A' || c == 'a') triggerSerial = true;
  }

  envioCount++;
  bool forcarAlarme = (envioCount % 5 == 0) || triggerSerial; // a cada 5 envios OU comando serial
  dadosSimulados(forcarAlarme);
  triggerSerial = false; // zera após usar

  doc.clear();
  doc["motor_temp"]    = motorTemp;
  doc["vibration_rms"] = vibrationRms;
  doc["current"]       = currentAmp;

  serializeJson(doc, buffer, sizeof(buffer));
  Serial.println(buffer);

  enviaMQTT();
  piscaLed();

  delay(10000);
}

void dadosSimulados(bool forcarAlarme){
  if (forcarAlarme) {
    // valores anômalos para demonstrar ALERTA
    motorTemp    = 110.0; // °C
    vibrationRms = 5.5;   // mm/s
    currentAmp   = 40.0;  // A
    return;
  }

  // simulação normal com pequenas variações e correlações
  currentAmp   = currentAmp + ruido(0.8);
  motorTemp    = motorTemp + ruido(0.6) + 0.02f * (currentAmp - 24.0);
  vibrationRms = vibrationRms + ruido(0.15) + (motorTemp > 80.0 ? 0.05f : 0.0f);

  motorTemp    = limitarValor(motorTemp,    40.0, 120.0);
  vibrationRms = limitarValor(vibrationRms, 0.2,  10.0);
  currentAmp   = limitarValor(currentAmp,   0.0,  60.0);
}
