#include <HardwareSerial.h>

#define RX_PIN 4
#define TX_PIN 2

HardwareSerial SIM800Serial(1); // Pino RX do SIM800L conectado ao pino D2 do ESP32 (RX1)
HardwareSerial SerialESP32(2); // Pino TX do SIM800L conectado ao pino D4 do ESP32 (TX2)

unsigned long previousMillis = 0;
const long interval = 20000; // Intervalo de 20 segundos em milissegundos

void setup() {
  Serial.begin(115200);
  SerialESP32.begin(9600, SERIAL_8N1, RX_PIN, TX_PIN);
  SIM800Serial.begin(9600, SERIAL_8N1, RX_PIN, TX_PIN, false);
  delay(1000);

  // Configura o SIM800L para enviar mensagens de texto
  SIM800Serial.println("AT+CMGF=1");
  delay(1000);
}

void loop() {
  unsigned long currentMillis = millis();

  // Verifica se passou o intervalo definido
  if (currentMillis - previousMillis >= interval) {
    // Salva o tempo atual como o último tempo de envio
    previousMillis = currentMillis;

    // Envia um SMS para +5512997585099
    sendSMS("+5512997585099", "Teste de mensagem SMS!");
  }
}

void sendSMS(String number, String message) {
  SIM800Serial.print("AT+CMGS=\"");
  SIM800Serial.print(number);
  SIM800Serial.println("\"");
  delay(1000);
  SIM800Serial.println(message);
  delay(1000);
  SIM800Serial.write(0x1A);
  delay(1000);

  // Verifica a resposta do módulo SIM800L para confirmar o envio
  if (SIM800Serial.find("OK")) {
    Serial.println("SMS enviado com sucesso.");
  } else {
    Serial.println("Erro: Falha ao enviar o SMS.");
  }
}
