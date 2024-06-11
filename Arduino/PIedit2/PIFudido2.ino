#include <WiFi.h>
#include <PubSubClient.h>
#include <HardwareSerial.h>
#include <TinyGPS++.h>
#include <IOXhop_FirebaseESP32.h>
#include <ArduinoJson.h>
#include <NTPClient.h>
#include <WiFiUdp.h>
#include <time.h>

const char* ssid = "...";
const char* password = "...";

// Adafruit IO
#define IO_USERNAME  "..."
#define IO_KEY       "..."
const char* mqtt_server = "...";

WiFiClient espClient;
PubSubClient client(espClient);

#define trigPin  18
#define echoPin 19
#define Buzzer 21
#define rxPin 4
#define txPin 2
#define RXD2 16
#define TXD2 17
#define PANIC_BUTTON_PIN 23 // GPIO14 corresponde ao pino D5

HardwareSerial sim800(1); // Módulo GSM
HardwareSerial neogps(2); // Módulo GPS
TinyGPSPlus gps;

#define FIREBASE_HOST "..." // Link do Firebase
#define FIREBASE_AUTH "..." // Autenticação do Firebase

WiFiUDP ntpUDP;
NTPClient timeClient(ntpUDP);

String dataFormatada;
String dia;
String hora;

void setup_wifi() {
  delay(10);
  WiFi.begin(ssid, password);
  Serial.print("Conectando ao WiFi");
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println("Conectado ao WiFi");
}

void callback(char* topic, byte* message, unsigned int length) {
  Serial.print("Mensagem recebida no tópico: ");
  Serial.print(topic);
  Serial.print(". Mensagem: ");
  String messageTemp;
  for (int i = 0; i < length; i++) {
    messageTemp += (char)message[i];
  }
  Serial.println(messageTemp);
}

void reconnect() {
  while (!client.connected()) {
    
    if (client.connect("ESP32Client", IO_USERNAME, IO_KEY)) {
      Serial.println("Conectado");
      //client.subscribe(IO_USERNAME "/feeds/device-state");
      //client.publish(IO_USERNAME "/feeds/device-state", "CONNECTED"); // Publica uma mensagem de conexão
    } else {
      Serial.print("Falha na conexão, rc=");
      Serial.print(client.state());
      Serial.println(" tentando novamente em 5 segundos");
      delay(5000);
    }
  }
}

void publishState() {
  String topic = String(IO_USERNAME) + "/feeds/device-state";
  String message = "LIGADO"; // ou "DESLIGADO", dependendo do estado do dispositivo.
  client.publish(topic.c_str(), message.c_str());
}

void setup() {
  Serial.begin(115200);
  setup_wifi();
  client.setServer(mqtt_server, 1883);
  client.setCallback(callback);
  
  pinMode(trigPin, OUTPUT);
  pinMode(echoPin, INPUT);
  pinMode(Buzzer, OUTPUT);
  pinMode(PANIC_BUTTON_PIN, INPUT_PULLUP);

  sim800.begin(9600, SERIAL_8N1, rxPin, txPin);
  neogps.begin(9600, SERIAL_8N1, RXD2, TXD2);

  timeClient.begin();
  timeClient.setTimeOffset(-10800); // Ajuste para fuso horário
  Firebase.begin(FIREBASE_HOST, FIREBASE_AUTH);
}

void loop() {
  if (!client.connected()) {
    reconnect();
  }
  client.loop();

  float duration, distance;

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
    digitalWrite(Buzzer, HIGH);
    delay(500);
    digitalWrite(Buzzer, LOW);
  } else if (distance >= 0 && distance < 30) {
    // Liga o buzzer
    digitalWrite(Buzzer, HIGH);
    delay(300);
    digitalWrite(Buzzer, LOW);
  } else if (distance >= 0 && distance < 20) {
    // Liga o buzzer
    digitalWrite(Buzzer, HIGH);
    delay(100);
    digitalWrite(Buzzer, LOW);
  } else if (distance >= 0 && distance < 10) {
    // Liga o buzzer
    digitalWrite(Buzzer, HIGH);
    delay(55);
    digitalWrite(Buzzer, LOW);
  } else {
    // Desliga o buzzer
    digitalWrite(Buzzer, LOW);
  }

  while (neogps.available()) {
    gps.encode(neogps.read());
  }

  if (digitalRead(PANIC_BUTTON_PIN) == LOW) {
    Serial.println("Botão de pânico pressionado!");
    
    if (gps.location.isUpdated()) {
      float latitude = gps.location.lat();
      float longitude = gps.location.lng();

      Serial.print("Latitude: ");
      Serial.println(latitude, 6);
      Serial.print("Longitude: ");
      Serial.println(longitude, 6);

      String url = "http://maps.google.com/maps?q=" + String(latitude, 6) + "," + String(longitude, 6);

      sim800.println("AT+CMGS=\"+5512997585099\"");
      delay(1000);
      sim800.print(url);
      delay(100);
      sim800.write(0x1A);
      delay(5000);

      Serial.println("SMS enviado com a localização.");
      
      PushLocationToFirebase(latitude, longitude);
    } else {
      Serial.println("Erro: Dados de GPS não detectados.");
    }
  }

  // Publicar o estado do dispositivo
  static unsigned long lastMsg = 0;
  unsigned long now = millis();
  if (now - lastMsg > 30000) { // Ajuste este valor para aumentar o intervalo entre publicações
    lastMsg = now;
    publishState();
  }

  delay(1000);
}

void PushLocationToFirebase(float latitude, float longitude) {
  while(!timeClient.update()) {
    timeClient.forceUpdate();
  }
  dataFormatada = timeClient.getFormattedTime();

  Serial.println(dataFormatada);
  
  // Extrai dia
  int splitT = dataFormatada.indexOf("T");
  dia = dataFormatada.substring(0, splitT);
  Serial.print("Data: ");
  Serial.println(dia);
  
  // Extrai hora
  hora = dataFormatada.substring(splitT+1, dataFormatada.length()-1);
  Serial.print("Hora: ");
  Serial.println(hora);
  delay(1000);
  
  // Envia dados para o Firebase
  Firebase.pushFloat("/Botao Panico/GPS/Latitude", latitude);
  Firebase.pushFloat("/Botao Panico/GPS/Longitude", longitude);
  Firebase.pushString("/Botao Panico/Tempo/Data", dia);
  Firebase.pushString("/Botao Panico/Tempo/Hora", hora);
  
  // Formata a URL do Google Maps
  String googleMapsUrl = String("https://maps.google.com/maps?q=") + String(latitude, 6) + "," + String(longitude, 6);
  Firebase.pushString("/Botao Panico/URL", googleMapsUrl);
  
  Serial.println("Dados enviados para o Firebase.");
}
