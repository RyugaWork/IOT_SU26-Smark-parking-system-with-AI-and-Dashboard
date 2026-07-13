/*
  ESP32_CAM_FromScratch_v26.0712.ino
  Smart Parking System - AI Thinker ESP32-CAM gateway

  Production data path:
    Slave Arduino --UART--> ESP32-CAM --HTTP JPEG--> YOLO server
    Slave sends:  CAPTURE\n
    ESP32 returns: OPEN\n or CLOSE\n

  IMPORTANT UART wiring (UART0):
    ESP32-CAM GPIO1 / U0TXD -> Slave Arduino D3 / SoftwareSerial RX
    ESP32-CAM GPIO3 / U0RXD <- Slave Arduino D4 / SoftwareSerial TX
                                  through the resistor protection network
    ESP32-CAM GND           <-> Slave Arduino GND

  Production rule:
    GPIO1/GPIO3 must carry only CAPTURE / OPEN / CLOSE protocol traffic.
    Disconnect the Slave UART while uploading or using verbose debug output.

  Target board: AI Thinker ESP32-CAM
*/

#include "esp_camera.h"
#include "esp_log.h"
#include <WiFi.h>
#include <HTTPClient.h>
#include <WebServer.h>
#include <Preferences.h>
#include <ESPmDNS.h>

// ============================================================
// 1. Build modes
// ============================================================

// 1 = UART test only: CAPTURE always returns OPEN.
// 0 = Real camera + Wi-Fi + YOLO server.
#define MOCK_UART_MODE              0
// 1 = tự động chụp và gửi một ảnh lên YOLO sau khi setup.
// 0 = tắt tính năng debug tự động.
#define AUTO_YOLO_DEBUG_AFTER_BOOT  1
// In thông tin HTTP qua Serial.
// Chỉ bật khi ESP32-CAM đang được test riêng, chưa nối UART với Slave.
#define VERBOSE_SERIAL_DEBUG        0

#if VERBOSE_SERIAL_DEBUG
  #define DEBUG_PRINT(x)       Serial.print(x)
  #define DEBUG_PRINTLN(x)     Serial.println(x)
  #define DEBUG_PRINTF(...)    Serial.printf(__VA_ARGS__)
#else
  #define DEBUG_PRINT(x)       do { } while (0)
  #define DEBUG_PRINTLN(x)     do { } while (0)
  #define DEBUG_PRINTF(...)    do { } while (0)
#endif

// ============================================================
// 2. Protocol, timing, and configuration constants
// ============================================================

static const uint32_t PRODUCTION_UART_BAUD = 9600;
static const uint32_t DEBUG_UART_BAUD = 115200;

static const uint32_t STARTUP_WIFI_TIMEOUT_MS = 20000UL;
static const uint32_t WIFI_RECONNECT_INTERVAL_MS = 10000UL;
static const uint32_t WIFI_PORTAL_FALLBACK_MS = 30000UL;
static const uint32_t HTTP_TIMEOUT_MS = 3500UL;
static const uint32_t DEFERRED_RESTART_DELAY_MS = 1500UL;
static const uint32_t AUTO_DEBUG_DELAY_MS = 3000UL;
static const uint32_t PORTAL_CLOSE_GRACE_MS = 5000UL;

static const size_t UART_COMMAND_MAX_LENGTH = 32;

static const char *NVS_NAMESPACE = "smartparking";
static const char *NVS_KEY_SSID = "ssid";
static const char *NVS_KEY_PASSWORD = "password";
static const char *NVS_KEY_SERVER = "server";
static const char *NVS_KEY_MODULE = "module";

static const char *CONFIG_AP_PASSWORD = "12345678"; // Minimum 8 characters.

// ============================================================
// 3. AI Thinker ESP32-CAM camera pins
// ============================================================

#define PWDN_GPIO_NUM   32
#define RESET_GPIO_NUM  -1
#define XCLK_GPIO_NUM    0
#define SIOD_GPIO_NUM   26
#define SIOC_GPIO_NUM   27

#define Y9_GPIO_NUM     35
#define Y8_GPIO_NUM     34
#define Y7_GPIO_NUM     39
#define Y6_GPIO_NUM     36
#define Y5_GPIO_NUM     21
#define Y4_GPIO_NUM     19
#define Y3_GPIO_NUM     18
#define Y2_GPIO_NUM      5

#define VSYNC_GPIO_NUM  25
#define HREF_GPIO_NUM   23
#define PCLK_GPIO_NUM   22

// UART0 pins are fixed by the AI Thinker board design:
// GPIO1 = U0TXD, GPIO3 = U0RXD.
static const int ESP32_UART_TX_PIN = 1;
static const int ESP32_UART_RX_PIN = 3;

// ============================================================
// 4. Runtime states
// ============================================================

enum WifiRuntimeState : uint8_t {
  WIFI_NOT_STARTED,
  WIFI_CONNECTING,
  WIFI_CONNECTED,
  WIFI_DISCONNECTED,
  WIFI_PORTAL_ACTIVE
};

enum DeviceState : uint8_t {
  STATE_BOOTING,
  STATE_CONFIG_PORTAL,
  STATE_CONNECTING_WIFI,
  STATE_READY,
  STATE_CAPTURING,
  STATE_UPLOADING,
  STATE_RETURNING_RESULT,
  STATE_ERROR
};

Preferences preferences;
WebServer configServer(80);

String configuredSsid;
String configuredPassword;
String serverBaseUrl;
String cameraModule;
String uartCommandBuffer;

WifiRuntimeState wifiState = WIFI_NOT_STARTED;
DeviceState deviceState = STATE_BOOTING;

bool cameraReady = false;
bool portalActive = false;
bool webServerStarted = false;
bool mdnsStarted = false;
bool captureBusy = false;

bool restartRequested = false;
bool clearConfigBeforeRestart = false;
uint32_t restartRequestedAt = 0;

uint32_t lastReconnectAttemptMs = 0;
uint32_t disconnectedSinceMs = 0;
uint32_t portalCloseRequestedAt = 0;
uint8_t lastDisconnectReason = 0;

// Wi-Fi callbacks run on a separate FreeRTOS task. The callback only records
// compact event flags under a critical section. setup()/loop() performs all
// state changes, logging, WebServer, and Wi-Fi API calls.
portMUX_TYPE wifiEventMux = portMUX_INITIALIZER_UNLOCKED;
volatile bool pendingWifiGotIp = false;
volatile bool pendingWifiDisconnected = false;
volatile uint8_t pendingWifiDisconnectReason = 0;

bool oneShotDebugDone = false;
uint32_t oneShotDebugArmedAt = 0;

// ============================================================
// 5. Utility helpers
// ============================================================

const char *deviceStateName(DeviceState state) {
  switch (state) {
    case STATE_BOOTING:          return "BOOTING";
    case STATE_CONFIG_PORTAL:    return "CONFIG_PORTAL";
    case STATE_CONNECTING_WIFI:  return "CONNECTING_WIFI";
    case STATE_READY:            return "READY";
    case STATE_CAPTURING:        return "CAPTURING";
    case STATE_UPLOADING:        return "UPLOADING";
    case STATE_RETURNING_RESULT: return "RETURNING_RESULT";
    case STATE_ERROR:            return "ERROR";
    default:                     return "UNKNOWN";
  }
}

const char *wifiStateName(WifiRuntimeState state) {
  switch (state) {
    case WIFI_NOT_STARTED:  return "NOT_STARTED";
    case WIFI_CONNECTING:   return "CONNECTING";
    case WIFI_CONNECTED:    return "CONNECTED";
    case WIFI_DISCONNECTED: return "DISCONNECTED";
    case WIFI_PORTAL_ACTIVE:return "PORTAL_ACTIVE";
    default:                return "UNKNOWN";
  }
}

String boolJson(bool value) {
  return value ? "true" : "false";
}

String htmlEscape(const String &value) {
  String output;
  output.reserve(value.length() + 16);

  for (size_t i = 0; i < value.length(); ++i) {
    const char c = value.charAt(i);
    switch (c) {
      case '&': output += F("&amp;");  break;
      case '<': output += F("&lt;");   break;
      case '>': output += F("&gt;");   break;
      case '"': output += F("&quot;"); break;
      case '\'': output += F("&#39;"); break;
      default: output += c; break;
    }
  }
  return output;
}

String jsonEscape(const String &value) {
  String output;
  output.reserve(value.length() + 16);

  for (size_t i = 0; i < value.length(); ++i) {
    const char c = value.charAt(i);
    switch (c) {
      case '\\': output += F("\\\\"); break;
      case '"':  output += F("\\\""); break;
      case '\n': output += F("\\n");  break;
      case '\r': output += F("\\r");  break;
      case '\t': output += F("\\t");  break;
      default:
        if (static_cast<uint8_t>(c) >= 0x20) {
          output += c;
        }
        break;
    }
  }
  return output;
}

String normalizeModule(String value) {
  value.trim();
  value.toUpperCase();
  if (value == "ENTRY" || value == "EXIT") {
    return value;
  }
  return "";
}

String normalizeServerBaseUrl(String value) {
  value.trim();

  while (value.endsWith("/")) {
    value.remove(value.length() - 1);
  }

  String lowerValue = value;
  lowerValue.toLowerCase();
  if (lowerValue.endsWith("/detect")) {
    value.remove(value.length() - 7);
  }

  while (value.endsWith("/")) {
    value.remove(value.length() - 1);
  }

  return value;
}

String safeModuleName() {
  const String normalized = normalizeModule(cameraModule);
  return normalized.length() > 0 ? normalized : String("ENTRY");
}

String buildHostname() {
  String hostname = "smartparking-" + safeModuleName();
  hostname.toLowerCase();
  return hostname;
}

bool hasValidConfiguration() {
  if (configuredSsid.length() == 0) {
    return false;
  }

  if (!serverBaseUrl.startsWith("http://")) {
    return false;
  }

  const String normalizedModule = normalizeModule(cameraModule);
  return normalizedModule == "ENTRY" || normalizedModule == "EXIT";
}

// ============================================================
// 6. Preferences / NVS
// ============================================================

void loadConfiguration() {
  configuredSsid = "";
  configuredPassword = "";
  serverBaseUrl = "";
  cameraModule = "";

  if (!preferences.begin(NVS_NAMESPACE, true)) {
    DEBUG_PRINTLN(F("[NVS] Unable to open namespace for reading."));
    return;
  }

  configuredSsid = preferences.getString(NVS_KEY_SSID, "");
  configuredPassword = preferences.getString(NVS_KEY_PASSWORD, "");
  serverBaseUrl = normalizeServerBaseUrl(
    preferences.getString(NVS_KEY_SERVER, "")
  );
  cameraModule = normalizeModule(
    preferences.getString(NVS_KEY_MODULE, "")
  );

  preferences.end();

  DEBUG_PRINTF(
    "[NVS] ssid=%s server=%s module=%s valid=%d\n",
    configuredSsid.c_str(),
    serverBaseUrl.c_str(),
    cameraModule.c_str(),
    hasValidConfiguration()
  );
}

bool saveConfiguration(
  const String &ssid,
  const String &password,
  const String &server,
  const String &module
) {
  if (!preferences.begin(NVS_NAMESPACE, false)) {
    return false;
  }

  const size_t ssidWritten = preferences.putString(NVS_KEY_SSID, ssid);
  preferences.putString(NVS_KEY_PASSWORD, password);
  const size_t serverWritten = preferences.putString(NVS_KEY_SERVER, server);
  const size_t moduleWritten = preferences.putString(NVS_KEY_MODULE, module);
  preferences.end();

  return ssidWritten > 0 && serverWritten > 0 && moduleWritten > 0;
}

void clearConfiguration() {
  if (!preferences.begin(NVS_NAMESPACE, false)) {
    return;
  }

  preferences.clear();
  preferences.end();
}

// ============================================================
// 7. Camera
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
  config.frame_size = FRAMESIZE_CIF;
  config.jpeg_quality = 16;
  config.fb_count = 1;
  config.grab_mode = CAMERA_GRAB_WHEN_EMPTY;
  config.fb_location = psramFound()
    ? CAMERA_FB_IN_PSRAM
    : CAMERA_FB_IN_DRAM;

  const esp_err_t error = esp_camera_init(&config);
  if (error != ESP_OK) {
    DEBUG_PRINTF("[CAM] init failed: 0x%x\n", error);
    return false;
  }

  delay(200);
  DEBUG_PRINTF(
    "[CAM] ready. PSRAM=%d frame=CIF quality=16 xclk=10MHz\n",
    psramFound()
  );
  return true;
}

camera_fb_t *captureFreshFrame() {
  camera_fb_t *oldFrame = esp_camera_fb_get();
  if (oldFrame != nullptr) {
    esp_camera_fb_return(oldFrame);
  }

  delay(20);
  return esp_camera_fb_get();
}

// ============================================================
// 8. Wi-Fi lifecycle
// ============================================================

void registerWiFiEvents() {
  WiFi.onEvent([](arduino_event_id_t event, arduino_event_info_t info) {
    portENTER_CRITICAL(&wifiEventMux);

    if (event == ARDUINO_EVENT_WIFI_STA_GOT_IP) {
      pendingWifiGotIp = true;
    } else if (event == ARDUINO_EVENT_WIFI_STA_DISCONNECTED) {
      pendingWifiDisconnected = true;
      pendingWifiDisconnectReason = info.wifi_sta_disconnected.reason;
    }

    portEXIT_CRITICAL(&wifiEventMux);
  });
}

void processPendingWiFiEvents() {
  bool gotIp = false;
  bool disconnected = false;
  uint8_t disconnectReason = 0;

  portENTER_CRITICAL(&wifiEventMux);
  gotIp = pendingWifiGotIp;
  disconnected = pendingWifiDisconnected;
  disconnectReason = pendingWifiDisconnectReason;
  pendingWifiGotIp = false;
  pendingWifiDisconnected = false;
  portEXIT_CRITICAL(&wifiEventMux);

  if (disconnected) {
    wifiState = WIFI_DISCONNECTED;
    lastDisconnectReason = disconnectReason;
    if (disconnectedSinceMs == 0) {
      disconnectedSinceMs = millis();
    }
    DEBUG_PRINTF(
      "[WIFI] disconnected. reason=%u\n",
      static_cast<unsigned int>(lastDisconnectReason)
    );
  }

  if (gotIp) {
    wifiState = WIFI_CONNECTED;
    disconnectedSinceMs = 0;
    portalCloseRequestedAt = millis();
    DEBUG_PRINTF(
      "[WIFI] connected. IP=%s\n",
      WiFi.localIP().toString().c_str()
    );
  }
}

void startWebServer();
void startConfigurationPortal();
void startMdns();

bool startStationConnection() {
  if (!hasValidConfiguration()) {
    return false;
  }

  if (WiFi.status() == WL_CONNECTED || wifiState == WIFI_CONNECTING) {
    return true;
  }

  WiFi.mode(portalActive ? WIFI_AP_STA : WIFI_STA);

  const String hostname = buildHostname();
  WiFi.setAutoReconnect(false);

  wifiState = WIFI_CONNECTING;
  deviceState = STATE_CONNECTING_WIFI;
  lastReconnectAttemptMs = millis();

  DEBUG_PRINTF(
    "[WIFI] begin ssid=%s hostname=%s\n",
    configuredSsid.c_str(),
    hostname.c_str()
  );

  WiFi.begin(configuredSsid.c_str(), configuredPassword.c_str());
  startWebServer();
  return true;
}

void requestReconnectIfSafe() {
  if (!hasValidConfiguration()) {
    return;
  }

  if (WiFi.status() == WL_CONNECTED || wifiState == WIFI_CONNECTING) {
    return;
  }

  const uint32_t now = millis();
  if (now - lastReconnectAttemptMs < WIFI_RECONNECT_INTERVAL_MS) {
    return;
  }

  lastReconnectAttemptMs = now;
  wifiState = WIFI_CONNECTING;
  deviceState = STATE_CONNECTING_WIFI;

  DEBUG_PRINTLN(F("[WIFI] controlled reconnect request."));
  if (!WiFi.reconnect()) {
    wifiState = WIFI_DISCONNECTED;
  }
}

void startMdns() {
  if (mdnsStarted || WiFi.status() != WL_CONNECTED) {
    return;
  }

  const String hostname = buildHostname();
  if (MDNS.begin(hostname.c_str())) {
    MDNS.addService("http", "tcp", 80);
    mdnsStarted = true;
    DEBUG_PRINTF("[MDNS] http://%s.local/\n", hostname.c_str());
  } else {
    DEBUG_PRINTLN(F("[MDNS] failed to start."));
  }
}

void stopConfigurationPortal() {
  if (!portalActive) {
    return;
  }

  // false: stop only SoftAP; do not shut down the Wi-Fi interface.
  WiFi.softAPdisconnect(false);
  portalActive = false;
  portalCloseRequestedAt = 0;

  DEBUG_PRINTLN(F("[PORTAL] SoftAP stopped; Station remains active."));
}

void maintainWiFi() {
#if MOCK_UART_MODE
  return;
#else
  processPendingWiFiEvents();
  const uint32_t now = millis();

  if (WiFi.status() == WL_CONNECTED) {
    wifiState = WIFI_CONNECTED;
    startMdns();

    if (!captureBusy &&
        deviceState != STATE_CAPTURING &&
        deviceState != STATE_UPLOADING &&
        deviceState != STATE_RETURNING_RESULT) {
      deviceState = cameraReady ? STATE_READY : STATE_ERROR;
    }

    if (portalActive &&
        hasValidConfiguration() &&
        portalCloseRequestedAt != 0 &&
        now - portalCloseRequestedAt >= PORTAL_CLOSE_GRACE_MS) {
      stopConfigurationPortal();
    }
    return;
  }

  if (disconnectedSinceMs == 0) {
    disconnectedSinceMs = now;
  }

  requestReconnectIfSafe();

  if (!portalActive &&
      now - disconnectedSinceMs >= WIFI_PORTAL_FALLBACK_MS) {
    startConfigurationPortal();
  }
#endif
}

// ============================================================
// 9. Configuration portal and status endpoint
// ============================================================

String buildConfigurationPage(const String &message = "") {
  const String module = safeModuleName();
  const bool entrySelected = module == "ENTRY";
  const bool exitSelected = module == "EXIT";

  String page;
  page.reserve(5200);
  page += F("<!doctype html><html><head><meta charset='utf-8'>");
  page += F("<meta name='viewport' content='width=device-width,initial-scale=1'>");
  page += F("<title>Smart Parking ESP32-CAM</title>");
  page += F("<style>body{font-family:Arial,sans-serif;max-width:760px;margin:32px auto;padding:0 16px;background:#f4f6f8;color:#17202a}main{background:#fff;padding:24px;border-radius:12px;box-shadow:0 2px 12px #0002}label{display:block;margin-top:14px;font-weight:700}input,select,button{box-sizing:border-box;width:100%;padding:11px;margin-top:6px;border:1px solid #aab7b8;border-radius:6px}button{background:#1f618d;color:#fff;border:0;font-weight:700;cursor:pointer}.danger{background:#922b21}.note{background:#eaf2f8;padding:12px;border-radius:6px}.message{background:#fcf3cf;padding:12px;border-radius:6px;margin-bottom:14px}code{word-break:break-all}</style></head><body><main>");
  page += F("<h1>Smart Parking ESP32-CAM</h1>");
  page += F("<p class='note'>UART production protocol: <code>CAPTURE</code> in, then exactly <code>OPEN</code> or <code>CLOSE</code> out.</p>");

  if (message.length() > 0) {
    page += F("<div class='message'>");
    page += htmlEscape(message);
    page += F("</div>");
  }

  page += F("<form method='post' action='/save'>");
  page += F("<label>Wi-Fi SSID</label><input name='ssid' required value='");
  page += htmlEscape(configuredSsid);
  page += F("'>");

  page += F("<label>Wi-Fi password</label><input name='password' type='password' placeholder='Leave blank to keep the saved password'>");

  page += F("<label>YOLO server base URL</label><input name='server' required placeholder='http://192.168.1.10:8000' value='");
  page += htmlEscape(serverBaseUrl);
  page += F("'>");

  page += F("<label>Camera module</label><select name='module'>");
  page += String("<option value='ENTRY'") + (entrySelected ? " selected" : "") + ">ENTRY</option>";
  page += String("<option value='EXIT'") + (exitSelected ? " selected" : "") + ">EXIT</option>";
  page += F("</select>");

  page += F("<button type='submit'>Save and restart</button></form>");
  page += F("<p>Status JSON: <a href='/status'>/status</a></p>");
  page += F("<form method='post' action='/reset' onsubmit=\"return confirm('Clear configuration and restart?')\"><button class='danger' type='submit'>Clear configuration</button></form>");
  page += F("</main></body></html>");
  return page;
}

void registerConfigurationRoutes() {
  configServer.on("/", HTTP_GET, []() {
    configServer.send(200, "text/html; charset=utf-8", buildConfigurationPage());
  });

  configServer.on("/save", HTTP_POST, []() {
    String newSsid = configServer.arg("ssid");
    String newPassword = configServer.arg("password");
    String newServer = normalizeServerBaseUrl(configServer.arg("server"));
    String newModule = normalizeModule(configServer.arg("module"));

    newSsid.trim();

    if (newPassword.length() == 0 && configuredPassword.length() > 0) {
      newPassword = configuredPassword;
    }

    String lowerServer = newServer;
    lowerServer.toLowerCase();

    String validationError;
    if (newSsid.length() == 0) {
      validationError = "SSID must not be empty.";
    } else if (!newServer.startsWith("http://")) {
      validationError = "Server URL must start with http://.";
    } else if (lowerServer.indexOf("localhost") >= 0 ||
               lowerServer.indexOf("127.0.0.1") >= 0) {
      validationError = "Use the YOLO computer LAN IP, not localhost or 127.0.0.1.";
    } else if (newModule != "ENTRY" && newModule != "EXIT") {
      validationError = "Module must be ENTRY or EXIT.";
    }

    if (validationError.length() > 0) {
      configServer.send(
        400,
        "text/html; charset=utf-8",
        buildConfigurationPage(validationError)
      );
      return;
    }

    if (!saveConfiguration(newSsid, newPassword, newServer, newModule)) {
      configServer.send(
        500,
        "text/html; charset=utf-8",
        buildConfigurationPage("Unable to save configuration to NVS.")
      );
      return;
    }

    configuredSsid = newSsid;
    configuredPassword = newPassword;
    serverBaseUrl = newServer;
    cameraModule = newModule;

    configServer.send(
      200,
      "text/html; charset=utf-8",
      "<html><body><h2>Configuration saved.</h2><p>The ESP32-CAM will restart.</p></body></html>"
    );

    restartRequested = true;
    clearConfigBeforeRestart = false;
    restartRequestedAt = millis();
  });

  configServer.on("/status", HTTP_GET, []() {
    String json;
    json.reserve(900);
    json += F("{");
    json += F("\"device_state\":\"");
    json += deviceStateName(deviceState);
    json += F("\",");
    json += F("\"wifi_state\":\"");
    json += wifiStateName(wifiState);
    json += F("\",");
    json += F("\"camera_ready\":");
    json += boolJson(cameraReady);
    json += F(",\"capture_busy\":");
    json += boolJson(captureBusy);
    json += F(",\"configuration_valid\":");
    json += boolJson(hasValidConfiguration());
    json += F(",\"portal_active\":");
    json += boolJson(portalActive);
    json += F(",\"module\":\"");
    json += jsonEscape(safeModuleName());
    json += F("\",");
    json += F("\"server\":\"");
    json += jsonEscape(serverBaseUrl);
    json += F("\",");
    json += F("\"sta_ip\":\"");
    json += jsonEscape(WiFi.localIP().toString());
    json += F("\",");
    json += F("\"ap_ip\":\"");
    json += jsonEscape(WiFi.softAPIP().toString());
    json += F("\",");
    json += F("\"rssi\":");
    json += String(WiFi.status() == WL_CONNECTED ? WiFi.RSSI() : 0);
    json += F(",\"last_disconnect_reason\":");
    json += String(static_cast<unsigned int>(lastDisconnectReason));
    json += F(",\"uart_tx_gpio\":");
    json += String(ESP32_UART_TX_PIN);
    json += F(",\"uart_rx_gpio\":");
    json += String(ESP32_UART_RX_PIN);
    json += F("}");

    configServer.send(200, "application/json; charset=utf-8", json);
  });

  configServer.on("/reset", HTTP_POST, []() {
    configServer.send(
      200,
      "text/html; charset=utf-8",
      "<html><body><h2>Configuration will be cleared.</h2><p>The ESP32-CAM will restart.</p></body></html>"
    );

    restartRequested = true;
    clearConfigBeforeRestart = true;
    restartRequestedAt = millis();
  });

  configServer.onNotFound([]() {
    configServer.send(404, "text/plain", "Not found");
  });
}

void startWebServer() {
  if (webServerStarted) {
    return;
  }

  configServer.begin();
  webServerStarted = true;
  DEBUG_PRINTLN(F("[HTTP] local configuration/status server started."));
}

void startConfigurationPortal() {
  if (portalActive) {
    return;
  }

  WiFi.mode(WIFI_AP_STA);

  const String apName = "ParkingConfig_" + safeModuleName();
  const bool started = WiFi.softAP(apName.c_str(), CONFIG_AP_PASSWORD);
  if (!started) {
    deviceState = STATE_ERROR;
    DEBUG_PRINTLN(F("[PORTAL] failed to start SoftAP."));
    return;
  }

  portalActive = true;
  wifiState = WIFI_PORTAL_ACTIVE;
  deviceState = STATE_CONFIG_PORTAL;
  portalCloseRequestedAt = 0;

  startWebServer();

  DEBUG_PRINTF(
    "[PORTAL] SSID=%s password=%s URL=http://%s/\n",
    apName.c_str(),
    CONFIG_AP_PASSWORD,
    WiFi.softAPIP().toString().c_str()
  );
}

void serviceWebServer() {
  if (webServerStarted) {
    configServer.handleClient();
  }
}

// ============================================================
// 10. YOLO HTTP transaction
// ============================================================

String buildDetectUrl() {
  return serverBaseUrl + ":8000/detect?module=" + safeModuleName();
}

String uploadFrameToYolo(camera_fb_t *frame) {
  if (frame == nullptr || frame->buf == nullptr || frame->len == 0) {
    return "CLOSE";
  }

  if (WiFi.status() != WL_CONNECTED) {
    return "CLOSE";
  }

  const String url = buildDetectUrl();
  WiFiClient client;
  HTTPClient http;

  DEBUG_PRINTF(
    "[YOLO] POST %s bytes=%u\n",
    url.c_str(),
    static_cast<unsigned int>(frame->len)
  );

  if (!http.begin(client, url)) {
    DEBUG_PRINTLN(F("[YOLO] http.begin failed."));
    return "CLOSE";
  }

  http.setTimeout(HTTP_TIMEOUT_MS);
  http.setReuse(false);
  http.addHeader("Content-Type", "image/jpeg");
  http.addHeader("X-Module-ID", safeModuleName());
  http.addHeader("Connection", "close");

  const int httpCode = http.POST(frame->buf, frame->len);
  String payload;

  if (httpCode > 0) {
    payload = http.getString();
  }

  http.end();

  payload.trim();
  payload.toUpperCase();

  DEBUG_PRINTF(
    "[YOLO] code=%d response=%s\n",
    httpCode,
    payload.c_str()
  );

  if (httpCode == HTTP_CODE_OK && payload == "OPEN") {
    return "OPEN";
  }

  return "CLOSE";
}

String captureAndUpload() {
  deviceState = STATE_CAPTURING;

  camera_fb_t *frame = captureFreshFrame();
  if (frame == nullptr) {
    DEBUG_PRINTLN(F("[CAM] fresh frame capture failed."));
    return "CLOSE";
  }

  deviceState = STATE_UPLOADING;
  const String decision = uploadFrameToYolo(frame);
  esp_camera_fb_return(frame);

  return decision == "OPEN" ? "OPEN" : "CLOSE";
}

String processCaptureRequest() {
  if (captureBusy) {
    return "CLOSE";
  }

  captureBusy = true;
  String decision = "CLOSE";

#if MOCK_UART_MODE
  delay(300);
  decision = "OPEN";
#else
  if (!cameraReady) {
    DEBUG_PRINTLN(F("[CAPTURE] camera unavailable."));
  } else if (!hasValidConfiguration()) {
    DEBUG_PRINTLN(F("[CAPTURE] invalid configuration."));
  } else if (WiFi.status() != WL_CONNECTED) {
    DEBUG_PRINTLN(F("[CAPTURE] Wi-Fi unavailable; fail-safe CLOSE."));
    requestReconnectIfSafe();
  } else {
    decision = captureAndUpload();
  }
#endif

  captureBusy = false;
  return decision == "OPEN" ? "OPEN" : "CLOSE";
}

// ============================================================
// 11. UART protocol with Slave Arduino
// ============================================================

void sendUartDecision(const String &decision) {
  // In production this is the only output emitted on GPIO1/U0TXD.
  if (decision == "OPEN") {
    Serial.println("OPEN");
  } else {
    Serial.println("CLOSE");
  }
  Serial.flush();
}

void executeUartCommand(String command) {
  command.trim();
  command.toUpperCase();

  if (command != "CAPTURE") {
    return;
  }

  deviceState = STATE_CAPTURING;
  const String decision = processCaptureRequest();

  deviceState = STATE_RETURNING_RESULT;
  sendUartDecision(decision);

  if (WiFi.status() == WL_CONNECTED || MOCK_UART_MODE) {
    deviceState = cameraReady ? STATE_READY : STATE_ERROR;
  } else if (portalActive) {
    deviceState = STATE_CONFIG_PORTAL;
  } else {
    deviceState = STATE_CONNECTING_WIFI;
  }
}

void handleSlaveUart() {
  while (Serial.available() > 0) {
    const char received = static_cast<char>(Serial.read());

    if (received == '\n') {
      const String completeCommand = uartCommandBuffer;
      uartCommandBuffer = "";
      executeUartCommand(completeCommand);
      continue;
    }

    if (received == '\r') {
      continue;
    }

    if (uartCommandBuffer.length() >= UART_COMMAND_MAX_LENGTH) {
      uartCommandBuffer = "";
      continue;
    }

    uartCommandBuffer += received;
  }
}

// ============================================================
// 12. Maintenance functions
// ============================================================

void processDeferredRestart() {
  if (!restartRequested) {
    return;
  }

  if (millis() - restartRequestedAt < DEFERRED_RESTART_DELAY_MS) {
    return;
  }

  if (clearConfigBeforeRestart) {
    clearConfiguration();
  }

  delay(50);
  ESP.restart();
}

void runOneShotYoloDebug() {
#if AUTO_YOLO_DEBUG_AFTER_BOOT
  if (oneShotDebugDone || !cameraReady || WiFi.status() != WL_CONNECTED) {
    return;
  }

  if (oneShotDebugArmedAt == 0) {
    oneShotDebugArmedAt = millis();
    return;
  }

  if (millis() - oneShotDebugArmedAt < AUTO_DEBUG_DELAY_MS) {
    return;
  }

  oneShotDebugDone = true;
  DEBUG_PRINTLN(F("[AUTO-YOLO] starting one-shot capture."));

  const String decision = processCaptureRequest();
  DEBUG_PRINTF("[AUTO-YOLO] final decision=%s\n", decision.c_str());

  if (WiFi.status() == WL_CONNECTED) {
    deviceState = cameraReady ? STATE_READY : STATE_ERROR;
  }
#endif
}

void waitForInitialConnectionOrTimeout() {
  const uint32_t startedAt = millis();

  while (WiFi.status() != WL_CONNECTED &&
         millis() - startedAt < STARTUP_WIFI_TIMEOUT_MS) {
    processPendingWiFiEvents();
    serviceWebServer();
    delay(50);
  }

  processPendingWiFiEvents();

  if (WiFi.status() == WL_CONNECTED) {
    wifiState = WIFI_CONNECTED;
    startMdns();
    deviceState = cameraReady ? STATE_READY : STATE_ERROR;
  } else {
    wifiState = WIFI_DISCONNECTED;
    if (disconnectedSinceMs == 0) {
      disconnectedSinceMs = millis();
    }
    startConfigurationPortal();
  }
}

void startUartForCurrentBuild() {
#if VERBOSE_SERIAL_DEBUG
  Serial.begin(DEBUG_UART_BAUD);
#else
  Serial.begin(PRODUCTION_UART_BAUD);
#endif
  Serial.setTimeout(50);
  uartCommandBuffer.reserve(UART_COMMAND_MAX_LENGTH);
  delay(100);
}

// ============================================================
// 13. Arduino setup / loop
// ============================================================

void setup() {
  deviceState = STATE_BOOTING;
  startUartForCurrentBuild();

#if !VERBOSE_SERIAL_DEBUG
  // Suppress ESP-IDF runtime logs on UART0. ROM boot text occurs before setup()
  // and cannot be disabled here; the Slave clears its UART buffer per capture.
  esp_log_level_set("*", ESP_LOG_NONE);
#endif

  DEBUG_PRINTLN(F(""));
  DEBUG_PRINTLN(F("[BOOT] ESP32-CAM Smart Parking gateway."));
  DEBUG_PRINTF(
    "[BOOT] UART0 TX=GPIO%d RX=GPIO%d baud=%lu\n",
    ESP32_UART_TX_PIN,
    ESP32_UART_RX_PIN,
    static_cast<unsigned long>(
#if VERBOSE_SERIAL_DEBUG
      DEBUG_UART_BAUD
#else
      PRODUCTION_UART_BAUD
#endif
    )
  );

#if MOCK_UART_MODE
  cameraReady = true;
  deviceState = STATE_READY;
  DEBUG_PRINTLN(F("[MOCK] UART mock active: CAPTURE -> OPEN."));
  return;
#else
  registerWiFiEvents();
  loadConfiguration();

  // Must run before WiFi.mode(), WiFi.begin(), or WiFi.softAP().
  const String hostname = buildHostname();
  WiFi.setHostname(hostname.c_str());

  registerConfigurationRoutes();

  cameraReady = initCamera();
  if (!cameraReady) {
    deviceState = STATE_ERROR;
  }

  if (!hasValidConfiguration()) {
    startConfigurationPortal();
    return;
  }

  startStationConnection();
  waitForInitialConnectionOrTimeout();
#endif
}

void loop() {
  serviceWebServer();
  maintainWiFi();
  handleSlaveUart();
  runOneShotYoloDebug();
  processDeferredRestart();
  delay(5);
}
