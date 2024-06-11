#define trigPin  18
#define echoPin 19
#define buzzerPin 21

void setup() {
  Serial.begin(115200);

  pinMode(trigPin, OUTPUT);
  pinMode(echoPin, INPUT);
  pinMode(buzzerPin, OUTPUT);
}

void loop() {
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
  
  if (distance >= 0 && distance < 40) {
    // Liga o buzzer
    digitalWrite(buzzerPin, HIGH);
    delay(500);
    digitalWrite(buzzerPin, LOW);
  } else if (distance >= 0 && distance < 30) {
    // Liga o buzzer
    digitalWrite(buzzerPin, HIGH);
    delay(300);
    digitalWrite(buzzerPin, LOW);
  } else if (distance >= 0 && distance < 20) {
    // Liga o buzzer
    digitalWrite(buzzerPin, HIGH);
    delay(100);
    digitalWrite(buzzerPin, LOW);
  } else if (distance >= 0 && distance < 10) {
    // Liga o buzzer
    digitalWrite(buzzerPin, HIGH);
    delay(55);
    digitalWrite(buzzerPin, LOW);
  } else {
    // Desliga o buzzer
    digitalWrite(buzzerPin, LOW);
  }

  delay(1000); // Aguarda 1 segundo antes de realizar a próxima medição
}
