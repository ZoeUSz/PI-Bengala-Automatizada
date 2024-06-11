#include <HardwareSerial.h>
#include <TinyGPS++.h>

#define rxPin 4
#define txPin 2
#define RXD2 16
#define TXD2 17
#define buttonPin 23

HardwareSerial sim800(1); // GSM Module
HardwareSerial neogps(2); // GPS Module

TinyGPSPlus gps;

unsigned long lastPrintTime = 0; // Variável para armazenar o tempo do último print dos dados de GPS
const unsigned long interval = 30000; // Intervalo de 30 segundos em milissegundos
int lastButtonState = HIGH;  // Estado anterior do botão, inicializado como HIGH (liberado)

void setup() {
  Serial.begin(115200);
  sim800.begin(9600, SERIAL_8N1, rxPin, txPin);
  neogps.begin(9600, SERIAL_8N1, RXD2, TXD2);
  pinMode(buttonPin, INPUT_PULLUP);  // Configura o pino do botão como entrada com pull-up interno

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

  if (millis() - lastPrintTime >= interval) {
    if (gps.location.isValid()) {
      float latitude = gps.location.lat();
      float longitude = gps.location.lng();

      // Print latitude, longitude, altitude, and satellites to serial monitor
      Serial.print("Latitude: ");
      Serial.println(latitude, 6);
      Serial.print("Longitude: ");
      Serial.println(longitude, 6);
      Serial.print("Altitude: ");
      Serial.print(gps.altitude.meters());
      Serial.println(" meters");
      Serial.print("Satellites: ");
      Serial.println(gps.satellites.value());
    } else {
      Serial.println("Erro: Dados de GPS não detectados.");
    }
    lastPrintTime = millis();
  }

  // Verifica o estado do botão
  int currentButtonState = digitalRead(buttonPin);  // Lê o estado atual do botão

  if (currentButtonState == LOW && lastButtonState == HIGH) {  // Se o botão foi pressionado
    Serial.println("Botão pressionado");

    if (gps.location.isValid()) {
      float latitude = gps.location.lat();
      float longitude = gps.location.lng();

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
    } else {
      Serial.println("Erro: Dados de GPS não detectados.");
    }
  }

  lastButtonState = currentButtonState;  // Atualiza o estado anterior do botão

  delay(50);  // Pequeno atraso para debounce
}
