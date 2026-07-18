/*
  Smart Parking System - Master Arduino UNO
  Version: simple functional baseline v2

  Role:
  - Poll Slave 0x08 and Slave 0x09 through I2C.
  - Start ESP32-CAM capture through the selected Slave when ultrasonic detection is stable.
  - Poll capture result asynchronously.
  - Open/close the barrier servo only from Master.
  - Wait for the object to leave before allowing another capture.

  Pin baseline: PinsLayout_v26.0621
*/

#include <Wire.h>
#include <Servo.h>
#include <LiquidCrystal.h>
#include <string.h>

// =====================
// I2C addresses
// =====================
#define SLAVE_ENTRY_ADDRESS 0x08
#define SLAVE_EXIT_ADDRESS  0x09

// =====================
// PinsLayout_v26.0621 - Master Arduino UNO
// =====================
#define MASTER_SYNC_PIN  13  // D3  -> shared Sync bus
#define MASTER_SERVO_PIN 11  // D11 -> Servo SG90 signal
#define MASTER_LED_PIN   12  // D12 -> status LED

#define LCD_RS 9
#define LCD_E  10
#define LCD_D4 5
#define LCD_D5 6
#define LCD_D6 7
#define LCD_D7 8

// =====================
// Gate and timing settings
// =====================
#define GATE_CLOSED_ANGLE 90
#define GATE_OPEN_ANGLE   0

#define SENSOR_POLL_MS          1000UL
#define RESULT_POLL_MS          500UL
#define CAPTURE_HARD_TIMEOUT_MS 6000UL
#define GATE_HOLD_MS            3000UL
#define STABLE_DETECT_COUNT     2

// =====================
// Debug settings
// =====================
#define DEBUG_SERIAL 1

// =====================
// Protocol definitions
// =====================
enum Command : uint8_t {
  CMD_READ_SENSOR = 1,
  CMD_HEALTH = 2,
  CMD_GET_SLOTS = 3,
  CMD_GATE_STATE = 4,
  CMD_START_CAPTURE = 5,
  CMD_GET_CAPTURE_RESULT = 6,
  CMD_ACK_CAPTURE_RESULT = 7
};

enum Status : uint8_t {
  STATUS_OK = 0,
  STATUS_BUSY = 1,
  STATUS_TIMEOUT = 2,
  STATUS_ERROR = 3,
  STATUS_STALE = 4
};

enum CaptureStatus : uint8_t {
  CAP_IDLE = 0,
  CAP_REQUESTED = 1,
  CAP_PROCESSING = 2,
  CAP_DONE = 3,
  CAP_TIMEOUT = 4,
  CAP_ERROR = 5
};

enum GateDecision : uint8_t {
  DECISION_NONE = 0,
  DECISION_OPEN = 1,
  DECISION_CLOSE = 2
};

struct BasicCommand {
  uint8_t command;
  uint16_t seq;
};

struct CaptureStartCommand {
  uint8_t command;
  uint8_t gateId;       // 1 = entry, 2 = exit
  uint16_t distanceCm;
  uint16_t seq;
};

struct SensorResponse {
  uint8_t commandEcho;
  uint8_t status;
  uint16_t distanceCm;
  uint8_t objectDetected;
  uint16_t seq;
};

struct CaptureAckResponse {
  uint8_t commandEcho;
  uint8_t status;
  uint16_t seq;
};

struct CaptureResultResponse {
  uint8_t commandEcho;
  uint8_t captureStatus;
  uint8_t decision;
  uint8_t detectedClass;
  uint8_t confidence;
  uint16_t seq;
};

// =====================
// Runtime state
// =====================
enum MasterState {
  IDLE_CLOSED,
  VERIFYING_CAMERA,
  OPEN_HOLD,
  WAIT_OBJECT_CLEAR
};

Servo gateServo;
LiquidCrystal lcd(LCD_RS, LCD_E, LCD_D4, LCD_D5, LCD_D6, LCD_D7);

MasterState masterState = IDLE_CLOSED;

uint16_t sensorSeq = 0;
uint16_t captureSeq = 0;
uint16_t activeCaptureSeq = 0;
uint8_t activeSlaveAddress = 0;
uint8_t activeGateId = 0;

unsigned long lastSensorPollMs = 0;
unsigned long lastResultPollMs = 0;
unsigned long captureStartMs = 0;
unsigned long gateOpenedMs = 0;

uint8_t stableEntryCount = 0;
uint8_t stableExitCount = 0;

// =====================
// Setup
// =====================
void setup() {
  Serial.begin(9600);
  Wire.begin();

  pinMode(MASTER_SYNC_PIN, OUTPUT);
  digitalWrite(MASTER_SYNC_PIN, LOW);

  pinMode(MASTER_LED_PIN, OUTPUT);
  digitalWrite(MASTER_LED_PIN, LOW);

  gateServo.attach(MASTER_SERVO_PIN);
  closeGate();

  lcd.begin(16, 2);
  showStatus("Smart Parking", "System Ready");

#if DEBUG_SERIAL
  Serial.println("Master ready. version 2.0");
#endif
}

// =====================
// Main loop
// =====================
void loop() {
#if DEBUG_SERIAL
        Serial.println("Master loop");
#endif
  unsigned long now = millis();

  switch (masterState) {
    case IDLE_CLOSED:
      if (now - lastSensorPollMs >= SENSOR_POLL_MS) {
        lastSensorPollMs = now;
        pollSensorsAndMaybeStartCapture();
      }
      break;

    case VERIFYING_CAMERA:
      if (now - captureStartMs >= CAPTURE_HARD_TIMEOUT_MS) {
#if DEBUG_SERIAL
        Serial.println("Master timeout. Gate remains closed.");
#endif
        showStatus("Camera Timeout", "Gate Closed");
        closeGate();
        enterWaitObjectClear();
        break;
      }

      if (now - lastResultPollMs >= RESULT_POLL_MS) {
        lastResultPollMs = now;
        pollCaptureResult();
      }
      break;

    case OPEN_HOLD:
      if (now - gateOpenedMs >= GATE_HOLD_MS) {
        // closeGate();
        showStatus("Gate Closed", "Move Vehicle");
        enterWaitObjectClear();
      }
      break;

    case WAIT_OBJECT_CLEAR:
      if (now - lastSensorPollMs >= SENSOR_POLL_MS) {
        lastSensorPollMs = now;
        waitUntilObjectClears();
      }
      break;
  }
  delay(100);
}

// =====================
// Sensor polling
// =====================
void pollSensorsAndMaybeStartCapture() {
  sendSyncPulse();

  SensorResponse entry = readSensorFromSlave(SLAVE_ENTRY_ADDRESS);
  SensorResponse exitGate = readSensorFromSlave(SLAVE_EXIT_ADDRESS);

  printSensor("Entry", entry);
  printSensor("Exit ", exitGate);

  if (entry.status != STATUS_OK && exitGate.status != STATUS_OK) {
    showStatus("Slave Error", "Check I2C");
    return;
  }

  stableEntryCount = entry.objectDetected ? stableEntryCount + 1 : 0;
  stableExitCount = exitGate.objectDetected ? stableExitCount + 1 : 0;

  if (stableEntryCount >= STABLE_DETECT_COUNT) {
    startCapture(SLAVE_ENTRY_ADDRESS, 1, entry.distanceCm);
  } else if (stableExitCount >= STABLE_DETECT_COUNT) {
    startCapture(SLAVE_EXIT_ADDRESS, 2, exitGate.distanceCm);
  } else {
    showDistance(entry.distanceCm, exitGate.distanceCm);
  }
}

void waitUntilObjectClears() {
  sendSyncPulse();

  SensorResponse entry = readSensorFromSlave(SLAVE_ENTRY_ADDRESS);
  SensorResponse exitGate = readSensorFromSlave(SLAVE_EXIT_ADDRESS);

  uint8_t selectedDetected = 0;

  if (activeGateId == 1) {
    selectedDetected = entry.objectDetected;
  } else if (activeGateId == 2) {
    selectedDetected = exitGate.objectDetected;
  } else {
    selectedDetected = entry.objectDetected || exitGate.objectDetected;
  }

  if (selectedDetected) {
    showStatus("Wait Object", "Clear Sensor");
#if DEBUG_SERIAL
    Serial.println("Waiting for object to clear before next capture.");
#endif
    return;
  }

#if DEBUG_SERIAL
  Serial.println("Object clear. Returning to IDLE_CLOSED.");
#endif
  showStatus("Object Clear", "Polling...");
  resetToIdle();
}

void sendSyncPulse() {
  digitalWrite(MASTER_SYNC_PIN, HIGH);
  delay(5);
  digitalWrite(MASTER_SYNC_PIN, LOW);
  delay(5);
}

SensorResponse readSensorFromSlave(uint8_t slaveAddress) {
  SensorResponse response;
  memset(&response, 0, sizeof(response));
  response.status = STATUS_ERROR;
  response.distanceCm = 999;

  BasicCommand command;
  command.command = CMD_READ_SENSOR;
  command.seq = ++sensorSeq;

  Wire.beginTransmission(slaveAddress);
  Wire.write((uint8_t*)&command, sizeof(command));
  uint8_t txStatus = Wire.endTransmission();

  if (txStatus != 0) {
    response.status = STATUS_ERROR;
    return response;
  }

  delay(5);
  Wire.requestFrom((int)slaveAddress, (int)sizeof(response));

  if (Wire.available() == sizeof(response)) {
    uint8_t* ptr = (uint8_t*)&response;
    for (uint8_t i = 0; i < sizeof(response); i++) {
      ptr[i] = Wire.read();
    }
  }

  return response;
}

// =====================
// Capture flow
// =====================
void startCapture(uint8_t slaveAddress, uint8_t gateId, uint16_t distanceCm) {
  activeSlaveAddress = slaveAddress;
  activeGateId = gateId;
  activeCaptureSeq = ++captureSeq;

  CaptureStartCommand command;
  command.command = CMD_START_CAPTURE;
  command.gateId = gateId;
  command.distanceCm = distanceCm;
  command.seq = activeCaptureSeq;

  CaptureAckResponse ack;
  memset(&ack, 0, sizeof(ack));
  ack.commandEcho = CMD_START_CAPTURE;
  ack.status = STATUS_ERROR;
  ack.seq = 0;

  Wire.beginTransmission(slaveAddress);
  Wire.write((uint8_t*)&command, sizeof(command));
  uint8_t txStatus = Wire.endTransmission();

  if (txStatus != 0) {
#if DEBUG_SERIAL
    Serial.println("START_CAPTURE I2C error.");
#endif
    showStatus("I2C Error", "Gate Closed");
    closeGate();
    enterWaitObjectClear();
    return;
  }

  delay(5);
  Wire.requestFrom((int)slaveAddress, (int)sizeof(ack));

  if (Wire.available() == sizeof(ack)) {
    uint8_t* ptr = (uint8_t*)&ack;
    for (uint8_t i = 0; i < sizeof(ack); i++) {
      ptr[i] = Wire.read();
    }
  }

  if (ack.status == STATUS_OK && ack.seq == activeCaptureSeq) {
#if DEBUG_SERIAL
    Serial.print("Capture started. GateId: ");
    Serial.print(gateId);
    Serial.print(" Seq: ");
    Serial.println(activeCaptureSeq);
#endif
    captureStartMs = millis();
    lastResultPollMs = 0;
    masterState = VERIFYING_CAMERA;
    showStatus("Verifying...", gateId == 1 ? "Entry Gate" : "Exit Gate");
    return;
  }

  if (ack.status == STATUS_BUSY) {
    handleBusyAck(ack, slaveAddress, gateId);
    return;
  }

#if DEBUG_SERIAL
  Serial.println("Capture rejected or failed.");
#endif
  showStatus("Capture Error", "Gate Closed");
  closeGate();
  enterWaitObjectClear();
}

void handleBusyAck(const CaptureAckResponse& ack, uint8_t slaveAddress, uint8_t gateId) {
  activeSlaveAddress = slaveAddress;
  activeGateId = gateId;

  // Improved busy handling:
  // If the Slave is already processing or holding a latched result, it returns
  // the active capture sequence. Master follows that sequence instead of
  // starting a new one and losing synchronization.
  if (ack.seq != 0) {
    activeCaptureSeq = ack.seq;
  }

#if DEBUG_SERIAL
  Serial.print("Slave busy. Tracking existing capture seq: ");
  Serial.println(activeCaptureSeq);
#endif

  captureStartMs = millis();
  lastResultPollMs = 0;
  masterState = VERIFYING_CAMERA;
  showStatus("Camera Busy", "Polling Result");
}

void pollCaptureResult() {
  if (activeSlaveAddress == 0 || activeCaptureSeq == 0) {
    showStatus("No Active Cap", "Gate Closed");
    closeGate();
    enterWaitObjectClear();
    return;
  }

  CaptureResultResponse response;
  memset(&response, 0, sizeof(response));

  BasicCommand command;
  command.command = CMD_GET_CAPTURE_RESULT;
  command.seq = activeCaptureSeq;

  Wire.beginTransmission(activeSlaveAddress);
  Wire.write((uint8_t*)&command, sizeof(command));
  uint8_t txStatus = Wire.endTransmission();

  if (txStatus != 0) {
#if DEBUG_SERIAL
    Serial.println("GET_CAPTURE_RESULT I2C error.");
#endif
    return;
  }

  delay(5);
  Wire.requestFrom((int)activeSlaveAddress, (int)sizeof(response));

  if (Wire.available() != sizeof(response)) {
#if DEBUG_SERIAL
    Serial.println("Incomplete capture result.");
#endif
    return;
  }

  uint8_t* ptr = (uint8_t*)&response;
  for (uint8_t i = 0; i < sizeof(response); i++) {
    ptr[i] = Wire.read();
  }

  if (response.seq != activeCaptureSeq) {
#if DEBUG_SERIAL
    Serial.print("Stale capture result ignored. Expected seq: ");
    Serial.print(activeCaptureSeq);
    Serial.print(" Got seq: ");
    Serial.println(response.seq);
#endif
    showStatus("Stale Result", "Gate Closed");
    closeGate();
    enterWaitObjectClear();
    return;
  }

  if (response.captureStatus == CAP_PROCESSING || response.captureStatus == CAP_REQUESTED) {
#if DEBUG_SERIAL
    Serial.println("Camera still processing...");
#endif
    showStatus("Processing...", "Wait Result");
    return;
  }

  if (response.captureStatus == CAP_DONE && response.decision == DECISION_OPEN) {
#if DEBUG_SERIAL
    Serial.println("Decision OPEN. Opening gate.");
#endif
    openGate();
    showStatus("Decision: OPEN", "Gate Opening");
    masterState = OPEN_HOLD;
    gateOpenedMs = millis();
    return;
  }

#if DEBUG_SERIAL
  Serial.println("Decision CLOSE / timeout / error. Gate remains closed.");
#endif
  showStatus("Decision: CLOSE", "Gate Closed");
  closeGate();
  enterWaitObjectClear();
}

// =====================
// Gate and state control
// =====================
void openGate() {
  digitalWrite(MASTER_LED_PIN, HIGH);
  gateServo.write(GATE_OPEN_ANGLE);
}

void closeGate() {
  gateServo.write(GATE_CLOSED_ANGLE);
  digitalWrite(MASTER_LED_PIN, LOW);
}

void enterWaitObjectClear() {
  stableEntryCount = 0;
  stableExitCount = 0;
  masterState = WAIT_OBJECT_CLEAR;
}

void resetToIdle() {
  activeSlaveAddress = 0;
  activeGateId = 0;
  activeCaptureSeq = 0;
  stableEntryCount = 0;
  stableExitCount = 0;
  masterState = IDLE_CLOSED;
}

// =====================
// LCD and Serial helpers
// =====================
void showStatus(const char* line1, const char* line2) {
  // Serial.print("LCD:");
  // Serial.print(line1);
  // Serial.print(":");
  // Serial.println(line2);
  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print(line1);
  lcd.setCursor(0, 1);
  lcd.print(line2);
}

void showDistance(uint16_t entryCm, uint16_t exitCm) {
  lcd.setCursor(0, 0);
  lcd.print("Entry:");
  lcd.print(entryCm);
  lcd.print("cm");
  lcd.setCursor(0, 1);
  lcd.print("Exit :");
  lcd.print(exitCm);
  lcd.print("cm");
}

void printSensor(const char* name, const SensorResponse& response) {
#if DEBUG_SERIAL
  Serial.print(name);
  Serial.print(" distance=");
  Serial.print(response.distanceCm);
  Serial.print("cm detect=");
  Serial.print(response.objectDetected);
  Serial.print(" status=");
  Serial.println(response.status);
#endif
}
