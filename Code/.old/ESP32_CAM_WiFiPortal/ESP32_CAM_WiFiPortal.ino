/*
 * Smart Parking System - ESP32-CAM with Wi-Fi Configuration Portal
 *
 * Main flow:
 *   Slave Arduino -> UART "CAPTURE"
 *   ESP32-CAM -> capture JPEG
 *   ESP32-CAM -> HTTP POST /detect?module=ENTRY|EXIT
 *   YOLO server -> plain text OPEN or CLOSE
 *   ESP32-CAM -> UART OPEN or CLOSE
 *
 * Wi-Fi upgrade:
 *   - Stores SSID, password, server base URL, and camera role in Preferences/NVS.
 *   - Starts SmartParking_Config access point when configuration is missing
 *     or Wi-Fi cannot connect.
 *   - Configuration page: http://192.168.4.1
 *   - When connected normally, the same page is available from the ESP32-CAM
 *     local IP and, when mDNS works, at:
 *       http://smartparking-entry.local
 *       http://smartparking-exit.local
 *
 * UART baseline:
 *   ESP32-CAM GPIO1 / U0TXD -> Slave Arduino D3
 *   ESP32-CAM GPIO3 / U0RXD <- Slave Arduino D4 through resistor protection
 *
 * Important:
 *   Serial0 is used by the Slave Arduino. Do not add debug Serial.print()
 *   messages because any extra UART text can corrupt the OPEN/CLOSE protocol.
 */

#include "esp_camera.h"
#include <WiFi.h>
#include <HTTPClient.h>
#include <WebServer.h>
#include <Preferences.h>
#include <ESPmDNS.h>

// ============================================================
// Build options
// ============================================================

// 1 = UART test only: CAPTURE always returns OPEN.
// 0 = Real camera + Wi-Fi + YOLO server.
#define USE_MOCK_SERVER 0
// 1 = tự động chụp và gửi một ảnh lên YOLO sau khi setup.
// 0 = tắt tính năng debug tự động.
#define AUTO_YOLO_DEBUG_AFTER_SETUP 1

// In thông tin HTTP qua Serial.
// Chỉ bật khi ESP32-CAM đang được test riêng, chưa nối UART với Slave.
#define YOLO_HTTP_DEBUG 1

const unsigned long AUTO_YOLO_DEBUG_DELAY_MS = 3000;

// ============================================================
// Timing
// ============================================================

// Startup connection may take longer because no capture is active.
const unsigned long STARTUP_WIFI_TIMEOUT_MS = 20000;

// During CAPTURE, reconnect quickly so the complete camera/server operation
// remains below the Slave's 6-second hard timeout.
const unsigned long CAPTURE_WIFI_TIMEOUT_MS = 1200;
const unsigned long HTTP_TIMEOUT_MS = 3500;

// Background network recovery.
const unsigned long WIFI_RETRY_INTERVAL_MS = 5000;
const unsigned long CONFIG_PORTAL_FALLBACK_MS = 15000;

// ============================================================
// Configuration access point
// ============================================================

const char* CONFIG_AP_SSID = "SmartParking_Config_Exit";
const char* CONFIG_AP_PASSWORD = "12345678";  // Minimum 8 characters.

// ============================================================
// ESP32-CAM AI Thinker camera pins
// ============================================================

#define PWDN_GPIO_NUM 32
#define RESET_GPIO_NUM -1
#define XCLK_GPIO_NUM 0
#define SIOD_GPIO_NUM 26
#define SIOC_GPIO_NUM 27

#define Y9_GPIO_NUM 35
#define Y8_GPIO_NUM 34
#define Y7_GPIO_NUM 39
#define Y6_GPIO_NUM 36
#define Y5_GPIO_NUM 21
#define Y4_GPIO_NUM 19
#define Y3_GPIO_NUM 18
#define Y2_GPIO_NUM 5

#define VSYNC_GPIO_NUM 25
#define HREF_GPIO_NUM 23
#define PCLK_GPIO_NUM 22

// ============================================================
// Runtime state
// ============================================================

Preferences preferences;
WebServer configServer(80);

String wifiSsid = "";
String wifiPassword = "";
String serverBaseUrl = "";
String cameraModule = "ENTRY";

bool cameraReady = false;
bool configPortalActive = false;
bool webServerStarted = false;
bool mdnsStarted = false;

unsigned long wifiDisconnectedSinceMs = 0;
unsigned long lastWifiRetryMs = 0;

// ============================================================
// Forward declarations
// ============================================================

bool initCamera();
void loadConfiguration();
bool saveConfiguration(
  const String& ssid,
  const String& password,
  const String& server,
  const String& module);
void clearConfiguration();

bool hasValidConfiguration();
String normalizeServerBaseUrl(String value);
String normalizeModule(String value);
String buildDetectUrl();
String deviceHostname();

bool connectWiFi(unsigned long timeoutMs);
void maintainWiFiConnection();
void startConfigurationPortal();
void stopConfigurationPortal();
void startWebServer();
void startMdns();

void registerConfigurationRoutes();
String buildConfigurationPage(const String& message = "");
String htmlEscape(const String& value);
String jsonEscape(const String& value);

void handleSlaveCommands();
String handleCaptureCommand();
String sendImageToServer(camera_fb_t* frame);

bool restartRequested = false;
bool clearConfigBeforeRestart = false;
unsigned long restartRequestedAt = 0;
bool wifiStationStarted = false;

void runAutoYoloDebug();

// ============================================================
// Setup
// ============================================================

void setup() {
  /*
   * Khi debug bằng Serial Monitor:
   * - Dùng 115200 baud.
   * - Ngắt UART giữa ESP32-CAM và Slave.
   *
   * Khi chạy chính thức với Slave:
   * - Đổi về cùng baud với Slave, ví dụ 9600.
   * - Tắt YOLO_HTTP_DEBUG. = 0
   */
  Serial.begin(115200);
  Serial.setTimeout(100);
  delay(1000);

#if YOLO_HTTP_DEBUG
  Serial.println("[BOOT] Setup started");
#endif

  loadConfiguration();

#if YOLO_HTTP_DEBUG
  Serial.println("[BOOT] Configuration loaded");
  Serial.print("[BOOT] Module: ");
  Serial.println(cameraModule);
  Serial.print("[BOOT] Server: ");
  Serial.println(serverBaseUrl);
#endif

#if USE_MOCK_SERVER

  cameraReady = true;
  webServerStarted = false;

#else

  cameraReady = initCamera();

#if YOLO_HTTP_DEBUG
  Serial.println(
    cameraReady
      ? "[BOOT] Camera initialized"
      : "[BOOT] Camera initialization failed"
  );
#endif

  registerConfigurationRoutes();

  if (
    hasValidConfiguration() &&
    connectWiFi(STARTUP_WIFI_TIMEOUT_MS)
  ) {
    stopConfigurationPortal();
    startWebServer();
    startMdns();

#if YOLO_HTTP_DEBUG
    Serial.print("[BOOT] Wi-Fi connected. IP: ");
    Serial.println(WiFi.localIP());
#endif

#if AUTO_YOLO_DEBUG_AFTER_SETUP
    delay(AUTO_YOLO_DEBUG_DELAY_MS);
    runAutoYoloDebug();
#endif

  } else {
    startConfigurationPortal();

#if YOLO_HTTP_DEBUG
    Serial.println("[BOOT] Configuration portal started.");
    Serial.println("[AUTO-YOLO] Upload skipped because Wi-Fi is unavailable.");
#endif
  }

#endif
}

// ============================================================
// Main loop
// ============================================================

void loop() {
  // The configuration web server is available in AP mode and normal STA mode.
  if (webServerStarted) {
    configServer.handleClient();
  }

#if !USE_MOCK_SERVER
  maintainWiFiConnection();
#endif

  // UART remains active in every mode.
  // In configuration mode, CAPTURE safely returns CLOSE.
  handleSlaveCommands();

  if (restartRequested && millis() - restartRequestedAt >= 1500) {
    restartRequested = false;

    if (clearConfigBeforeRestart) {
      clearConfiguration();
    }

    delay(50);
    ESP.restart();
  }

  delay(10);
}

// ============================================================
// Camera
// ============================================================

bool initCamera() {
  camera_config_t config = {};

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

  config.xclk_freq_hz = 10000000;
  config.pixel_format = PIXFORMAT_JPEG;

  // Cân bằng giữa độ rõ, kích thước ảnh và độ ổn định.
  config.frame_size = FRAMESIZE_CIF;  // 400 × 296
  config.jpeg_quality = 16;
  config.fb_count = 1;
  config.grab_mode = CAMERA_GRAB_WHEN_EMPTY;

  if (psramFound()) {
    config.fb_location = CAMERA_FB_IN_PSRAM;
  } else {
    config.fb_location = CAMERA_FB_IN_DRAM;
  }

  return esp_camera_init(&config) == ESP_OK;
}

// ============================================================
// Preferences / NVS
// ============================================================

void loadConfiguration() {
  preferences.begin("smartparking", true);

  wifiSsid = preferences.getString("ssid", "");
  wifiPassword = preferences.getString("password", "");
  serverBaseUrl = preferences.getString("server", "");
  cameraModule = preferences.getString("module", "ENTRY");

  preferences.end();

  wifiSsid.trim();
  serverBaseUrl = normalizeServerBaseUrl(serverBaseUrl);
  cameraModule = normalizeModule(cameraModule);
}

bool saveConfiguration(
  const String& ssid,
  const String& password,
  const String& server,
  const String& module) {
  String cleanSsid = ssid;
  String cleanServer = normalizeServerBaseUrl(server);
  String cleanModule = normalizeModule(module);

  cleanSsid.trim();

  if (cleanSsid.length() == 0) {
    return false;
  }

  // Current project server is local HTTP, not HTTPS.
  if (!cleanServer.startsWith("http://")) {
    return false;
  }

  if (cleanModule != "ENTRY" && cleanModule != "EXIT") {
    return false;
  }

  preferences.begin("smartparking", false);

  size_t written = 0;
  written += preferences.putString("ssid", cleanSsid);
  written += preferences.putString("password", password);
  written += preferences.putString("server", cleanServer);
  written += preferences.putString("module", cleanModule);

  preferences.end();

  return written > 0;
}

void clearConfiguration() {
  preferences.begin("smartparking", false);
  preferences.clear();
  preferences.end();
}

bool hasValidConfiguration() {
  if (wifiSsid.length() == 0) {
    return false;
  }

  if (!serverBaseUrl.startsWith("http://")) {
    return false;
  }

  if (cameraModule != "ENTRY" && cameraModule != "EXIT") {
    return false;
  }

  return true;
}

String normalizeServerBaseUrl(String value) {
  value.trim();

  int queryIndex = value.indexOf('?');
  if (queryIndex >= 0) {
    value = value.substring(0, queryIndex);
  }

  while (value.endsWith("/")) {
    value.remove(value.length() - 1);
  }

  // Accept a pasted full endpoint and convert it back to the base URL.
  if (value.endsWith("/detect")) {
    value.remove(value.length() - 7);

    while (value.endsWith("/")) {
      value.remove(value.length() - 1);
    }
  }

  return value;
}

String normalizeModule(String value) {
  value.trim();
  value.toUpperCase();

  return value == "EXIT" ? "EXIT" : "ENTRY";
}

String buildDetectUrl() {
  return serverBaseUrl + "/detect?module=" + cameraModule;
}

String deviceHostname() {
  return cameraModule == "EXIT"
           ? "smartparking-exit"
           : "smartparking-entry";
}

// ============================================================
// Wi-Fi
// ============================================================

WiFi.onEvent([](
  WiFiEvent_t event,
  WiFiEventInfo_t info
) {
  if (
    event ==
    ARDUINO_EVENT_WIFI_STA_DISCONNECTED
  ) {
    Serial.print(
      "[WIFI] Disconnected. Reason code: "
    );

    Serial.println(
      info.wifi_sta_disconnected.reason
    );
  }

  if (
    event ==
    ARDUINO_EVENT_WIFI_STA_GOT_IP
  ) {
    Serial.print("[WIFI] Got IP: ");
    Serial.println(WiFi.localIP());
  }
});

bool connectWiFi(unsigned long timeoutMs) {
  if (!hasValidConfiguration()) {
    Serial.println("[WIFI] Invalid configuration.");
    return false;
  }

  /*
   * Chỉ cấu hình và gọi WiFi.begin() một lần.
   * Những lần gọi connectWiFi() sau chỉ chờ kết quả,
   * không ghi lại cấu hình khi STA vẫn đang kết nối.
   */
  if (!wifiStationStarted) {
    String hostname = deviceHostname();

    // Reset Wi-Fi trước khi thiết lập hostname.
    WiFi.mode(WIFI_MODE_NULL);
    delay(100);

    // Phải đặt hostname trước khi khởi động Wi-Fi.
    WiFi.setHostname(hostname.c_str());

    /*
     * Dùng AP + STA ngay từ đầu.
     * Nếu STA không kết nối được, có thể mở portal mà
     * không cần đổi chế độ trong lúc STA đang connecting.
     */
    WiFi.mode(WIFI_AP_STA);

    WiFi.setSleep(false);
    WiFi.setAutoReconnect(true);

    Serial.print("[WIFI] Connecting to: ");
    Serial.println(wifiSsid);

    WiFi.begin(
      wifiSsid.c_str(),
      wifiPassword.c_str()
    );

    wifiStationStarted = true;
    lastWifiRetryMs = millis();
  }

  unsigned long startedMs = millis();

  while (
    WiFi.status() != WL_CONNECTED &&
    millis() - startedMs < timeoutMs
  ) {
    delay(250);
    Serial.print(".");
  }

  Serial.println();

  if (WiFi.status() == WL_CONNECTED) {
    wifiDisconnectedSinceMs = 0;

    Serial.println("[WIFI] Connected.");
    Serial.print("[WIFI] IP: ");
    Serial.println(WiFi.localIP());

    Serial.print("[WIFI] RSSI: ");
    Serial.println(WiFi.RSSI());

    return true;
  }

  Serial.print("[WIFI] Connection timeout. Status: ");
  Serial.println((int)WiFi.status());

  return false;
}

void maintainWiFiConnection() {
  if (!hasValidConfiguration()) {
    if (!configPortalActive) {
      startConfigurationPortal();
    }

    return;
  }

  if (WiFi.status() == WL_CONNECTED) {
    wifiDisconnectedSinceMs = 0;

    if (configPortalActive) {
      stopConfigurationPortal();
    }

    startMdns();
    return;
  }

  if (wifiDisconnectedSinceMs == 0) {
    wifiDisconnectedSinceMs = millis();
  }

  /*
   * Không gọi WiFi.begin() tại đây.
   * Driver đang tự xử lý kết nối/reconnect.
   *
   * Gọi WiFi.begin() liên tục trong lúc STA đang connecting
   * gây lỗi:
   * "wifi:sta is connecting, cannot set config"
   */

  if (
    !configPortalActive &&
    millis() - wifiDisconnectedSinceMs >=
      CONFIG_PORTAL_FALLBACK_MS
  ) {
    startConfigurationPortal();
  }
}

// ============================================================
// Configuration portal
// ============================================================

void registerConfigurationRoutes() {
  configServer.on("/", HTTP_GET, []() {
    configServer.send(
      200,
      "text/html; charset=utf-8",
      buildConfigurationPage());
  });

  configServer.on("/save", HTTP_POST, []() {
    String newSsid = configServer.arg("ssid");
    String newPassword = configServer.arg("password");
    String newServer = configServer.arg("server");
    String newModule = configServer.arg("module");

    newSsid.trim();
    newServer.trim();
    newModule.trim();
    newModule.toUpperCase();

    // Blank password means keep the existing saved password.
    if (newPassword.length() == 0) {
      newPassword = wifiPassword;
    }

    if (
      newSsid.length() == 0 || !normalizeServerBaseUrl(newServer).startsWith("http://") || (newModule != "ENTRY" && newModule != "EXIT")) {
      configServer.send(
        400,
        "text/html; charset=utf-8",
        buildConfigurationPage(
          "Invalid configuration. Check SSID, HTTP server URL, and module."));
      return;
    }

    if (!saveConfiguration(newSsid, newPassword, newServer, newModule)) {
      configServer.send(
        500,
        "text/html; charset=utf-8",
        buildConfigurationPage("Unable to save configuration."));
      return;
    }

    configServer.send(
      200,
      "text/html; charset=utf-8",
      "<!doctype html><html><body>"
      "<h2>Configuration saved</h2>"
      "<p>ESP32-CAM is restarting and will use the new settings.</p>"
      "</body></html>");

    clearConfigBeforeRestart = false;
    restartRequested = true;
    restartRequestedAt = millis();
  });

  configServer.on("/status", HTTP_GET, []() {
    String status = "{";
    status += "\"camera_ready\":";
    status += cameraReady ? "true" : "false";
    status += ",\"wifi_connected\":";
    status += WiFi.status() == WL_CONNECTED ? "true" : "false";
    status += ",\"config_portal_active\":";
    status += configPortalActive ? "true" : "false";
    status += ",\"ssid\":\"" + jsonEscape(wifiSsid) + "\"";
    status += ",\"server\":\"" + jsonEscape(serverBaseUrl) + "\"";
    status += ",\"module\":\"" + jsonEscape(cameraModule) + "\"";
    status += ",\"detect_url\":\"" + jsonEscape(buildDetectUrl()) + "\"";
    status += ",\"station_ip\":\"" + WiFi.localIP().toString() + "\"";
    status += ",\"access_point_ip\":\"" + WiFi.softAPIP().toString() + "\"";
    status += "}";

    configServer.send(200, "application/json", status);
  });

  configServer.on("/reset", HTTP_POST, []() {
    clearConfiguration();

    configServer.send(
      200,
      "text/html; charset=utf-8",
      "<!doctype html><html><body>"
      "<h2>Configuration cleared</h2>"
      "<p>ESP32-CAM is restarting in configuration mode.</p>"
      "</body></html>");

    clearConfigBeforeRestart = true;
    restartRequested = true;
    restartRequestedAt = millis();
  });

  configServer.onNotFound([]() {
    configServer.sendHeader("Location", "/");
    configServer.send(302, "text/plain", "");
  });
}

void startWebServer() {
  if (!webServerStarted) {
    configServer.begin();
    webServerStarted = true;
  }
}

void startConfigurationPortal() {
  if (configPortalActive) {
    return;
  }

  configPortalActive = true;
  mdnsStarted = false;

  /*
   * Nếu chưa từng bắt đầu STA vì cấu hình không hợp lệ,
   * cần bật AP + STA tại đây.
   *
   * Nếu STA đã bắt đầu thì không gọi WiFi.mode() lại trong
   * lúc nó đang kết nối.
   */
  if (!wifiStationStarted) {
    WiFi.mode(WIFI_AP_STA);
  }

  bool apStarted = WiFi.softAP(
    CONFIG_AP_SSID,
    CONFIG_AP_PASSWORD
  );

  if (apStarted) {
    Serial.println("[WIFI] Configuration portal started.");

    Serial.print("[WIFI] Portal SSID: ");
    Serial.println(CONFIG_AP_SSID);

    Serial.print("[WIFI] Portal IP: ");
    Serial.println(WiFi.softAPIP());
  } else {
    Serial.println(
      "[WIFI] Failed to start configuration portal."
    );
  }

  startWebServer();
}

void stopConfigurationPortal() {
  if (!configPortalActive) {
    return;
  }

  /*
   * false = chỉ tắt SoftAP.
   * true có thể tắt toàn bộ Wi-Fi radio, bao gồm STA.
   */
  WiFi.softAPdisconnect(false);

  configPortalActive = false;

  Serial.println(
    "[WIFI] Configuration portal stopped."
  );
}

void startMdns() {
  if (mdnsStarted || WiFi.status() != WL_CONNECTED) {
    return;
  }

  String hostname = deviceHostname();

  if (MDNS.begin(hostname.c_str())) {
    MDNS.addService("http", "tcp", 80);
    mdnsStarted = true;
  }
}

String buildConfigurationPage(const String& message) {
  String stationStatus = WiFi.status() == WL_CONNECTED
                           ? "Connected"
                           : "Disconnected";

  String page = R"HTML(
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width,initial-scale=1">
  <title>Smart Parking ESP32-CAM</title>
  <style>
    body { font-family: Arial, sans-serif; margin: 0; background: #f3f4f6; }
    main { max-width: 620px; margin: 32px auto; background: white; padding: 24px;
           border-radius: 12px; box-shadow: 0 4px 18px rgba(0,0,0,.10); }
    h1 { margin-top: 0; }
    label { display: block; margin-top: 16px; font-weight: bold; }
    input, select { width: 100%; box-sizing: border-box; padding: 10px;
                    margin-top: 6px; border: 1px solid #bbb; border-radius: 6px; }
    button { margin-top: 20px; padding: 11px 16px; border: 0; border-radius: 6px;
             cursor: pointer; }
    .primary { background: #111827; color: white; }
    .danger { background: #b91c1c; color: white; }
    .status { background: #eef2ff; padding: 12px; border-radius: 8px; }
    .message { background: #fff7ed; padding: 12px; border-radius: 8px; }
    code { word-break: break-all; }
  </style>
</head>
<body>
<main>
  <h1>Smart Parking ESP32-CAM</h1>
)HTML";

  if (message.length() > 0) {
    page += "<div class='message'>" + htmlEscape(message) + "</div>";
  }

  page += "<div class='status'>";
  page += "<div><strong>Wi-Fi:</strong> " + stationStatus + "</div>";
  page += "<div><strong>Camera:</strong> ";
  page += cameraReady ? "Ready" : "Not ready";
  page += "</div>";
  page += "<div><strong>Role:</strong> " + htmlEscape(cameraModule) + "</div>";
  page += "<div><strong>Detect URL:</strong> <code>";
  page += htmlEscape(buildDetectUrl());
  page += "</code></div>";

  if (WiFi.status() == WL_CONNECTED) {
    page += "<div><strong>Station IP:</strong> ";
    page += WiFi.localIP().toString();
    page += "</div>";
    page += "<div><strong>Local name:</strong> http://";
    page += htmlEscape(deviceHostname());
    page += ".local</div>";
  }

  if (configPortalActive) {
    page += "<div><strong>Configuration AP:</strong> ";
    page += CONFIG_AP_SSID;
    page += " / 192.168.4.1</div>";
  }

  page += "</div>";

  page += "<form method='POST' action='/save'>";
  page += "<label>Wi-Fi SSID</label>";
  page += "<input name='ssid' required value='" + htmlEscape(wifiSsid) + "'>";

  page += "<label>Wi-Fi password</label>";
  page += "<input name='password' type='password' ";
  page += "placeholder='Leave blank to keep the saved password'>";

  page += "<label>YOLO server base URL</label>";
  page += "<input name='server' required value='" + htmlEscape(serverBaseUrl) + "' ";
  page += "placeholder='http://192.168.1.10:8000'>";

  page += "<label>Camera module</label>";
  page += "<select name='module'>";
  page += cameraModule == "ENTRY"
            ? "<option selected>ENTRY</option><option>EXIT</option>"
            : "<option>ENTRY</option><option selected>EXIT</option>";
  page += "</select>";

  page += "<button class='primary' type='submit'>Save and restart</button>";
  page += "</form>";

  page += "<form method='POST' action='/reset'>";
  page += "<button class='danger' type='submit'>Clear saved configuration</button>";
  page += "</form>";

  page += R"HTML(
</main>
</body>
</html>
)HTML";

  return page;
}

String htmlEscape(const String& value) {
  String escaped = value;
  escaped.replace("&", "&amp;");
  escaped.replace("<", "&lt;");
  escaped.replace(">", "&gt;");
  escaped.replace("\"", "&quot;");
  escaped.replace("'", "&#39;");
  return escaped;
}

String jsonEscape(const String& value) {
  String escaped = value;
  escaped.replace("\\", "\\\\");
  escaped.replace("\"", "\\\"");
  escaped.replace("\n", "\\n");
  escaped.replace("\r", "\\r");
  return escaped;
}

// ============================================================
// UART protocol
// ============================================================

void handleSlaveCommands() {
  if (!Serial.available()) {
    return;
  }

  String command = Serial.readStringUntil('\n');
  command.trim();
  command.toUpperCase();

  if (command == "CAPTURE") {
    String result = handleCaptureCommand();
    result.trim();
    result.toUpperCase();

    // Only exact OPEN is accepted. Everything else fails safe to CLOSE.
    Serial.println(result == "OPEN" ? "OPEN" : "CLOSE");
  }
}

String handleCaptureCommand() {
#if USE_MOCK_SERVER

  delay(300);
  return "OPEN";

#else

  if (configPortalActive || !cameraReady || !hasValidConfiguration()) {
    return "CLOSE";
  }

  if (WiFi.status() != WL_CONNECTED && !connectWiFi(CAPTURE_WIFI_TIMEOUT_MS)) {
    return "CLOSE";
  }

  // Discard buffered frame.
  camera_fb_t* oldFrame = esp_camera_fb_get();

  if (oldFrame != nullptr) {
    esp_camera_fb_return(oldFrame);
  }

  // Capture a newer frame for YOLO.
  camera_fb_t* frame = esp_camera_fb_get();

  if (frame == nullptr) {
    return "CLOSE";
  }

  String result = sendImageToServer(frame);

  esp_camera_fb_return(frame);

  result.trim();
  result.toUpperCase();

  return result == "OPEN" ? "OPEN" : "CLOSE";

#endif
}

// ============================================================
// YOLO/FastAPI communication
// ============================================================

String sendImageToServer(camera_fb_t* frame) {
  if (frame == nullptr) {
#if YOLO_HTTP_DEBUG
    Serial.println("[YOLO-HTTP] ERROR: Frame is null.");
#endif
    return "CLOSE";
  }

  if (WiFi.status() != WL_CONNECTED) {
#if YOLO_HTTP_DEBUG
    Serial.println("[YOLO-HTTP] ERROR: Wi-Fi is disconnected.");
#endif
    return "CLOSE";
  }

  WiFiClient client;
  HTTPClient http;

  String detectUrl = buildDetectUrl();

#if YOLO_HTTP_DEBUG
  Serial.print("[YOLO-HTTP] URL: ");
  Serial.println(detectUrl);

  Serial.print("[YOLO-HTTP] Module: ");
  Serial.println(cameraModule);

  Serial.print("[YOLO-HTTP] JPEG bytes: ");
  Serial.println(frame->len);
#endif

  if (!http.begin(client, detectUrl)) {
#if YOLO_HTTP_DEBUG
    Serial.println("[YOLO-HTTP] ERROR: http.begin() failed.");
#endif
    return "CLOSE";
  }

  http.setTimeout(HTTP_TIMEOUT_MS);

  http.addHeader("Content-Type", "image/jpeg");
  http.addHeader("X-Module-ID", cameraModule);

  int httpCode = http.POST(frame->buf, frame->len);

#if YOLO_HTTP_DEBUG
  Serial.print("[YOLO-HTTP] HTTP code: ");
  Serial.println(httpCode);
#endif

  String payload = "CLOSE";

  if (httpCode == HTTP_CODE_OK) {
    payload = http.getString();
    payload.trim();
    payload.toUpperCase();

#if YOLO_HTTP_DEBUG
    Serial.print("[YOLO-HTTP] Server response: ");
    Serial.println(payload);
#endif

    if (payload != "OPEN") {
      payload = "CLOSE";
    }

  } else {
#if YOLO_HTTP_DEBUG
    Serial.print("[YOLO-HTTP] Request failed: ");
    Serial.println(http.errorToString(httpCode));
#endif
  }

  http.end();

  return payload;
}

void runAutoYoloDebug() {
#if USE_MOCK_SERVER

#if YOLO_HTTP_DEBUG
  Serial.println("[AUTO-YOLO] Mock mode is enabled.");
  Serial.println("[AUTO-YOLO] Real image upload was skipped.");
#endif

#else

#if YOLO_HTTP_DEBUG
  Serial.println();
  Serial.println("========================================");
  Serial.println("[AUTO-YOLO] Starting automatic YOLO test");
  Serial.println("========================================");
#endif

  if (!cameraReady) {
#if YOLO_HTTP_DEBUG
    Serial.println("[AUTO-YOLO] ERROR: Camera is not ready.");
#endif
    return;
  }

  if (!hasValidConfiguration()) {
#if YOLO_HTTP_DEBUG
    Serial.println("[AUTO-YOLO] ERROR: Configuration is invalid.");
#endif
    return;
  }

  if (WiFi.status() != WL_CONNECTED) {
#if YOLO_HTTP_DEBUG
    Serial.println("[AUTO-YOLO] ERROR: Wi-Fi is not connected.");
#endif
    return;
  }

#if YOLO_HTTP_DEBUG
  Serial.print("[AUTO-YOLO] ESP32 IP: ");
  Serial.println(WiFi.localIP());

  Serial.print("[AUTO-YOLO] Detect URL: ");
  Serial.println(buildDetectUrl());

  Serial.println("[AUTO-YOLO] Discarding buffered frame...");
#endif

  /*
   * Với CAMERA_GRAB_WHEN_EMPTY và fb_count = 1,
   * buffer có thể đang chứa một frame cũ.
   * Lấy và trả frame đầu tiên để frame tiếp theo mới hơn.
   */
  camera_fb_t* oldFrame = esp_camera_fb_get();

  if (oldFrame != nullptr) {
    esp_camera_fb_return(oldFrame);
  }

  delay(100);

#if YOLO_HTTP_DEBUG
  Serial.println("[AUTO-YOLO] Capturing new frame...");
#endif

  camera_fb_t* frame = esp_camera_fb_get();

  if (frame == nullptr) {
#if YOLO_HTTP_DEBUG
    Serial.println("[AUTO-YOLO] ERROR: Unable to capture frame.");
#endif
    return;
  }

#if YOLO_HTTP_DEBUG
  Serial.print("[AUTO-YOLO] JPEG size: ");
  Serial.print(frame->len);
  Serial.println(" bytes");

  Serial.println("[AUTO-YOLO] Uploading image...");
#endif

  String result = sendImageToServer(frame);

  esp_camera_fb_return(frame);

  result.trim();
  result.toUpperCase();

#if YOLO_HTTP_DEBUG
  Serial.print("[AUTO-YOLO] Final result: ");
  Serial.println(result);

  if (result == "OPEN") {
    Serial.println("[AUTO-YOLO] SUCCESS: Vehicle accepted.");
  } else {
    Serial.println(
      "[AUTO-YOLO] Result is CLOSE. "
      "Connection may still be working, but YOLO did not accept the image."
    );
  }

  Serial.println("========================================");
  Serial.println();
#endif

#endif
}
