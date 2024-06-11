#include <HardwareSerial.h>
#include <TinyGPS++.h>

#define rxPin 4
#define txPin 2
#define RXD2 16
#define TXD2 17

HardwareSerial sim800(1); // GSM Module
HardwareSerial neogps(2); // GPS Module

TinyGPSPlus gps;

unsigned long lastPrintTime = 0; // Variável para armazenar o tempo do último print dos dados de GPS
unsigned long lastSMSTime = 0; // Variável para armazenar o tempo do último envio de SMS
unsigned long lastErrorPrintTime = 0; // Variável para armazenar o tempo da última impressão da mensagem de erro
const unsigned long interval = 30000; // Intervalo de 30 segundos em milissegundos

void setup() {
  Serial.begin(115200);
  sim800.begin(9600, SERIAL_8N1, rxPin, txPin);
  neogps.begin(9600, SERIAL_8N1, RXD2, TXD2);

  delay(1000);

  // Initialize GSM
  sim800.println("AT");
  delay(1000);
  sim800.println("AT+CMGF=1"); // Set SMS mode to text
  delay(1000);
}

void loop() {
  while (neogps.available()) {
    gps.encode(neogps.read());
  }

  if (gps.location.isUpdated()) {
    float latitude = gps.location.lat();
    float longitude = gps.location.lng();

    // Print latitude, longitude, altitude, and satellites to serial monitor
    if (millis() - lastPrintTime >= interval) {
      Serial.print("Latitude: ");
      Serial.println(latitude, 6);
      Serial.print("Longitude: ");
      Serial.println(longitude, 6);
      Serial.print("Altitude: ");
      Serial.print(gps.altitude.meters());
      Serial.println(" meters");
      Serial.print("Satellites: ");
      Serial.println(gps.satellites.value());
      lastPrintTime = millis();
    }

    // Verifica se já passou tempo suficiente para enviar outro SMS
    if (millis() - lastSMSTime >= interval) {
      // Format Google Maps URL
      String url = "http://maps.google.com/maps?q=" + String(latitude, 6) + "," + String(longitude, 6);

      // Send SMS with Google Maps URL
      sim800.println("AT+CMGS=\"+5512997585099\""); // Replace with recipient's number
      delay(1000);
      sim800.print(url);
      delay(100);
      sim800.write(0x1A); // Envia Ctrl+Z para indicar fim do texto
      delay(5000); // Aguarda o envio do SMS

      if (sim800.find("OK")) {
        Serial.println("SMS enviado com a localização.");
      } else {
        Serial.println("Erro: Falha ao enviar o SMS.");
      }

      lastSMSTime = millis();
    }
  } else {
    // Verifica se já passou tempo suficiente para imprimir a mensagem de erro novamente
    if (millis() - lastErrorPrintTime >= interval) {
      Serial.println("Erro: Dados de GPS não detectados.");
      lastErrorPrintTime = millis();
    }
  }

  delay(1000); // Aguarda 1 segundo antes de verificar novamente
}
