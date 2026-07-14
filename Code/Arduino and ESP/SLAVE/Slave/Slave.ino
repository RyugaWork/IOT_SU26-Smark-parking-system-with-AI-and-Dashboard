/*
  Smart Parking System - Slave Arduino UNO
  Version: simple functional baseline v2

  Role:
  - Read ultrasonic sensor.
  - Receive I2C commands from Master.
  - Trigger local ESP32-CAM through UART when Master sends CMD_START_CAPTURE.
  - Latch OPEN/CLOSE result until Master polls CMD_GET_CAPTURE_RESULT.
  - Provide a debug mode for testing without ESP32-CAM, camera, Wi-Fi, or YOLO server.

  Upload this same sketch to both Slave boards.
  Change SLAVE_ADDRESS before upload:
    0x08 = Entry Slave
    0x09 = Exit Slave

  Pin baseline: PinsLayout_v26.0621
*/

#include <Wire.h>
#include <SoftwareSerial.h>

// =====================
// Board address - change before uploading to each Slave
// =====================
#define SLAVE_ADDRESS 0x08   // Use 0x08 for Entry, 0x09 for Exit

// =====================
// PinsLayout_v26.0621 - Slave Arduino UNO
// =====================
#define SLAVE_SYNC_PIN 2   // D2 -> shared Sync input from Master D3
#define SLAVE_ECHO_PIN 5   // D5 -> Ultrasonic ECHO
#define SLAVE_TRIG_PIN 6   // D6 -> Ultrasonic TRIG

// Physical UART lines to ESP32-CAM
// ESP32-CAM GPIO1 is U0TXD, so Arduino receives on D3.
// ESP32-CAM GPIO3 is U0RXD, so Arduino transmits on D4 through resistor network.
#define ESP_RX_FROM_CAM_PIN 3 // Grey
#define ESP_TX_TO_CAM_PIN   4 // White

// =====================
// Debug mode
// =====================
// Set this to 1 to test Master + Slave using only ultrasonic sensor.
// In this mode, Slave does not wait for ESP32-CAM or YOLO server.
#define DEBUG_NO_CAMERA_YOLO 0

// Used only when DEBUG_NO_CAMERA_YOLO = 1.
// 1 = return OPEN after DEBUG_MOCK_RESPONSE_MS.
// 0 = return CLOSE after DEBUG_MOCK_RESPONSE_MS.
#define DEBUG_MOCK_DECISION_OPEN 1
#define DEBUG_MOCK_RESPONSE_MS   800UL

// =====================
// Sensor and timing settings
// =====================
#define DETECTION_DISTANCE_CM   15
#define MAX_DISTANCE_CM         300
#define SENSOR_REFRESH_MS       1000UL
#define CAPTURE_HARD_TIMEOUT_MS 6000UL

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
  uint8_t gateId;
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
SoftwareSerial espCamSerial(ESP_RX_FROM_CAM_PIN, ESP_TX_TO_CAM_PIN); // RX, TX

volatile bool syncTriggered = false;

uint8_t lastCommand = CMD_READ_SENSOR;
uint16_t lastCommandSeq = 0;

uint16_t latestDistanceCm = MAX_DISTANCE_CM;
uint8_t latestObjectDetected = 0;
unsigned long lastSensorReadMs = 0;

uint8_t lastAckStatus = STATUS_OK;
uint16_t lastAckSeq = 0;

uint8_t captureStatus = CAP_IDLE;
uint8_t captureDecision = DECISION_NONE;
uint16_t captureSeq = 0;
unsigned long captureStartMs = 0;
bool pendingCaptureStart = false;
bool resetCaptureAfterResultRead = false;

// =====================
// Interrupt
// =====================
void syncEvent() {
  syncTriggered = true;
}

// =====================
// Setup
// =====================
void setup() {
  Serial.begin(9600);
  espCamSerial.begin(9600);
  espCamSerial.setTimeout(50);

  pinMode(SLAVE_TRIG_PIN, OUTPUT);
  pinMode(SLAVE_ECHO_PIN, INPUT);

  pinMode(SLAVE_SYNC_PIN, INPUT);
  attachInterrupt(digitalPinToInterrupt(SLAVE_SYNC_PIN), syncEvent, RISING);

  Wire.begin(SLAVE_ADDRESS);
  Wire.onReceive(receiveEvent);
  Wire.onRequest(requestEvent);

  readAndStoreSensor();

  Serial.print("Slave ready. Address: 0x");
  Serial.println(SLAVE_ADDRESS, HEX);

#if DEBUG_NO_CAMERA_YOLO
  Serial.println("DEBUG_NO_CAMERA_YOLO enabled. Slave will mock OPEN/CLOSE result.");
#endif
}

// =====================
// Main loop
// =====================
void loop() {
  unsigned long now = millis();

  if (syncTriggered || now - lastSensorReadMs >= SENSOR_REFRESH_MS) {
    syncTriggered = false;
    readAndStoreSensor();
  }

  if (pendingCaptureStart) {
    pendingCaptureStart = false;
    captureStatus = CAP_PROCESSING;
    captureDecision = DECISION_NONE;
    captureStartMs = millis();

#if DEBUG_NO_CAMERA_YOLO
    Serial.print("Debug capture started. Seq: ");
    Serial.println(captureSeq);
#else
    clearEspSerialBuffer();
    espCamSerial.println("CAPTURE");
    Serial.print("Capture command sent to ESP32-CAM. Seq: ");
    Serial.println(captureSeq);
#endif
  }

  updateCaptureState();

  if (resetCaptureAfterResultRead) {
    resetCaptureAfterResultRead = false;
    resetCaptureState();
  }
}

// =====================
// I2C events
// =====================
void receiveEvent(int byteCount) {
  if (byteCount <= 0) return;

  uint8_t buffer[16];
  uint8_t index = 0;

  while (Wire.available() && index < sizeof(buffer)) {
    buffer[index++] = Wire.read();
  }

  uint8_t command = buffer[0];
  lastCommand = command;

  if (command == CMD_READ_SENSOR || command == CMD_GET_CAPTURE_RESULT) {
    if (index >= sizeof(BasicCommand)) {
      BasicCommand* basic = (BasicCommand*)buffer;
      lastCommandSeq = basic->seq;
    }
    return;
  }

  if (command == CMD_START_CAPTURE) {
    if (index < sizeof(CaptureStartCommand)) {
      lastAckStatus = STATUS_ERROR;
      lastAckSeq = 0;
      return;
    }

    CaptureStartCommand* startCommand = (CaptureStartCommand*)buffer;
    lastAckSeq = startCommand->seq;

    // Improved busy check:
    // Any non-idle capture state is busy, including CAP_DONE, CAP_TIMEOUT,
    // and CAP_ERROR while the result is still latched for Master to read.
    if (captureStatus != CAP_IDLE) {
      lastAckStatus = STATUS_BUSY;
      lastAckSeq = captureSeq;  // Tell Master which existing capture seq to poll.
      return;
    }

    captureSeq = startCommand->seq;
    captureStatus = CAP_REQUESTED;
    captureDecision = DECISION_NONE;
    pendingCaptureStart = true;
    lastAckStatus = STATUS_OK;
    lastAckSeq = captureSeq;
    return;
  }
}

void requestEvent() {
  if (lastCommand == CMD_START_CAPTURE) {
    CaptureAckResponse response;
    response.commandEcho = CMD_START_CAPTURE;
    response.status = lastAckStatus;
    response.seq = lastAckSeq;
    Wire.write((uint8_t*)&response, sizeof(response));
    return;
  }

  if (lastCommand == CMD_GET_CAPTURE_RESULT) {
    CaptureResultResponse response;
    response.commandEcho = CMD_GET_CAPTURE_RESULT;
    response.captureStatus = captureStatus;
    response.decision = captureDecision;
    response.detectedClass = 0;
    response.confidence = 0;
    response.seq = captureSeq;

    Wire.write((uint8_t*)&response, sizeof(response));

    if (captureStatus == CAP_DONE || captureStatus == CAP_TIMEOUT || captureStatus == CAP_ERROR) {
      resetCaptureAfterResultRead = true;
    }
    return;
  }

  SensorResponse response;
  response.commandEcho = CMD_READ_SENSOR;
  response.status = STATUS_OK;
  response.distanceCm = latestDistanceCm;
  response.objectDetected = latestObjectDetected;
  response.seq = lastCommandSeq;
  Wire.write((uint8_t*)&response, sizeof(response));
}

// =====================
// Sensor logic
// =====================
void readAndStoreSensor() {
  lastSensorReadMs = millis();
  latestDistanceCm = readUltrasonicDistanceCm();
  latestObjectDetected = (latestDistanceCm > 0 && latestDistanceCm <= DETECTION_DISTANCE_CM) ? 1 : 0;

  Serial.print("Distance: ");
  Serial.print(latestDistanceCm);
  Serial.print(" cm, detected: ");
  Serial.println(latestObjectDetected);
}

uint16_t readUltrasonicDistanceCm() {
  digitalWrite(SLAVE_TRIG_PIN, LOW);
  delayMicroseconds(2);

  digitalWrite(SLAVE_TRIG_PIN, HIGH);
  delayMicroseconds(10);

  digitalWrite(SLAVE_TRIG_PIN, LOW);

  unsigned long duration = pulseIn(SLAVE_ECHO_PIN, HIGH, 30000UL);

  if (duration == 0) {
    return MAX_DISTANCE_CM;
  }

  uint16_t distanceCm = (uint16_t)(duration * 0.0343 / 2.0);

  if (distanceCm > MAX_DISTANCE_CM) {
    return MAX_DISTANCE_CM;
  }

  return distanceCm;
}

// =====================
// Capture logic
// =====================
void updateCaptureState() {
  if (captureStatus != CAP_PROCESSING) return;

#if DEBUG_NO_CAMERA_YOLO
  if (millis() - captureStartMs >= DEBUG_MOCK_RESPONSE_MS) {
    captureStatus = CAP_DONE;
#if DEBUG_MOCK_DECISION_OPEN
    captureDecision = DECISION_OPEN;
    Serial.println("Debug result: OPEN");
#else
    captureDecision = DECISION_CLOSE;
    Serial.println("Debug result: CLOSE");
#endif
    return;
  }
#else
  if (espCamSerial.available()) {
    String result = espCamSerial.readStringUntil('\n');
    result.trim();
    result.toUpperCase();

    if (result.indexOf("OPEN") >= 0) {
      captureStatus = CAP_DONE;
      captureDecision = DECISION_OPEN;
      Serial.println("ESP32-CAM result: OPEN");
      return;
    }

    if (result.indexOf("CLOSE") >= 0) {
      captureStatus = CAP_DONE;
      captureDecision = DECISION_CLOSE;
      Serial.println("ESP32-CAM result: CLOSE");
      return;
    }
  }
#endif

  if (millis() - captureStartMs >= CAPTURE_HARD_TIMEOUT_MS) {
    captureStatus = CAP_TIMEOUT;
    captureDecision = DECISION_CLOSE;
    Serial.println("Capture timeout. Decision CLOSE.");
  }
}

void resetCaptureState() {
  captureStatus = CAP_IDLE;
  captureDecision = DECISION_NONE;
  captureSeq = 0;
  captureStartMs = 0;
  pendingCaptureStart = false;
}

void clearEspSerialBuffer() {
  while (espCamSerial.available()) {
    espCamSerial.read();
  }
}
