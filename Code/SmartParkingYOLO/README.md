# Smart Parking YOLO Server Rebuild

This package is a clean rebuild of the YOLO/FastAPI server for the Smart Parking System. It keeps the useful ideas from the previous server and template, but the code is simplified and rebuilt to match the current Arduino + ESP32-CAM design.

The most important rule is unchanged:

```text
ESP32-CAM sends JPEG to POST /detect
YOLO server returns plain text OPEN or CLOSE
```

The plain-text result is intentional because the ESP32-CAM forwards it to the Slave Arduino through UART. The Slave stores the result until the Master Arduino polls it. Only the Master Arduino controls the physical servo gate.

---

## 1. Correct System Path

The YOLO server does not directly talk to the Arduino boards.

Correct flow:

```text
Master Arduino
  -> I2C command to Slave Arduino
  -> Slave Arduino sends CAPTURE to ESP32-CAM over UART
  -> ESP32-CAM captures JPEG image
  -> ESP32-CAM sends HTTP POST /detect to YOLO server
  -> YOLO server returns OPEN or CLOSE
  -> ESP32-CAM sends OPEN or CLOSE back to Slave Arduino
  -> Slave Arduino latches the result
  -> Master Arduino polls the Slave and controls the servo gate
```

---

## 2. Files

| File | Purpose |
|---|---|
| `YoloSERVER.py` | Main FastAPI + YOLO server. |
| `database.py` | Optional SQL Server connection helper. SQL is disabled by default. |
| `parking_repository.py` | Optional SQL logging functions for the refined current-design schema. |
| `test_client.py` | PC test client. It replaces the ESP32-CAM for testing. |
| `requirements.txt` | Core Python dependencies. |
| `requirements-sql.txt` | Optional SQL Server dependency: `pyodbc`. |
| `.env.example` | Example configuration values. |
| `sql/smart_parking_refine.sql` | Current-design SQL schema. |
| `README.md` | This document. |

---

## 3. What This Rebuild Supports

Supported now:

- ESP32-CAM sends raw JPEG to `/detect`.
- Server runs YOLO object detection.
- Server returns only `OPEN` or `CLOSE` to ESP32-CAM.
- Server fails safe to `CLOSE` on invalid image, model error, no vehicle, or server exception.
- Server saves raw image, annotated image, and JSON metadata under `results/`.
- Server has a PC debug endpoint `/detect-debug`.
- Server can optionally log to SQL table `dbo.detection_events`.
- Server can optionally update `dbo.parking_occupancy` count.

Not supported in the current design:

- License plate recognition.
- RFID card tracking.
- Individual slot assignment.
- Parking fee calculation.
- Vehicle identity matching between entry and exit.

Those features were removed because the current Arduino/ESP32-CAM/YOLO flow only returns object class detection and a gate decision.

---

## 4. API Endpoints

### `GET /health`

Checks whether the server is running.

Example:

```text
http://127.0.0.1:8000/health
```

Example response:

```json
{
  "status": "ok",
  "model": "yolov8n.pt",
  "confidence_threshold": 0.45,
  "img_size": 640,
  "allowed_classes": ["bus", "car", "motorcycle", "truck"],
  "database_enabled": false
}
```

### `POST /detect`

Main endpoint for ESP32-CAM.

Input:

```text
Raw JPEG bytes in HTTP body
```

Output:

```text
OPEN
```

or:

```text
CLOSE
```

Do not change this endpoint to JSON unless you also change the ESP32-CAM parsing logic.

### `POST /detect-debug`

PC debug endpoint. It runs the same YOLO logic as `/detect`, but returns JSON details such as detected class, confidence, image path, and database result.

Do not use this endpoint in the ESP32-CAM sketch.

### `GET /latest`

Returns the latest saved detection JSON.

### `GET /latest-image`

Returns the latest annotated image.

### `GET /api/dashboard`

Returns SQL dashboard data if `DB_ENABLED=1`. If SQL is disabled, it returns local latest/recent JSON detections.

### `GET /api/detections`

Returns recent detection events from SQL when enabled, otherwise from local JSON files.

---

## 5. Detection Logic

Default YOLO model:

```text
yolov8n.pt
```

Default allowed classes:

```text
car, motorcycle, bus, truck
```

Decision rule:

```text
If at least one allowed class is detected with confidence >= threshold -> OPEN
Otherwise -> CLOSE
```

Failure rule:

```text
No image / invalid JPEG / server error / model error -> CLOSE
```

This matches the project safety requirement: invalid camera/server result must keep the gate closed.

---

## 6. Run Without SQL Server

Use this mode first. It is the easiest mode for camera and YOLO testing.

Open CMD in the package folder.

Create virtual environment:

```cmd
python -m venv .venv
```

Activate:

```cmd
.venv\Scripts\activate.bat
```

Install dependencies:

```cmd
python -m pip install --upgrade pip setuptools wheel
pip install -r requirements.txt
```

Run server with SQL disabled:

```cmd
set DB_ENABLED=0
uvicorn YoloSERVER:app --host 0.0.0.0 --port 8000
```

Keep this CMD window open.

Test in browser:

```text
http://127.0.0.1:8000/health
```

From ESP32-CAM, use the computer IP, not `localhost`:

```text
http://YOUR_PC_IP:8000/detect
```

Example:

```text
http://192.168.1.10:8000/detect
```

---

## 7. Test With `test_client.py`

Open a second CMD window in the same package folder.

Activate the same virtual environment:

```cmd
.venv\Scripts\activate.bat
```

Put a test image in the package folder, for example:

```text
sample_car.jpg
```

Run an ENTRY test:

```cmd
python test_client.py sample_car.jpg --url http://127.0.0.1:8000/detect --module ENTRY
```

Run an EXIT test:

```cmd
python test_client.py sample_car.jpg --url http://127.0.0.1:8000/detect --module EXIT
```

Expected output:

```text
HTTP status: 200
Response:
OPEN
```

or:

```text
Response:
CLOSE
```

Run debug JSON test:

```cmd
python test_client.py sample_car.jpg --url http://127.0.0.1:8000/detect --module ENTRY --debug
```

Send Arduino-like metadata:

```cmd
python test_client.py sample_car.jpg --url http://127.0.0.1:8000/detect --module ENTRY --sequence-id 101 --distance-cm 14.5 --object-detected
```

---

## 8. Run With SQL Server Logging

Only use this after basic `/detect` testing works.

First, create the database using:

```text
sql/smart_parking_refine.sql
```

Install SQL dependency:

```cmd
pip install -r requirements-sql.txt
```

Run with SQL enabled:

```cmd
set DB_ENABLED=1
set DB_HOST=localhost
set DB_PORT=1433
set DB_NAME=SmartParkingIOT102
set DB_USER=sa
set DB_PASSWORD=12345
uvicorn YoloSERVER:app --host 0.0.0.0 --port 8000
```

If your SQL Server uses a different ODBC driver, set it:

```cmd
set DB_DRIVER=ODBC Driver 18 for SQL Server
```

The server logs each detection into:

```text
dbo.detection_events
```

It also updates:

```text
dbo.parking_occupancy
```

Entry `OPEN` increases `vehicles_inside` by 1, unless capacity is full. Exit `OPEN` decreases `vehicles_inside` by 1, but never below 0.

---

## 9. Result Files

When saving is enabled, the server creates:

```text
results/
  raw/
    ENTRY_20260703_130000_123456.jpg
  annotated/
    ENTRY_20260703_130000_123456.jpg
  json/
    ENTRY_20260703_130000_123456.json
  latest_detection.json
  latest_annotated.jpg
```

These files are for debugging and dashboard preview. The Arduino/ESP32-CAM protocol still depends only on the plain `OPEN` or `CLOSE` response from `/detect`.

---

## 10. Optional Configuration

The server reads environment variables.

| Variable | Default | Meaning |
|---|---:|---|
| `MODEL_PATH` | `yolov8n.pt` | YOLO model file. Use `best.pt` for a custom model. |
| `CONF_THRESHOLD` | `0.45` | Minimum confidence for `OPEN`. |
| `IMG_SIZE` | `640` | YOLO inference image size. |
| `ALLOWED_CLASSES` | `car,motorcycle,bus,truck` | Classes allowed to open gate. |
| `SAVE_RAW_IMAGE` | `1` | Save original ESP32-CAM image. |
| `SAVE_RESULT_IMAGE` | `1` | Save YOLO annotated image. |
| `RESULT_DIR` | `results` | Output folder. |
| `DB_ENABLED` | `0` | Enable SQL logging. |
| `DB_FAIL_SAFE_CLOSE` | `0` | Force `CLOSE` if SQL logging fails. |

Example: include `person` during demo:

```cmd
set ALLOWED_CLASSES=person,car,motorcycle,bus,truck
uvicorn YoloSERVER:app --host 0.0.0.0 --port 8000
```

For the final parking-gate logic, vehicle-only classes are safer.

---

## 11. ESP32-CAM Server URL

The ESP32-CAM should send images to `/detect`:

```cpp
SERVER_URL = "http://192.168.1.10:8000/detect";
```

Replace `192.168.1.10` with the IP address of the PC running this server.

Wrong for ESP32-CAM:

```text
http://localhost:8000/detect
```

Correct for ESP32-CAM:

```text
http://PC_IP_ADDRESS:8000/detect
```

---

## 12. Troubleshooting

### Server starts then crashes at `/latest-image`

This rebuild already avoids the old FastAPI bug. The route uses:

```python
@app.get("/latest-image", response_model=None)
```

Do not use the old file that had a return annotation like:

```python
def latest_annotated_image() -> FileResponse | JSONResponse:
```

That can crash FastAPI during startup.

### `WinError 206 filename too long`

Move the package to a short path:

```text
C:\iot\SmartParkingYOLO
```

Then recreate `.venv` there.

### ESP32-CAM cannot connect

Check these items:

- Server is running with `--host 0.0.0.0`.
- ESP32-CAM and PC are on the same Wi-Fi.
- Windows Firewall allows Python or port `8000`.
- ESP32-CAM URL uses PC IP, not `localhost`.

### Server always returns `CLOSE`

Open:

```text
http://127.0.0.1:8000/latest
http://127.0.0.1:8000/latest-image
```

Check what YOLO detected. Then either lower confidence threshold or add the detected class into `ALLOWED_CLASSES`.

Example:

```cmd
set CONF_THRESHOLD=0.30
set ALLOWED_CLASSES=person,car,motorcycle,bus,truck
uvicorn YoloSERVER:app --host 0.0.0.0 --port 8000
```

---

## 13. Recommended Test Order

1. Run server with `DB_ENABLED=0`.
2. Test `/health` in browser.
3. Test `test_client.py` with a local image.
4. Check `/latest` and `/latest-image`.
5. Connect ESP32-CAM to `/detect`.
6. Only after YOLO works, enable SQL logging.

---

## 14. Summary

This rebuild keeps the server aligned with the current project. The server receives JPEG images from ESP32-CAM, detects allowed vehicle classes with YOLO, returns plain `OPEN` or `CLOSE`, saves debug artifacts, and optionally logs events to the refined SQL schema. It does not implement plate recognition, RFID, slot assignment, or fee calculation because those are outside the current hardware/software design.
