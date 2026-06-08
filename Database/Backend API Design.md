1. Kiến trúc Backend API đề xuất

Backend nên đóng vai trò trung tâm giữa ESP32-CAM, AI YOLO, SQL Server và Web Dashboard.

Luồng tổng quát:

ESP32-CAM 
   -> upload image 
   -> FastAPI lưu ảnh vào /uploads
   -> FastAPI lưu image_path vào SQL Server
   -> AI Compute Module lấy ảnh hoặc nhận image_id
   -> YOLO detect
   -> AI gửi detection result về FastAPI
   -> FastAPI lưu kết quả AI + vehicle event + gate command
   -> Dashboard gọi REST API để xem lịch sử, trạng thái cổng
   -> Arduino/ESP32 polling API để lấy lệnh OPEN/CLOSE

FastAPI phù hợp vì hỗ trợ API Python tốt, có thể nhận file upload bằng UploadFile; file và form-data được gửi theo dạng multipart/form-data, và nếu nhận file/form thì cần cài python-multipart.

2. Danh sách API endpoints
Nhóm	Endpoint	Method	Mục đích
Image	/api/v1/images/upload	POST	ESP32-CAM upload ảnh
Detection	/api/v1/detections	POST	AI Module gửi kết quả YOLO
Vehicle Events	/api/v1/vehicle-events	GET	Dashboard lấy lịch sử xe vào/ra
Gate Status	/api/v1/gates/status	GET	Dashboard lấy trạng thái tất cả cổng
Gate Status	/api/v1/gates/{gate_id}/status	GET	Lấy trạng thái một cổng
Gate Command	/api/v1/gates/{gate_id}/commands	POST	Dashboard gửi lệnh OPEN/CLOSE
Device Polling	/api/v1/devices/{device_id}/commands/pending	GET	Arduino/ESP32 lấy lệnh chờ xử lý
Device Ack	/api/v1/gate-commands/{command_id}/ack	PUT	Arduino/ESP32 xác nhận đã xử lý lệnh
Sensor	/api/v1/sensors/readings	POST	Lưu dữ liệu ultrasonic sensor
Gate Log	/api/v1/gate-command-logs	POST	Lưu log lệnh mở/đóng cổng
3. API chi tiết
3.1. ESP32-CAM upload image
Endpoint
POST /api/v1/images/upload
Content-Type: multipart/form-data
Request form-data mẫu
file: car_entry_001.jpg
camera_id: CAM_ENTRY_01
gate_id: GATE_ENTRY
direction: ENTRY
sensor_id: US_ENTRY_01
distance_cm: 18.5
Response JSON mẫu
{
  "success": true,
  "message": "Image uploaded successfully",
  "data": {
    "image_id": 101,
    "camera_id": "CAM_ENTRY_01",
    "gate_id": "GATE_ENTRY",
    "direction": "ENTRY",
    "image_path": "uploads/2026/06/08/car_entry_001.jpg",
    "status": "PROCESSING"
  }
}
Luồng xử lý
1. ESP32-CAM phát hiện xe hoặc nhận lệnh chụp từ Arduino.
2. ESP32-CAM gửi ảnh lên FastAPI.
3. FastAPI validate camera_id, gate_id, direction.
4. FastAPI lưu ảnh vào thư mục /uploads.
5. FastAPI lưu metadata ảnh vào bảng CameraImages.
6. Trả về image_id cho ESP32-CAM hoặc AI Module.
7. AI Module dùng image_id/image_path để detect.
3.2. AI Compute Module gửi detection result
Endpoint
POST /api/v1/detections
Content-Type: application/json
Request JSON mẫu
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
Response JSON mẫu
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
Luồng xử lý
1. AI Module nhận ảnh từ image_path hoặc image_id.
2. YOLO detect vehicle/license plate.
3. AI Module gửi kết quả về FastAPI.
4. FastAPI lưu vào bảng AIDetections.
5. Nếu is_valid = true:
   - tạo VehicleEvent với event_type = ENTRY hoặc EXIT.
   - tạo GateCommand với command = OPEN.
6. Nếu is_valid = false:
   - lưu detection nhưng không mở cổng.
   - gate_action = NONE hoặc DENY.
7. Dashboard có thể thấy kết quả gần như realtime qua REST polling hoặc WebSocket/SSE.
3.3. Dashboard lấy danh sách xe vào/ra
Endpoint
GET /api/v1/vehicle-events?direction=ENTRY&limit=20
Response JSON mẫu
{
  "success": true,
  "data": [
    {
      "vehicle_event_id": 301,
      "event_type": "ENTRY",
      "license_plate": "51A12345",
      "vehicle_type": "car",
      "gate_id": "GATE_ENTRY",
      "image_path": "uploads/2026/06/08/car_entry_001.jpg",
      "confidence": 0.94,
      "created_at": "2026-06-08T15:30:12"
    },
    {
      "vehicle_event_id": 300,
      "event_type": "EXIT",
      "license_plate": "59B88888",
      "vehicle_type": "motorbike",
      "gate_id": "GATE_EXIT",
      "image_path": "uploads/2026/06/08/car_exit_002.jpg",
      "confidence": 0.91,
      "created_at": "2026-06-08T15:25:01"
    }
  ]
}
Luồng xử lý
1. Dashboard gọi API.
2. Backend query bảng VehicleEvents.
3. Có thể filter theo ENTRY, EXIT, license_plate, date range.
4. Backend trả danh sách mới nhất cho dashboard.
3.4. Dashboard lấy trạng thái cổng
Endpoint
GET /api/v1/gates/status
Response JSON mẫu
{
  "success": true,
  "data": [
    {
      "gate_id": "GATE_ENTRY",
      "gate_name": "Entry Gate",
      "direction": "ENTRY",
      "status": "CLOSED",
      "last_command": "OPEN",
      "last_updated": "2026-06-08T15:30:15"
    },
    {
      "gate_id": "GATE_EXIT",
      "gate_name": "Exit Gate",
      "direction": "EXIT",
      "status": "OPEN",
      "last_command": "OPEN",
      "last_updated": "2026-06-08T15:31:02"
    }
  ]
}
Luồng xử lý
1. Dashboard gọi API.
2. Backend lấy dữ liệu từ bảng Gates hoặc GateStatus.
3. Trả trạng thái hiện tại: OPEN, CLOSED, ERROR, UNKNOWN.
3.5. Dashboard gửi lệnh mở/đóng cổng
Endpoint
POST /api/v1/gates/GATE_ENTRY/commands
Content-Type: application/json
Request JSON mẫu
{
  "command": "OPEN",
  "source": "DASHBOARD",
  "requested_by": "admin",
  "reason": "Manual open from dashboard"
}
Response JSON mẫu
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
Luồng xử lý
1. Admin bấm Open/Close trên Dashboard.
2. Dashboard gọi API tạo command.
3. Backend lưu command vào bảng GateCommands với status = PENDING.
4. Arduino/ESP32 sẽ gọi API polling để lấy command mới nhất.
3.6. Arduino/ESP32 lấy lệnh điều khiển cổng
Endpoint
GET /api/v1/devices/ARD_ENTRY_01/commands/pending?gate_id=GATE_ENTRY
Response JSON mẫu khi có lệnh
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
Response JSON mẫu khi không có lệnh
{
  "success": true,
  "has_command": false,
  "data": null
}
Luồng xử lý
1. Arduino/ESP32 gọi API mỗi 500ms - 2000ms.
2. Backend tìm command PENDING mới nhất theo gate_id.
3. Nếu có command:
   - trả command cho Arduino/ESP32.
4. Arduino nhận OPEN/CLOSE.
5. Arduino điều khiển servo.
6. Arduino gọi API ACK để xác nhận đã xử lý.
3.7. Arduino/ESP32 xác nhận đã xử lý lệnh
Endpoint
PUT /api/v1/gate-commands/701/ack
Content-Type: application/json
Request JSON mẫu
{
  "device_id": "ARD_ENTRY_01",
  "status": "DONE",
  "message": "Servo opened successfully"
}
Response JSON mẫu
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
Luồng xử lý
1. Arduino/ESP32 thực hiện command.
2. Arduino/ESP32 gửi ACK về backend.
3. Backend cập nhật GateCommands.status = DONE hoặc FAILED.
4. Backend cập nhật Gates.status = OPEN/CLOSED tương ứng.
5. Backend lưu log vào GateCommandLogs.
3.8. Lưu sensor reading
Endpoint
POST /api/v1/sensors/readings
Content-Type: application/json
Request JSON mẫu
{
  "sensor_id": "US_ENTRY_01",
  "gate_id": "GATE_ENTRY",
  "sensor_type": "ULTRASONIC",
  "distance_cm": 18.5,
  "detected": true,
  "device_id": "ARD_ENTRY_01"
}
Response JSON mẫu
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
Luồng xử lý
1. Arduino đọc ultrasonic.
2. Nếu khoảng cách nhỏ hơn threshold, detected = true.
3. Arduino gửi reading lên backend.
4. Backend lưu vào SensorReadings.
5. Nếu detected = true, hệ thống có thể trigger ESP32-CAM chụp ảnh.
3.9. Lưu gate command log
Endpoint
POST /api/v1/gate-command-logs
Content-Type: application/json
Request JSON mẫu
{
  "command_id": 701,
  "gate_id": "GATE_ENTRY",
  "device_id": "ARD_ENTRY_01",
  "action": "OPEN",
  "status": "SUCCESS",
  "message": "Gate opened in 1.2 seconds"
}
Response JSON mẫu
{
  "success": true,
  "message": "Gate command log saved",
  "data": {
    "log_id": 12001,
    "command_id": 701
  }
}
4. Cấu trúc project FastAPI đề xuất
smart-parking-backend/
│
├── app/
│   ├── main.py
│   │
│   ├── core/
│   │   ├── config.py
│   │   └── security.py
│   │
│   ├── database.py
│   │
│   ├── models/
│   │   ├── camera_image.py
│   │   ├── ai_detection.py
│   │   ├── vehicle_event.py
│   │   ├── gate.py
│   │   ├── gate_command.py
│   │   └── sensor_reading.py
│   │
│   ├── schemas/
│   │   ├── detection_schema.py
│   │   ├── gate_schema.py
│   │   ├── sensor_schema.py
│   │   └── image_schema.py
│   │
│   ├── api/
│   │   └── v1/
│   │       ├── image_routes.py
│   │       ├── detection_routes.py
│   │       ├── vehicle_event_routes.py
│   │       ├── gate_routes.py
│   │       └── sensor_routes.py
│   │
│   ├── services/
│   │   ├── image_service.py
│   │   ├── detection_service.py
│   │   ├── gate_service.py
│   │   └── sensor_service.py
│   │
│   └── utils/
│       └── file_helper.py
│
├── uploads/
│
├── .env
├── requirements.txt
└── README.md

Giải thích nhanh:

models/   : mapping bảng SQL Server bằng SQLAlchemy ORM.
schemas/  : Pydantic request/response DTO.
api/v1/   : định nghĩa endpoint.
services/ : xử lý business logic.
uploads/  : lưu ảnh ESP32-CAM.
database.py : tạo SQLAlchemy engine/session.
5. Code mẫu kết nối SQL Server

SQLAlchemy có dialect riêng cho Microsoft SQL Server và hỗ trợ kết nối qua mssql+pyodbc. Với ODBC Driver 18, khi dùng môi trường local/dev thường cần cấu hình Encrypt=yes và có thể dùng TrustServerCertificate=yes để bỏ qua kiểm tra certificate trong môi trường không có certificate hợp lệ.

requirements.txt
fastapi
uvicorn[standard]
sqlalchemy
pyodbc
pydantic
pydantic-settings
python-multipart
.env
DB_SERVER=localhost
DB_PORT=1433
DB_NAME=SmartParkingDB
DB_USER=sa
DB_PASSWORD=YourStrongPassword123
DB_DRIVER=ODBC Driver 18 for SQL Server
app/core/config.py
from pydantic_settings import BaseSettings
from urllib.parse import quote_plus


class Settings(BaseSettings):
    DB_SERVER: str
    DB_PORT: int = 1433
    DB_NAME: str
    DB_USER: str
    DB_PASSWORD: str
    DB_DRIVER: str = "ODBC Driver 18 for SQL Server"

    class Config:
        env_file = ".env"

    @property
    def database_url(self) -> str:
        odbc_connection = (
            f"DRIVER={{{self.DB_DRIVER}}};"
            f"SERVER={self.DB_SERVER},{self.DB_PORT};"
            f"DATABASE={self.DB_NAME};"
            f"UID={self.DB_USER};"
            f"PWD={self.DB_PASSWORD};"
            f"Encrypt=yes;"
            f"TrustServerCertificate=yes;"
        )

        encoded_connection = quote_plus(odbc_connection)
        return f"mssql+pyodbc:///?odbc_connect={encoded_connection}"


settings = Settings()
app/database.py
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, DeclarativeBase
from app.core.config import settings


engine = create_engine(
    settings.database_url,
    echo=True,
    pool_pre_ping=True,
    pool_size=5,
    max_overflow=10
)

SessionLocal = sessionmaker(
    autocommit=False,
    autoflush=False,
    bind=engine
)


class Base(DeclarativeBase):
    pass


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
6. Model SQLAlchemy tối thiểu cho detection
app/models/ai_detection.py
from sqlalchemy import Column, Integer, String, Float, Boolean, DateTime, ForeignKey, Text
from sqlalchemy.sql import func
from app.database import Base


class AIDetection(Base):
    __tablename__ = "ai_detections"

    detection_id = Column(Integer, primary_key=True, index=True, autoincrement=True)

    image_id = Column(Integer, nullable=False)
    camera_id = Column(String(50), nullable=False)
    gate_id = Column(String(50), nullable=False)
    direction = Column(String(20), nullable=False)

    vehicle_type = Column(String(50), nullable=True)
    license_plate = Column(String(30), nullable=True)

    vehicle_confidence = Column(Float, nullable=True)
    plate_confidence = Column(Float, nullable=True)

    is_valid = Column(Boolean, nullable=False, default=False)
    processing_time_ms = Column(Integer, nullable=True)

    raw_result = Column(Text, nullable=True)

    created_at = Column(DateTime, server_default=func.now(), nullable=False)
app/models/vehicle_event.py
from sqlalchemy import Column, Integer, String, Float, DateTime
from sqlalchemy.sql import func
from app.database import Base


class VehicleEvent(Base):
    __tablename__ = "vehicle_events"

    vehicle_event_id = Column(Integer, primary_key=True, index=True, autoincrement=True)

    detection_id = Column(Integer, nullable=False)
    image_id = Column(Integer, nullable=False)

    event_type = Column(String(20), nullable=False)
    gate_id = Column(String(50), nullable=False)

    vehicle_type = Column(String(50), nullable=True)
    license_plate = Column(String(30), nullable=True)
    confidence = Column(Float, nullable=True)

    image_path = Column(String(255), nullable=True)

    created_at = Column(DateTime, server_default=func.now(), nullable=False)
app/models/gate_command.py
from sqlalchemy import Column, Integer, String, DateTime
from sqlalchemy.sql import func
from app.database import Base


class GateCommand(Base):
    __tablename__ = "gate_commands"

    command_id = Column(Integer, primary_key=True, index=True, autoincrement=True)

    gate_id = Column(String(50), nullable=False)
    command = Column(String(20), nullable=False)

    source = Column(String(50), nullable=False)
    requested_by = Column(String(100), nullable=True)
    reason = Column(String(255), nullable=True)

    status = Column(String(20), nullable=False, default="PENDING")

    created_at = Column(DateTime, server_default=func.now(), nullable=False)
    ack_by = Column(String(50), nullable=True)
    ack_at = Column(DateTime, nullable=True)
7. Schema request/response cho detection
app/schemas/detection_schema.py
from typing import Optional, Dict, Any
from pydantic import BaseModel, Field


class DetectionCreateRequest(BaseModel):
    image_id: int
    camera_id: str
    gate_id: str
    direction: str = Field(..., examples=["ENTRY", "EXIT"])

    vehicle_type: Optional[str] = None
    license_plate: Optional[str] = None

    vehicle_confidence: Optional[float] = None
    plate_confidence: Optional[float] = None

    is_valid: bool
    processing_time_ms: Optional[int] = None

    raw_result: Optional[Dict[str, Any]] = None


class DetectionCreateResponseData(BaseModel):
    detection_id: int
    vehicle_event_id: Optional[int] = None
    gate_command_id: Optional[int] = None
    gate_action: str


class DetectionCreateResponse(BaseModel):
    success: bool
    message: str
    data: DetectionCreateResponseData
8. Code mẫu endpoint insert detection vào database
app/api/v1/detection_routes.py
import json
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.ai_detection import AIDetection
from app.models.vehicle_event import VehicleEvent
from app.models.gate_command import GateCommand
from app.schemas.detection_schema import (
    DetectionCreateRequest,
    DetectionCreateResponse,
    DetectionCreateResponseData
)


router = APIRouter(
    prefix="/api/v1/detections",
    tags=["AI Detections"]
)


@router.post("", response_model=DetectionCreateResponse)
def create_detection(
    request: DetectionCreateRequest,
    db: Session = Depends(get_db)
):
    try:
        raw_result_json = None

        if request.raw_result is not None:
            raw_result_json = json.dumps(request.raw_result, ensure_ascii=False)

        detection = AIDetection(
            image_id=request.image_id,
            camera_id=request.camera_id,
            gate_id=request.gate_id,
            direction=request.direction,
            vehicle_type=request.vehicle_type,
            license_plate=request.license_plate,
            vehicle_confidence=request.vehicle_confidence,
            plate_confidence=request.plate_confidence,
            is_valid=request.is_valid,
            processing_time_ms=request.processing_time_ms,
            raw_result=raw_result_json
        )

        db.add(detection)
        db.flush()

        vehicle_event_id = None
        gate_command_id = None
        gate_action = "NONE"

        if request.is_valid:
            vehicle_event = VehicleEvent(
                detection_id=detection.detection_id,
                image_id=request.image_id,
                event_type=request.direction,
                gate_id=request.gate_id,
                vehicle_type=request.vehicle_type,
                license_plate=request.license_plate,
                confidence=request.vehicle_confidence,
                image_path=None
            )

            db.add(vehicle_event)
            db.flush()

            vehicle_event_id = vehicle_event.vehicle_event_id

            gate_command = GateCommand(
                gate_id=request.gate_id,
                command="OPEN",
                source="AI_MODULE",
                requested_by="YOLO",
                reason=f"Valid {request.direction} detection"
            )

            db.add(gate_command)
            db.flush()

            gate_command_id = gate_command.command_id
            gate_action = "OPEN"

        db.commit()

        return DetectionCreateResponse(
            success=True,
            message="Detection result saved",
            data=DetectionCreateResponseData(
                detection_id=detection.detection_id,
                vehicle_event_id=vehicle_event_id,
                gate_command_id=gate_command_id,
                gate_action=gate_action
            )
        )

    except Exception as error:
        db.rollback()
        raise HTTPException(
            status_code=500,
            detail=f"Failed to save detection result: {str(error)}"
        )
9. Main FastAPI file
app/main.py
from fastapi import FastAPI
from app.database import Base, engine

from app.api.v1.detection_routes import router as detection_router

from app.models.ai_detection import AIDetection
from app.models.vehicle_event import VehicleEvent
from app.models.gate_command import GateCommand


app = FastAPI(
    title="Smart Parking System API",
    description="Backend API for ESP32-CAM, AI YOLO, SQL Server, and Web Dashboard",
    version="1.0.0"
)


Base.metadata.create_all(bind=engine)


app.include_router(detection_router)


@app.get("/")
def root():
    return {
        "success": True,
        "message": "Smart Parking Backend API is running"
    }
10. Cách chạy backend
python -m venv venv
venv\Scripts\activate
pip install -r requirements.txt
uvicorn app.main:app --reload

Sau đó mở:

http://127.0.0.1:8000/docs

Swagger UI của FastAPI sẽ hiện toàn bộ endpoint để test.

11. Gợi ý status chuẩn nên dùng
Gate status
OPEN
CLOSED
OPENING
CLOSING
ERROR
UNKNOWN
Gate command status
PENDING
PROCESSING
DONE
FAILED
CANCELLED
Direction
ENTRY
EXIT
Detection valid logic
is_valid = true nếu:
- vehicle_confidence >= 0.70
- có vehicle_type hợp lệ: car, motorbike, truck, bus
- nếu dùng biển số thì plate_confidence >= 0.70
12. Kết luận thiết kế

Thiết kế backend nên tách rõ 4 nhóm chính:

1. ESP32-CAM API:
   - upload image

2. AI API:
   - insert detection result

3. Dashboard API:
   - get vehicle events
   - get gate status
   - send gate command

4. Device API:
   - Arduino/ESP32 polling command
   - ACK command
   - send sensor reading

Với demo IoT102, chưa cần WebSocket ngay. Cứ dùng REST API + polling là đủ dễ làm, dễ debug, dễ trình bày với giảng viên. Khi dashboard cần realtime mượt hơn thì nâng cấp thêm WebSocket hoặc Server-Sent Events
