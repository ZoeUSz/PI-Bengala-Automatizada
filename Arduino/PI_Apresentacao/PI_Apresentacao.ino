#include <HardwareSerial.h>

#define trigPin  18
#define echoPin 19
#define buzzerPin 21
#define RX_PIN 4
#define TX_PIN 2
#define buttonPin 23

HardwareSerial SIM800Serial(1); // Pino RX do SIM800L conectado ao pino D2 do ESP32 (RX1)
HardwareSerial SerialESP32(2); // Pino TX do SIM800L conectado ao pino D4 do ESP32 (TX2)

unsigned long previousMillis = 0;
const long interval = 60000; // Intervalo de 1 minuto em milissegundos
bool panicButtonPressed = false;

void setup() {
  Serial.begin(115200);
  SerialESP32.begin(9600, SERIAL_8N1, RX_PIN, TX_PIN);
  SIM800Serial.begin(9600, SERIAL_8N1, RX_PIN, TX_PIN, false);
  pinMode(buttonPin, INPUT_PULLUP); // Configura o pino do botão de pânico como entrada com pull-up
  pinMode(trigPin, OUTPUT);
  pinMode(echoPin, INPUT);
  pinMode(buzzerPin, OUTPUT);

  // Configura o SIM800L para enviar mensagens de texto
  SIM800Serial.println("AT+CMGF=1");
  delay(1000);
}

void loop() {
  // Lógica do sensor ultrassônico e buzzer
  long duration, distance;

  // Gera um pulso de trigger de 10 microsegundos
  digitalWrite(trigPin, LOW);
  delayMicroseconds(2);
  digitalWrite(trigPin, HIGH);
  delayMicroseconds(10);
  digitalWrite(trigPin, LOW);
  
  // Leitura do echo e cálculo da distância
  duration = pulseIn(echoPin, HIGH, 30000); // Timeout de 30ms
  if (duration == 0) {
    Serial.println("Nenhum eco recebido");
    distance = -1;
  } else {
    distance = duration * 0.034 / 2;
  }

  Serial.print("Distância: ");
  Serial.print(distance);
  Serial.println(" cm");
  
  if (distance >= 0 && distance <= 50) {
    int delayTime = map(distance, 0, 50, 50, 1000); // Mapeia a distância para o tempo de delay

    // Liga o buzzer por um curto período
    digitalWrite(buzzerPin, HIGH);
    delay(50); // Buzzer ligado por 50ms
    digitalWrite(buzzerPin, LOW);

    // Espera pelo tempo calculado
    delay(delayTime - 50);
  } else {
    // Desliga o buzzer
    digitalWrite(buzzerPin, LOW);
  }

  // Lógica do botão de pânico
  if (digitalRead(buttonPin) == LOW) { // Verifica se o botão foi pressionado
    if (!panicButtonPressed) { // Verifica se o botão estava previamente solto
      panicButtonPressed = true;
      sendSMS("+5512997585099", "SOS! Preciso de ajuda nesta localizacao:\nhttp://maps.google.com/maps?q=-22.733271,-45.122494");
    }
  } else {
    panicButtonPressed = false; // Reseta o estado do botão de pânico quando ele é solto
  }

  delay(100); // Aguarda 100ms antes de realizar a próxima medição
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

  // Limpa o buffer serial para evitar que os comandos AT sejam impressos
  while (SIM800Serial.available()) {
    SIM800Serial.read();
  }
}
