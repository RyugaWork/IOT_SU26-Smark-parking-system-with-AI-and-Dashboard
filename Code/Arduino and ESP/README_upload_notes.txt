Smart Parking System - Simple Functional Arduino Code v2

Files:
1. Master.ino
   - Upload to Master Arduino UNO.
   - Uses Master D3 sync, D11 servo, D12 LED, LCD pins D5/D6/D7/D8/D9/D10.
   - Adds WAIT_OBJECT_CLEAR state so the same object cannot trigger repeated captures.
   - Improved STATUS_BUSY handling: Master tracks the existing active capture sequence returned by the Slave.

2. Slave.ino
   - Upload to both Slave Arduino UNO boards.
   - Before uploading, change:
       #define SLAVE_ADDRESS 0x08
     for Entry Slave.
   - Then change:
       #define SLAVE_ADDRESS 0x09
     for Exit Slave.
   - Uses D2 sync, D5 Echo, D6 Trig, D3/D4 UART to ESP32-CAM.
   - Busy rule is now captureStatus != CAP_IDLE.
   - Debug mode without ESP32-CAM/camera/YOLO server:
       #define DEBUG_NO_CAMERA_YOLO 1
     Then choose mock decision:
       #define DEBUG_MOCK_DECISION_OPEN 1
     or:
       #define DEBUG_MOCK_DECISION_OPEN 0

3. ESP32_CAM.ino
   - Upload to each ESP32-CAM AI Thinker.
   - Change WIFI_SSID, WIFI_PASSWORD, and SERVER_URL before real testing.
   - Debug mode without camera, Wi-Fi, or YOLO server:
       #define DEBUG_MOCK_ONLY 1
     Then choose mock response:
       #define DEBUG_MOCK_RESULT_OPEN 1
     or:
       #define DEBUG_MOCK_RESULT_OPEN 0

Recommended test order:
1. Master + Slave only:
   - Set DEBUG_NO_CAMERA_YOLO = 1 in Slave.ino.
   - Upload Master.ino to Master.
   - Upload Slave.ino to 0x08 and 0x09.
   - Put an object within DETECTION_DISTANCE_CM.
   - Expected: Master starts capture, Slave returns mock OPEN/CLOSE, then Master waits for object clear.

2. Master + Slave + ESP32-CAM mock:
   - Set DEBUG_NO_CAMERA_YOLO = 0 in Slave.ino.
   - Set DEBUG_MOCK_ONLY = 1 in ESP32_CAM.ino.
   - Expected: Slave sends CAPTURE over UART, ESP32-CAM returns mock OPEN/CLOSE.

3. Full real test:
   - Set DEBUG_NO_CAMERA_YOLO = 0 in Slave.ino.
   - Set DEBUG_MOCK_ONLY = 0 in ESP32_CAM.ino.
   - Update WIFI_SSID, WIFI_PASSWORD, SERVER_URL.
   - Run YoloSERVER.py with host 0.0.0.0 and port 8000.

Important:
- Only Master controls the servo gate.
- Capture is asynchronous:
    CMD_START_CAPTURE starts camera capture.
    CMD_GET_CAPTURE_RESULT polls for result.
- Slave latches OPEN/CLOSE until Master reads it.
- 6-second timeout fails safe to CLOSE.
