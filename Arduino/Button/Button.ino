#define buttonPin 23  // Pino digital do ESP32 conectado ao botão

int lastButtonState = HIGH;  // Estado anterior do botão, inicializado como HIGH (liberado)

void setup() {
  Serial.begin(115200);  // Inicializa a comunicação serial a 115200 bps
  pinMode(buttonPin, INPUT_PULLUP);  // Configura o pino do botão como entrada com pull-up interno
}

void loop() {
  int currentButtonState = digitalRead(buttonPin);  // Lê o estado atual do botão

  if (currentButtonState != lastButtonState) {  // Se o estado do botão mudou
    if (currentButtonState == LOW) {  // Se o botão foi pressionado
      Serial.println("Botão pressionado");
    } else {  // Se o botão foi liberado
      Serial.println("Botão liberado");
    }
    lastButtonState = currentButtonState;  // Atualiza o estado anterior do botão
  }

  delay(50);  // Pequeno atraso para debounce
}
