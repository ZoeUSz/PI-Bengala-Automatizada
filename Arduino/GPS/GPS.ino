#include <TinyGPS++.h>
#include <HardwareSerial.h>

const int RXPin = 16;  // Define o pino RX do ESP32
const int TXPin = 17;  // Define o pino TX do ESP32

TinyGPSPlus gps;  // Objeto TinyGPS++ para processar os dados do GPS
HardwareSerial gpsSerial(1);  // Criação de uma instância do objeto HardwareSerial para se comunicar com o módulo GPS

unsigned long previousMillis = 0;
const long interval = 30000;  // Intervalo de 30 segundos em milissegundos

void setup() {
  Serial.begin(115200);  // Inicializa a comunicação serial com o monitor serial a 115200 bps
  gpsSerial.begin(9600, SERIAL_8N1, RXPin, TXPin);  // Inicializa a comunicação serial com o módulo GPS
  
  delay(1000);
  
  // Mensagem de depuração para verificar o início do reset
  Serial.println("Iniciando reset do módulo GPS...");

  // Reseta o módulo GPS
  resetGPSModule();
}

void loop() {
  unsigned long currentMillis = millis();

  // Verifica se já passou o intervalo de 30 segundos
  if (currentMillis - previousMillis >= interval) {
    previousMillis = currentMillis;  // Atualiza o valor de previousMillis

    if (gps.charsProcessed() < 10) {
      Serial.println(F("Não há dados de GPS disponíveis!"));
    } else {
      if (gps.location.isValid()) {
        double latitude = gps.location.lat();
        double longitude = gps.location.lng();

        Serial.print(F("Latitude: "));
        Serial.println(latitude, 6);
        Serial.print(F("Longitude: "));
        Serial.println(longitude, 6);

        // Formata a URL do Google Maps
        String googleMapsUrl = "https://www.google.com/maps/search/?api=1&query=";
        googleMapsUrl += String(latitude, 6);
        googleMapsUrl += ",";
        googleMapsUrl += String(longitude, 6);

        // Imprime a URL no monitor serial
        Serial.print(F("Google Maps URL: "));
        Serial.println(googleMapsUrl);
      } else {
        Serial.println(F("Dados de localização inválidos!"));
      }
    }
  }

  // Verifica se há novos dados disponíveis do GPS
  while (gpsSerial.available() > 0) {
    if (gps.encode(gpsSerial.read())) {
      // Novos dados de GPS recebidos
    }
  }
}

void resetGPSModule() {
  // UBX-CFG-RST message to reset the GPS module
  uint8_t ubxCfgRst[] = { 
    0xB5, 0x62, // UBX Header
    0x06, 0x04, // CFG-RST
    0x04, 0x00, // Payload length: 4 bytes
    0x00, 0x00, // navBbrMask: Hotstart
    0x00, 0x00, // resetMode: Hardware reset
    0x10, 0x2E // Checksum (calculated manually or using a tool)
  };

  // Mensagem de depuração para verificar antes do envio
  Serial.println("Enviando comando de reset para o módulo GPS...");

  // Send the UBX-CFG-RST message to the GPS module
  gpsSerial.write(ubxCfgRst, sizeof(ubxCfgRst));
  Serial.println("Comando de reset do módulo GPS enviado.");
}
