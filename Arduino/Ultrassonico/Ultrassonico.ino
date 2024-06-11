#define trigPin  18
#define echoPin 19

void setup() {
  Serial.begin(115200);

  pinMode(trigPin, OUTPUT);
  pinMode(echoPin, INPUT);
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
  
  delay(1000); // Aguarda 1 segundo antes de realizar a próxima medição
}
