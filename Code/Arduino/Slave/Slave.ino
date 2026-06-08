// C++ code
//

#include <Wire.h>

// =============================
// Slave 1 I2C Address
// =============================
#define SLAVE_ADDRESS //0x08 || 0x09

// =============================
// Input Pins
// =============================
#define SYNC_PIN 2

// =============================
// Ultrasonic Sensor Pins
// =============================
#define TRIG_PIN 11
#define ECHO_PIN 10

// =============================
// Detection Settings
// =============================
#define DETECTION_DISTANCE 200
#define MAX_DISTANCE 300

// =============================
// Packages
// =============================

struct REQpackage {
};

struct RESpackage {
	long sensor;
  bool detect;
};



// =============================

RESpackage responce;

bool syncTriggered = false;

void requestEvent() {
  Wire.write((byte*)&responce, sizeof(responce));
}

void syncEvent() {
  syncTriggered = true; 
}


int readUltrasonicDistance() {
  digitalWrite(TRIG_PIN, LOW);
  delayMicroseconds(2);

  digitalWrite(TRIG_PIN, HIGH);
  delayMicroseconds(10);

  digitalWrite(TRIG_PIN, LOW);

  long duration = pulseIn(ECHO_PIN, HIGH, 30000);

  if (duration == 0) {
    return MAX_DISTANCE;
  }

  int distance = duration * 0.034 / 2;
  return distance;
}

void setup()
{
  Serial.begin(9600);

  pinMode(TRIG_PIN, OUTPUT);
  pinMode(ECHO_PIN, INPUT);

  pinMode(SYNC_PIN, INPUT); 
  attachInterrupt(digitalPinToInterrupt(SYNC_PIN), syncEvent, RISING);

  Wire.begin(SLAVE_ADDRESS);
  Wire.onRequest(requestEvent);
}

void loop()
{
  if (!syncTriggered) return;
  syncTriggered = false;

  responce.sensor = readUltrasonicDistance();

  if (responce.sensor > 0 && responce.sensor <= DETECTION_DISTANCE) {
    responce.detect = 1;
  } else {
    responce.detect = 0;
  }
  
  Serial.print("Slave: ");
  Serial.print(responce.sensor);
  Serial.print(", ");
  Serial.println(responce.detect);
}