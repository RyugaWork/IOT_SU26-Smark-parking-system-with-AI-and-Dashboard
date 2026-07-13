/*
  Smart Parking System - ESP32-CAM AI Thinker
  Version: simple functional baseline v2

  Role:
  - Wait for "CAPTURE" from Slave Arduino through UART.
  - Capture JPEG image.
  - POST JPEG to YOLO/FastAPI /detect endpoint.
  - Return plain "OPEN" or "CLOSE" to Slave.
  - Optional debug mock mode for testing without camera, Wi-Fi, or YOLO server.

  UART physical baseline: PinsLayout_v26.0621
  - ESP32-CAM GPIO1/U0TXD -> Slave Arduino D3
  - ESP32-CAM GPIO3/U0RXD <- Slave Arduino D4 through resistor network
*/

#include "esp_camera.h"
#include <WiFi.h>
#include <HTTPClient.h>

// =====================
// Wi-Fi config - change to your network
// =====================
const char* WIFI_SSID = "._.";
const char* WIFI_PASSWORD = "........";

// YOLO/FastAPI endpoint. Example: http://192.168.1.25:8000/detect
const char* SERVER_URL = "http://192.168.89.21:8000/detect";

// =====================
// Debug mode
// =====================
// Set this to 1 to test UART logic without camera, Wi-Fi, or YOLO server.
// ESP32-CAM will reply OPEN or CLOSE when it receives CAPTURE.
#define DEBUG_MOCK_ONLY 1
#define DEBUG_MOCK_RESULT_OPEN 1
#define DEBUG_MOCK_RESPONSE_MS 500UL

// HTTP timeout should be lower than the Arduino 6-second capture timeout.
#define HTTP_TIMEOUT_MS 5000

// =====================
// ESP32-CAM AI Thinker camera pins
// =====================
#define PWDN_GPIO_NUM     32
#define RESET_GPIO_NUM    -1
#define XCLK_GPIO_NUM      0
#define SIOD_GPIO_NUM     26
#define SIOC_GPIO_NUM     27

#define Y9_GPIO_NUM       35
#define Y8_GPIO_NUM       34
#define Y7_GPIO_NUM       39
#define Y6_GPIO_NUM       36
#define Y5_GPIO_NUM       21
#define Y4_GPIO_NUM       19
#define Y3_GPIO_NUM       18
#define Y2_GPIO_NUM        5
#define VSYNC_GPIO_NUM    25
#define HREF_GPIO_NUM     23
#define PCLK_GPIO_NUM     22

// =====================
// Setup
// =====================
void setup() {
  // Serial0 is the UART line to Slave Arduino in the final circuit.
  // Avoid debug logs here because Slave expects only OPEN/CLOSE responses.
  Serial.begin(9600);
  Serial.setTimeout(1000);

#if !DEBUG_MOCK_ONLY
  initCamera();
  connectWiFi(15000);
#endif
}

// =====================
// Main loop
// =====================
void loop() {
  if (Serial.available()) {
    String command = Serial.readStringUntil('\n');
    command.trim();
    command.toUpperCase();

    if (command == "CAPTURE") {
      String result = handleCaptureCommand();
      result.trim();
      result.toUpperCase();

      if (result.indexOf("OPEN") >= 0) {
        Serial.println("OPEN");
      } else {
        Serial.println("CLOSE");
      }
    }
  }

  delay(20);
}

// =====================
// Camera setup
// =====================
void initCamera() {
  camera_config_t config;
  config.ledc_channel = LEDC_CHANNEL_0;
  config.ledc_timer = LEDC_TIMER_0;

  config.pin_d0 = Y2_GPIO_NUM;
  config.pin_d1 = Y3_GPIO_NUM;
  config.pin_d2 = Y4_GPIO_NUM;
  config.pin_d3 = Y5_GPIO_NUM;
  config.pin_d4 = Y6_GPIO_NUM;
  config.pin_d5 = Y7_GPIO_NUM;
  config.pin_d6 = Y8_GPIO_NUM;
  config.pin_d7 = Y9_GPIO_NUM;

  config.pin_xclk = XCLK_GPIO_NUM;
  config.pin_pclk = PCLK_GPIO_NUM;
  config.pin_vsync = VSYNC_GPIO_NUM;
  config.pin_href = HREF_GPIO_NUM;

  config.pin_sccb_sda = SIOD_GPIO_NUM;
  config.pin_sccb_scl = SIOC_GPIO_NUM;
  config.pin_pwdn = PWDN_GPIO_NUM;
  config.pin_reset = RESET_GPIO_NUM;

  config.xclk_freq_hz = 20000000;
  config.pixel_format = PIXFORMAT_JPEG;

  if (psramFound()) {
    config.frame_size = FRAMESIZE_VGA;
    config.jpeg_quality = 12;
    config.fb_count = 2;
    config.fb_location = CAMERA_FB_IN_PSRAM;
  } else {
    config.frame_size = FRAMESIZE_QVGA;
    config.jpeg_quality = 15;
    config.fb_count = 1;
    config.fb_location = CAMERA_FB_IN_DRAM;
  }

  config.grab_mode = CAMERA_GRAB_LATEST;

  esp_err_t err = esp_camera_init(&config);
  if (err != ESP_OK) {
    delay(1000);
    ESP.restart();
  }
}

// =====================
// Wi-Fi and server logic
// =====================
bool connectWiFi(unsigned long timeoutMs) {
  if (WiFi.status() == WL_CONNECTED) return true;

  WiFi.mode(WIFI_STA);
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);

  unsigned long startMs = millis();
  while (WiFi.status() != WL_CONNECTED && millis() - startMs < timeoutMs) {
    delay(250);
  }

  return WiFi.status() == WL_CONNECTED;
}

String handleCaptureCommand() {
#if DEBUG_MOCK_ONLY
  delay(DEBUG_MOCK_RESPONSE_MS);
#if DEBUG_MOCK_RESULT_OPEN
  return "OPEN";
#else
  return "CLOSE";
#endif
#else
  if (!connectWiFi(3000)) {
    return "CLOSE";
  }

  camera_fb_t* fb = esp_camera_fb_get();
  if (!fb) {
    return "CLOSE";
  }

  String serverResponse = sendImageToServer(fb);
  esp_camera_fb_return(fb);

  if (serverResponse.length() == 0) {
    return "CLOSE";
  }

  return serverResponse;
#endif
}

String sendImageToServer(camera_fb_t* fb) {
  HTTPClient http;
  String payload = "CLOSE";

  http.begin(SERVER_URL);
  http.setTimeout(HTTP_TIMEOUT_MS);
  http.addHeader("Content-Type", "image/jpeg");

  int httpCode = http.POST(fb->buf, fb->len);

  if (httpCode > 0) {
    payload = http.getString();
  }

  http.end();
  return payload;
}
