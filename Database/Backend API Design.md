Mục tiêu backend:

FastAPI Backend sẽ là trung tâm xử lý giữa:
ESP32-CAM -> AI YOLO -> SQL Server -> Web Dashboard -> Arduino/ESP32 điều khiển servo

Backend không trực tiếp train YOLO. Backend chỉ nhận ảnh, lưu metadata, nhận kết quả detection, lưu lịch sử xe, lưu sensor reading, lưu trạng thái cổng và phân phối lệnh mở/đóng cổng cho Arduino/ESP32.

1. Cấu trúc project backend chính thức
smart-parking-backend/
│
├── app/
│   ├── __init__.py
│   ├── main.py
│   │
│   ├── core/
│   │   ├── __init__.py
│   │   ├── config.py
│   │   └── security.py
│   │
│   ├── database.py
│   │
│   ├── models/
│   │   ├── __init__.py
│   │   ├── camera_image.py
│   │   ├── ai_detection.py
│   │   ├── vehicle_event.py
│   │   ├── gate.py
│   │   ├── gate_command.py
│   │   └── sensor_reading.py
│   │
│   ├── schemas/
│   │   ├── __init__.py
│   │   ├── dashboard_schema.py
│   │   ├── detection_schema.py
│   │   ├── gate_schema.py
│   │   ├── sensor_schema.py
│   │   ├── image_schema.py
│   │   └── vehicle_event_schema.py
│   │
│   ├── api/
│   │   ├── __init__.py
│   │   └── v1/
│   │       ├── __init__.py
│   │       ├── dashboard_routes.py
│   │       ├── image_routes.py
│   │       ├── detection_routes.py
│   │       ├── vehicle_event_routes.py
│   │       ├── gate_routes.py
│   │       └── sensor_routes.py
│   │
│   ├── services/
│   │   ├── __init__.py
│   │   ├── dashboard_service.py
│   │   ├── image_service.py
│   │   ├── detection_service.py
│   │   ├── vehicle_event_service.py
│   │   ├── gate_service.py
│   │   └── sensor_service.py
│   │
│   └── utils/
│       ├── __init__.py
│       └── file_helper.py
│
├── uploads/
│   ├── entry/
│   ├── exit/
│   └── detection/
│
├── .env
├── requirements.txt
└── README.md
2. Kiến trúc xử lý backend

Backend chia thành 5 layer:

Client / Device
    ↓
API Routes
    ↓
Schemas
    ↓
Services
    ↓
Models + Database

Ý nghĩa từng layer:

api/v1/:
- Khai báo endpoint.
- Nhận request từ ESP32-CAM, AI Module, Dashboard, Arduino.
- Không viết logic phức tạp ở đây.

schemas/:
- Định nghĩa request body và response body.
- Validate dữ liệu đầu vào.

services/:
- Xử lý business logic.
- Ví dụ: nếu detection hợp lệ thì tạo vehicle_event và gate_command OPEN.

models/:
- Mapping với bảng SQL Server bằng SQLAlchemy ORM.

database.py:
- Kết nối SQL Server.
- Tạo session database.

utils/:
- Hàm phụ trợ, ví dụ tạo tên file ảnh, lưu ảnh, kiểm tra extension.
3. Luồng dữ liệu tổng thể
3.1. Luồng xe vào
1. Ultrasonic sensor ở cổng vào phát hiện vật thể.
2. Arduino gửi tín hiệu cho ESP32-CAM chụp ảnh.
3. ESP32-CAM upload ảnh lên FastAPI:
   POST /api/v1/images/upload

4. FastAPI lưu ảnh vào:
   uploads/entry/

5. FastAPI lưu metadata ảnh vào bảng camera_images.

6. AI Compute Module lấy image_id hoặc image_path để chạy YOLO.

7. AI Module gửi kết quả detection về FastAPI:
   POST /api/v1/detections

8. FastAPI lưu kết quả vào bảng ai_detections.

9. Nếu is_valid = true:
   - tạo vehicle_events với event_type = ENTRY
   - tạo gate_commands với command = OPEN, status = PENDING

10. Arduino/ESP32 polling:
    GET /api/v1/devices/{device_id}/commands/pending

11. Arduino nhận lệnh OPEN và điều khiển servo.

12. Arduino gửi ACK:
    PUT /api/v1/gate-commands/{command_id}/ack

13. Backend cập nhật command status = DONE và gate status = OPEN.
3.2. Luồng xe ra
1. Ultrasonic sensor ở cổng ra phát hiện vật thể.
2. Arduino gửi tín hiệu cho ESP32-CAM chụp ảnh.
3. ESP32-CAM upload ảnh lên FastAPI:
   POST /api/v1/images/upload

4. Ảnh được lưu vào:
   uploads/exit/

5. AI Module detect xe hoặc biển số.
6. AI Module gửi detection result.
7. Backend tạo vehicle_event với event_type = EXIT.
8. Backend tạo gate_command OPEN cho cổng ra.
9. Arduino polling command.
10. Arduino mở servo.
11. Arduino ACK lại backend.
4. Danh sách API endpoint chính thức
Nhóm	File route	Method	Endpoint	Mục đích
Image	image_routes.py	POST	/api/v1/images/upload	ESP32-CAM upload ảnh
Image	image_routes.py	GET	/api/v1/images/{image_id}	Lấy thông tin ảnh
Detection	detection_routes.py	POST	/api/v1/detections	AI gửi kết quả YOLO
Detection	detection_routes.py	GET	/api/v1/detections/{detection_id}	Lấy chi tiết detection
Vehicle Event	vehicle_event_routes.py	GET	/api/v1/vehicle-events	Dashboard lấy lịch sử xe
Vehicle Event	vehicle_event_routes.py	GET	/api/v1/vehicle-events/{event_id}	Chi tiết một event
Gate	gate_routes.py	GET	/api/v1/gates/status	Lấy trạng thái tất cả cổng
Gate	gate_routes.py	GET	/api/v1/gates/{gate_id}/status	Lấy trạng thái một cổng
Gate	gate_routes.py	POST	/api/v1/gates/{gate_id}/commands	Dashboard gửi lệnh mở/đóng
Device	gate_routes.py	GET	/api/v1/devices/{device_id}/commands/pending	Arduino/ESP32 lấy lệnh chờ
Device	gate_routes.py	PUT	/api/v1/gate-commands/{command_id}/ack	Arduino/ESP32 xác nhận đã xử lý
Sensor	sensor_routes.py	POST	/api/v1/sensors/readings	Lưu ultrasonic reading
Sensor	sensor_routes.py	GET	/api/v1/sensors/readings	Dashboard xem sensor history
Dashboard	dashboard_routes.py	GET	/api/v1/dashboard/summary	Tổng quan dashboard
Dashboard	dashboard_routes.py	GET	/api/v1/dashboard/recent-events	Event mới nhất
Dashboard	dashboard_routes.py	GET	/api/v1/dashboard/gates	Trạng thái cổng cho dashboard
5. Thiết kế database models
5.1. camera_images

File model:

app/models/camera_image.py

Mục đích: lưu ảnh do ESP32-CAM upload.

Các field chính:

image_id
camera_id
gate_id
direction
image_path
image_url
status
created_at

Status đề xuất:

UPLOADED
PROCESSING
DETECTED
FAILED
5.2. ai_detections

File model:

app/models/ai_detection.py

Mục đích: lưu kết quả AI YOLO.

Các field chính:

detection_id
image_id
camera_id
gate_id
direction
vehicle_type
license_plate
vehicle_confidence
plate_confidence
is_valid
processing_time_ms
raw_result
created_at
5.3. vehicle_events

File model:

app/models/vehicle_event.py

Mục đích: lưu lịch sử xe vào/ra.

Các field chính:

vehicle_event_id
detection_id
image_id
event_type
gate_id
vehicle_type
license_plate
confidence
image_path
created_at

Event type:

ENTRY
EXIT
5.4. gates

File model:

app/models/gate.py

Mục đích: lưu trạng thái cổng.

Các field chính:

gate_id
gate_name
direction
status
last_updated

Gate status:

OPEN
CLOSED
OPENING
CLOSING
ERROR
UNKNOWN
5.5. gate_commands

File model:

app/models/gate_command.py

Mục đích: lưu lệnh mở/đóng cổng.

Các field chính:

command_id
gate_id
command
source
status
requested_by
reason
created_at
ack_by
ack_at

Command:

OPEN
CLOSE
STOP

Command status:

PENDING
PROCESSING
DONE
FAILED
CANCELLED
5.6. sensor_readings

File model:

app/models/sensor_reading.py

Mục đích: lưu dữ liệu ultrasonic sensor.

Các field chính:

sensor_reading_id
sensor_id
gate_id
sensor_type
distance_cm
detected
device_id
created_at
6. Thiết kế schemas
6.1. image_schema.py

Dùng cho upload ảnh và trả thông tin ảnh.

Nên có:

ImageUploadResponse
ImageDetailResponse
ImageListResponse
6.2. detection_schema.py

Dùng cho AI Module gửi kết quả.

Nên có:

DetectionCreateRequest
DetectionCreateResponse
DetectionDetailResponse
6.3. vehicle_event_schema.py

Dùng cho dashboard lấy lịch sử xe.

Nên có:

VehicleEventResponse
VehicleEventListResponse
6.4. gate_schema.py

Dùng cho dashboard và Arduino/ESP32.

Nên có:

GateStatusResponse
GateCommandCreateRequest
GateCommandResponse
PendingCommandResponse
GateCommandAckRequest
6.5. sensor_schema.py

Dùng cho ultrasonic sensor.

Nên có:

SensorReadingCreateRequest
SensorReadingResponse
SensorReadingListResponse
6.6. dashboard_schema.py

Dùng cho dashboard tổng quan.

Nên có:

DashboardSummaryResponse
RecentVehicleEventResponse
GateOverviewResponse
7. Thiết kế API chi tiết
7.1. ESP32-CAM upload image
Endpoint
POST /api/v1/images/upload
Content-Type
multipart/form-data
Request form-data
file: entry_001.jpg
camera_id: CAM_ENTRY_01
gate_id: GATE_ENTRY
direction: ENTRY
Response
{
  "success": true,
  "message": "Image uploaded successfully",
  "data": {
    "image_id": 101,
    "camera_id": "CAM_ENTRY_01",
    "gate_id": "GATE_ENTRY",
    "direction": "ENTRY",
    "image_path": "uploads/entry/20260608_153012_CAM_ENTRY_01.jpg",
    "image_url": "/uploads/entry/20260608_153012_CAM_ENTRY_01.jpg",
    "status": "UPLOADED"
  }
}
Service xử lý

File:

app/services/image_service.py

Logic:

1. Kiểm tra direction là ENTRY hoặc EXIT.
2. Kiểm tra file có phải ảnh không.
3. Tạo tên file không trùng.
4. Nếu direction = ENTRY thì lưu vào uploads/entry/.
5. Nếu direction = EXIT thì lưu vào uploads/exit/.
6. Lưu metadata vào camera_images.
7. Trả image_id cho ESP32-CAM hoặc AI Module.
7.2. AI Module gửi detection result
Endpoint
POST /api/v1/detections
Request JSON
{
  "image_id": 101,
  "camera_id": "CAM_ENTRY_01",
  "gate_id": "GATE_ENTRY",
  "direction": "ENTRY",
  "vehicle_type": "car",
  "license_plate": "51A12345",
  "vehicle_confidence": 0.94,
  "plate_confidence": 0.88,
  "is_valid": true,
  "processing_time_ms": 235,
  "raw_result": {
    "model": "yolov8n",
    "objects": [
      {
        "class": "car",
        "confidence": 0.94,
        "bbox": [120, 80, 420, 300]
      },
      {
        "class": "license_plate",
        "confidence": 0.88,
        "bbox": [210, 260, 320, 295]
      }
    ]
  }
}
Response JSON
{
  "success": true,
  "message": "Detection result saved",
  "data": {
    "detection_id": 501,
    "vehicle_event_id": 301,
    "gate_command_id": 701,
    "gate_action": "OPEN"
  }
}
Service xử lý

File:

app/services/detection_service.py

Logic:

1. Kiểm tra image_id có tồn tại trong camera_images không.
2. Lưu kết quả vào ai_detections.
3. Cập nhật camera_images.status = DETECTED.
4. Nếu is_valid = true:
   - tạo vehicle_events.
   - tạo gate_commands với command = OPEN, status = PENDING.
5. Nếu is_valid = false:
   - không tạo lệnh mở cổng.
   - trả gate_action = NONE.
6. Trả detection_id, vehicle_event_id, gate_command_id.
7.3. Dashboard lấy lịch sử xe vào/ra
Endpoint
GET /api/v1/vehicle-events
Query params
direction=ENTRY hoặc EXIT
license_plate=51A12345
limit=20
offset=0
Ví dụ
GET /api/v1/vehicle-events?direction=ENTRY&limit=20
Response JSON
{
  "success": true,
  "data": [
    {
      "vehicle_event_id": 301,
      "event_type": "ENTRY",
      "license_plate": "51A12345",
      "vehicle_type": "car",
      "gate_id": "GATE_ENTRY",
      "confidence": 0.94,
      "image_path": "uploads/entry/20260608_153012_CAM_ENTRY_01.jpg",
      "created_at": "2026-06-08T15:30:12"
    }
  ]
}
Service xử lý

File:

app/services/vehicle_event_service.py

Logic:

1. Nhận filter từ dashboard.
2. Query bảng vehicle_events.
3. Sort theo created_at DESC.
4. Trả danh sách event.
7.4. Dashboard lấy trạng thái cổng
Endpoint
GET /api/v1/gates/status
Response JSON
{
  "success": true,
  "data": [
    {
      "gate_id": "GATE_ENTRY",
      "gate_name": "Entry Gate",
      "direction": "ENTRY",
      "status": "CLOSED",
      "last_updated": "2026-06-08T15:30:15"
    },
    {
      "gate_id": "GATE_EXIT",
      "gate_name": "Exit Gate",
      "direction": "EXIT",
      "status": "OPEN",
      "last_updated": "2026-06-08T15:31:02"
    }
  ]
}
Service xử lý

File:

app/services/gate_service.py

Logic:

1. Query bảng gates.
2. Trả trạng thái mới nhất của từng cổng.
7.5. Dashboard gửi lệnh mở/đóng cổng
Endpoint
POST /api/v1/gates/{gate_id}/commands
Ví dụ
POST /api/v1/gates/GATE_ENTRY/commands
Request JSON
{
  "command": "OPEN",
  "source": "DASHBOARD",
  "requested_by": "admin",
  "reason": "Manual open from dashboard"
}
Response JSON
{
  "success": true,
  "message": "Gate command created",
  "data": {
    "command_id": 701,
    "gate_id": "GATE_ENTRY",
    "command": "OPEN",
    "status": "PENDING",
    "created_at": "2026-06-08T15:32:10"
  }
}
Service xử lý

File:

app/services/gate_service.py

Logic:

1. Kiểm tra gate_id có tồn tại không.
2. Kiểm tra command là OPEN, CLOSE hoặc STOP.
3. Tạo gate_commands với status = PENDING.
4. Arduino/ESP32 sẽ lấy command này bằng polling API.
7.6. Arduino/ESP32 lấy lệnh đang chờ
Endpoint
GET /api/v1/devices/{device_id}/commands/pending
Ví dụ
GET /api/v1/devices/ARD_ENTRY_01/commands/pending?gate_id=GATE_ENTRY
Response khi có lệnh
{
  "success": true,
  "has_command": true,
  "data": {
    "command_id": 701,
    "gate_id": "GATE_ENTRY",
    "command": "OPEN",
    "status": "PENDING",
    "created_at": "2026-06-08T15:32:10"
  }
}
Response khi không có lệnh
{
  "success": true,
  "has_command": false,
  "data": null
}
Service xử lý

File:

app/services/gate_service.py

Logic:

1. Arduino/ESP32 gọi API liên tục mỗi 1-2 giây.
2. Backend tìm command có status = PENDING theo gate_id.
3. Nếu có:
   - trả command cho Arduino/ESP32.
   - có thể cập nhật status = PROCESSING.
4. Nếu không có:
   - trả has_command = false.
7.7. Arduino/ESP32 xác nhận xử lý command
Endpoint
PUT /api/v1/gate-commands/{command_id}/ack
Ví dụ
PUT /api/v1/gate-commands/701/ack
Request JSON
{
  "device_id": "ARD_ENTRY_01",
  "status": "DONE",
  "message": "Servo opened successfully"
}
Response JSON
{
  "success": true,
  "message": "Command acknowledged",
  "data": {
    "command_id": 701,
    "status": "DONE",
    "ack_by": "ARD_ENTRY_01",
    "ack_at": "2026-06-08T15:32:12"
  }
}
Service xử lý

File:

app/services/gate_service.py

Logic:

1. Tìm command theo command_id.
2. Cập nhật gate_commands.status = DONE hoặc FAILED.
3. Cập nhật ack_by và ack_at.
4. Nếu command = OPEN và status = DONE:
   - cập nhật gates.status = OPEN.
5. Nếu command = CLOSE và status = DONE:
   - cập nhật gates.status = CLOSED.
7.8. Arduino gửi sensor reading
Endpoint
POST /api/v1/sensors/readings
Request JSON
{
  "sensor_id": "US_ENTRY_01",
  "gate_id": "GATE_ENTRY",
  "sensor_type": "ULTRASONIC",
  "distance_cm": 18.5,
  "detected": true,
  "device_id": "ARD_ENTRY_01"
}
Response JSON
{
  "success": true,
  "message": "Sensor reading saved",
  "data": {
    "sensor_reading_id": 9001,
    "sensor_id": "US_ENTRY_01",
    "detected": true,
    "created_at": "2026-06-08T15:33:00"
  }
}
Service xử lý

File:

app/services/sensor_service.py

Logic:

1. Nhận sensor reading từ Arduino.
2. Lưu vào sensor_readings.
3. Nếu detected = true:
   - dashboard có thể hiển thị có xe đang đứng trước cổng.
4. Backend không nhất thiết phải tự chụp ảnh.
   Việc chụp ảnh nên để Arduino gửi lệnh cho ESP32-CAM.
7.9. Dashboard summary
Endpoint
GET /api/v1/dashboard/summary
Response JSON
{
  "success": true,
  "data": {
    "total_entry_today": 25,
    "total_exit_today": 18,
    "current_vehicle_count": 7,
    "entry_gate_status": "CLOSED",
    "exit_gate_status": "OPEN",
    "latest_event": {
      "license_plate": "51A12345",
      "event_type": "ENTRY",
      "created_at": "2026-06-08T15:30:12"
    }
  }
}
Service xử lý

File:

app/services/dashboard_service.py

Logic:

1. Đếm tổng ENTRY trong ngày.
2. Đếm tổng EXIT trong ngày.
3. current_vehicle_count = total_entry_today - total_exit_today.
4. Lấy trạng thái cổng vào.
5. Lấy trạng thái cổng ra.
6. Lấy event mới nhất.
8. Uploads folder design

Cách lưu ảnh:

uploads/
├── entry/
│   └── 20260608_153012_CAM_ENTRY_01.jpg
│
├── exit/
│   └── 20260608_154501_CAM_EXIT_01.jpg
│
└── detection/
    └── 20260608_153012_detected.jpg

Ý nghĩa:

uploads/entry/
- Ảnh gốc từ camera cổng vào.

uploads/exit/
- Ảnh gốc từ camera cổng ra.

uploads/detection/
- Ảnh đã được AI vẽ bounding box.
- Phần này optional, chưa cần làm ngay trong demo đầu.

Database chỉ lưu đường dẫn:

uploads/entry/20260608_153012_CAM_ENTRY_01.jpg

Không lưu trực tiếp ảnh dạng binary vào SQL Server.

9. Kế hoạch triển khai backend theo thứ tự
Phase 1: Setup project

Làm các file cơ bản:

app/__init__.py
app/main.py
app/core/config.py
app/database.py
requirements.txt
.env

Mục tiêu:

- Chạy được FastAPI.
- Vào được http://127.0.0.1:8000/docs.
- Kết nối được SQL Server.
Phase 2: Tạo models

Tạo các file:

camera_image.py
ai_detection.py
vehicle_event.py
gate.py
gate_command.py
sensor_reading.py

Mục tiêu:

- Mapping đúng các bảng database.
- Có thể tạo bảng bằng SQLAlchemy hoặc dùng SQL script riêng.

Khuyến nghị cho bài IoT102:

Nên tạo database bằng SQL Server script trước.
SQLAlchemy chỉ dùng để query/insert/update.
Phase 3: Tạo schemas

Tạo các file:

image_schema.py
detection_schema.py
vehicle_event_schema.py
gate_schema.py
sensor_schema.py
dashboard_schema.py

Mục tiêu:

- Chuẩn hóa JSON request.
- Chuẩn hóa JSON response.
- Dễ test bằng Swagger UI.
Phase 4: Làm Image API

Tạo:

image_routes.py
image_service.py
file_helper.py

API cần chạy được:

POST /api/v1/images/upload
GET  /api/v1/images/{image_id}

Mục tiêu:

- ESP32-CAM hoặc Postman upload được ảnh.
- Ảnh được lưu vào uploads/entry hoặc uploads/exit.
- Database lưu được image_path.
Phase 5: Làm Detection API

Tạo:

detection_routes.py
detection_service.py

API cần chạy được:

POST /api/v1/detections
GET  /api/v1/detections/{detection_id}

Mục tiêu:

- AI Module gửi kết quả YOLO được.
- Backend lưu ai_detections.
- Nếu is_valid = true thì tự tạo:
  - vehicle_events
  - gate_commands OPEN

Đây là API quan trọng nhất của backend.

Phase 6: Làm Gate API

Tạo:

gate_routes.py
gate_service.py
gate_schema.py

API cần chạy được:

GET  /api/v1/gates/status
GET  /api/v1/gates/{gate_id}/status
POST /api/v1/gates/{gate_id}/commands
GET  /api/v1/devices/{device_id}/commands/pending
PUT  /api/v1/gate-commands/{command_id}/ack

Mục tiêu:

- Dashboard tạo lệnh OPEN/CLOSE được.
- Arduino/ESP32 lấy lệnh pending được.
- Arduino/ESP32 ACK sau khi điều khiển servo.
- Backend cập nhật trạng thái cổng.
Phase 7: Làm Sensor API

Tạo:

sensor_routes.py
sensor_service.py
sensor_schema.py

API cần chạy được:

POST /api/v1/sensors/readings
GET  /api/v1/sensors/readings

Mục tiêu:

- Arduino gửi ultrasonic reading được.
- Dashboard xem sensor log được.
Phase 8: Làm Dashboard API

Tạo:

dashboard_routes.py
dashboard_service.py
dashboard_schema.py

API cần chạy được:

GET /api/v1/dashboard/summary
GET /api/v1/dashboard/recent-events
GET /api/v1/dashboard/gates

Mục tiêu:

- Web Dashboard chỉ cần gọi ít API.
- Có dữ liệu tổng quan:
  - tổng xe vào hôm nay
  - tổng xe ra hôm nay
  - số xe đang trong bãi
  - trạng thái cổng
  - event mới nhất
10. Thứ tự test backend

Nên test theo đúng thứ tự này:

1. GET /
   Kiểm tra FastAPI chạy chưa.

2. Test kết nối SQL Server.
   Kiểm tra database.py.

3. POST /api/v1/images/upload
   Upload ảnh thử bằng Swagger UI hoặc Postman.

4. POST /api/v1/detections
   Gửi detection giả lập.

5. GET /api/v1/vehicle-events
   Kiểm tra event có được tạo chưa.

6. GET /api/v1/gates/status
   Kiểm tra trạng thái cổng.

7. GET /api/v1/devices/ARD_ENTRY_01/commands/pending?gate_id=GATE_ENTRY
   Kiểm tra Arduino có lấy được lệnh không.

8. PUT /api/v1/gate-commands/{command_id}/ack
   Giả lập Arduino xác nhận đã mở cổng.

9. POST /api/v1/sensors/readings
   Gửi sensor reading giả lập.

10. GET /api/v1/dashboard/summary
    Kiểm tra dashboard tổng hợp.
11. Phân công logic theo file
main.py

Chỉ làm:

- Tạo FastAPI app
- Include router
- Mount uploads
- CORS

Không viết business logic trong main.py.

routes.py

Chỉ làm:

- Nhận request
- Gọi service
- Trả response

Không xử lý logic dài trong route.

services.py

Làm logic chính:

- Lưu ảnh
- Lưu detection
- Tạo vehicle event
- Tạo gate command
- Cập nhật gate status
- Tính dashboard summary
models.py

Chỉ định nghĩa bảng database.

schemas.py

Chỉ định nghĩa request/response.

12. Kết luận thiết kế

Thiết kế backend cuối cùng nên đi theo hướng:

REST API + SQL Server + file storage local + polling command

Chưa cần WebSocket ngay.

Với demo IoT102, cách này là hợp lý nhất vì:

- Dễ code.
- Dễ debug bằng Swagger UI.
- ESP32/Arduino dễ gọi API.
- Dashboard dễ gọi REST.
- SQL Server lưu được toàn bộ lịch sử.
- Có thể mở rộng realtime sau.

Thứ tự ưu tiên code:

1. database.py + models
2. image upload API
3. detection insert API
4. gate command API
5. vehicle event API
6. sensor reading API
7. dashboard summary API

Nếu làm đúng thứ tự này, backend sẽ có thể demo luồng đầy đủ:

Upload image -> AI gửi detection -> tạo event -> tạo command OPEN -> Arduino lấy command -> ACK -> Dashboard hiển thị lịch sử
Reference

Dựa trên thiết kế project FastAPI mới đã sửa của bạn và yêu cầu Smart Parking System with AI and Dashboard.
