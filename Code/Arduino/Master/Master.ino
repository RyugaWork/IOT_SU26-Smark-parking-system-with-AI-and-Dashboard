// C++ code
//

#include <Wire.h>
#include <Servo.h>

// =============================
// I2C Slave Addresses
// =============================
#define SLAVE_1_ADDRESS 0x08
#define SLAVE_2_ADDRESS 0x09

// =============================
// Output Pins
// =============================
#define SERVO_PIN 7
#define LED_PIN 8
#define SYNCPIN 3

// =============================
// Input Pins
// =============================

// =============================
// Gate Settings
// =============================
#define GATE_CLOSED_ANGLE 0
#define GATE_OPEN_ANGLE 90

// =============================
// Packages
// =============================

struct REQpackage {
  long sensor;
  bool detect;
};

struct RESpackage {
	
};

// =============================

Servo gateServo;
bool isGateOpen = false;

void setup()
{
  Serial.begin(9600);
  Wire.begin(); 
  
  pinMode(SYNCPIN, OUTPUT);
  digitalWrite(SYNCPIN, LOW);
  pinMode(LED_PIN, OUTPUT);
  digitalWrite(LED_PIN, LOW);
  
  gateServo.attach(SERVO_PIN);
}

REQpackage retrivePackage;
void requestSlave(byte slaveAddress) {
  int size = sizeof(retrivePackage);

  Wire.requestFrom((int)slaveAddress, size);

  if (Wire.available() >= size) {
    byte* ptr = (byte*)&retrivePackage;

    for (int i = 0; i < size; i++) {
      ptr[i] = Wire.read();
    }
  }
}

void loop()
{
  digitalWrite(SYNCPIN, HIGH);
  delay(70);
  // -------------------------
  requestSlave(SLAVE_1_ADDRESS);
  REQpackage slave1 = retrivePackage;
  requestSlave(SLAVE_2_ADDRESS);
  REQpackage slave2 = retrivePackage;
  
  bool objectDetect = slave1.detect || slave2.detect;
  
  Serial.print("Slave 1: ");
  Serial.print(slave1.sensor);
  Serial.print(", ");
  Serial.println(slave1.detect);
  Serial.print("Slave 2: ");
  Serial.print(slave2.sensor);
  Serial.print(", ");
  Serial.println(slave2.detect);
  
  if(objectDetect && isGateOpen == false) {
    isGateOpen = true;
  	openGate();
  } else if(!objectDetect && isGateOpen == true) {
    isGateOpen = false;
	  closeGate();
  }
  // -------------------------
  digitalWrite(SYNCPIN, LOW);
  delay(1000);
}

void openGate() {
  Serial.println("Opening gate");

  digitalWrite(LED_PIN, HIGH);
  gateServo.write(GATE_OPEN_ANGLE);
}

void closeGate() {
  Serial.println("Closing gate");

  gateServo.write(GATE_CLOSED_ANGLE);
  digitalWrite(LED_PIN, LOW);
}