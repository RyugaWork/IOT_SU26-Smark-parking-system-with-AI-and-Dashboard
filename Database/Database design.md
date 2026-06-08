Chủ nhân, dưới đây là thiết kế database SQL Server cho Smart Parking System with AI and Dashboard. Thiết kế này đủ cho demo hiện tại: entry, exit, ultrasonic, ESP32-CAM, AI YOLO, servo, dashboard; đồng thời có bảng mở rộng RFID.

1. Danh sách bảng
STT	Bảng	Mục đích
1	ParkingDirection	Lưu 2 hướng/cổng logic: ENTRY, EXIT.
2	Gate	Lưu thông tin cổng vật lý và trạng thái đóng/mở.
3	Sensor	Lưu ultrasonic sensor theo từng hướng.
4	Camera	Lưu ESP32-CAM theo từng hướng, kèm stream_url.
5	Servo	Lưu servo điều khiển cổng.
6	Vehicle	Lưu xe đã nhận dạng được, chủ yếu theo biển số.
7	CaptureImage	Lưu metadata ảnh chụp từ ESP32-CAM, chỉ lưu image_path.
8	AIRecognitionResult	Lưu kết quả YOLO: loại xe, biển số, confidence, hợp lệ hay không.
9	GateAccessEvent	Lưu từng sự kiện xe đến cổng, AI quyết định mở/từ chối.
10	ParkingSession	Lưu phiên gửi xe: xe vào, xe ra, thời gian gửi.
11	SensorReading	Lưu log khoảng cách ultrasonic để dashboard xem trạng thái sensor.
12	RFIDCard	Dự phòng mở rộng RFID trong tương lai.
13	DashboardUser	Lưu tài khoản dashboard.
14	ManualGateCommand	Lưu lệnh mở/đóng cổng thủ công từ dashboard.
2. Thiết kế bảng chi tiết
ParkingDirection
Column	Data type	Null	Ghi chú
DirectionId	TINYINT IDENTITY	NOT NULL	PK
DirectionCode	VARCHAR(10)	NOT NULL	ENTRY, EXIT
DirectionName	NVARCHAR(50)	NOT NULL	Tên hướng
Description	NVARCHAR(255)	NULL	Mô tả

PK: DirectionId
Unique: DirectionCode

Gate
Column	Data type	Null	Ghi chú
GateId	INT IDENTITY	NOT NULL	PK
DirectionId	TINYINT	NOT NULL	FK đến ParkingDirection
GateCode	VARCHAR(50)	NOT NULL	Mã cổng
GateName	NVARCHAR(100)	NOT NULL	Tên cổng
GateStatus	VARCHAR(20)	NOT NULL	OPEN, CLOSED, ERROR, OFFLINE
LastOpenedAt	DATETIME2(0)	NULL	Lần mở gần nhất
CreatedAt	DATETIME2(0)	NOT NULL	Ngày tạo

PK: GateId
FK: DirectionId → ParkingDirection(DirectionId)

Sensor
Column	Data type	Null	Ghi chú
SensorId	INT IDENTITY	NOT NULL	PK
DirectionId	TINYINT	NOT NULL	FK
SensorCode	VARCHAR(50)	NOT NULL	Ví dụ US_ENTRY_01
SensorType	VARCHAR(30)	NOT NULL	Hiện tại: ULTRASONIC
TriggerDistanceCm	DECIMAL(6,2)	NOT NULL	Khoảng cách kích hoạt
Status	VARCHAR(20)	NOT NULL	ACTIVE, OFFLINE, ERROR
LastDistanceCm	DECIMAL(6,2)	NULL	Khoảng cách gần nhất
LastSeenAt	DATETIME2(0)	NULL	Lần gửi dữ liệu gần nhất

PK: SensorId
FK: DirectionId → ParkingDirection(DirectionId)

Camera
Column	Data type	Null	Ghi chú
CameraId	INT IDENTITY	NOT NULL	PK
DirectionId	TINYINT	NOT NULL	FK
CameraCode	VARCHAR(50)	NOT NULL	Ví dụ CAM_ENTRY_01
CameraName	NVARCHAR(100)	NOT NULL	Tên camera
IpAddress	VARCHAR(45)	NULL	IPv4/IPv6
SnapshotEndpoint	NVARCHAR(500)	NULL	API chụp ảnh
StreamUrl	NVARCHAR(500)	NULL	URL live stream
Status	VARCHAR(20)	NOT NULL	ACTIVE, OFFLINE, ERROR
LastSeenAt	DATETIME2(0)	NULL	Lần camera hoạt động gần nhất

PK: CameraId
FK: DirectionId → ParkingDirection(DirectionId)

Servo
Column	Data type	Null	Ghi chú
ServoId	INT IDENTITY	NOT NULL	PK
GateId	INT	NOT NULL	FK
ServoCode	VARCHAR(50)	NOT NULL	Mã servo
MinAngle	INT	NOT NULL	Góc đóng
MaxAngle	INT	NOT NULL	Góc mở
CurrentAngle	INT	NULL	Góc hiện tại
Status	VARCHAR(20)	NOT NULL	ACTIVE, OFFLINE, ERROR
LastMovedAt	DATETIME2(0)	NULL	Lần servo chạy gần nhất

PK: ServoId
FK: GateId → Gate(GateId)

Vehicle
Column	Data type	Null	Ghi chú
VehicleId	BIGINT IDENTITY	NOT NULL	PK
LicensePlate	NVARCHAR(20)	NOT NULL	Biển số
VehicleType	NVARCHAR(30)	NULL	car, motorbike, truck
OwnerName	NVARCHAR(100)	NULL	Chủ xe, nếu có
FirstSeenAt	DATETIME2(0)	NOT NULL	Lần đầu xuất hiện
LastSeenAt	DATETIME2(0)	NULL	Lần gần nhất

PK: VehicleId
Unique: LicensePlate

CaptureImage
Column	Data type	Null	Ghi chú
CaptureId	BIGINT IDENTITY	NOT NULL	PK
DirectionId	TINYINT	NOT NULL	FK
CameraId	INT	NOT NULL	FK
CapturedAt	DATETIME2(0)	NOT NULL	Thời điểm chụp
ImagePath	NVARCHAR(500)	NOT NULL	Đường dẫn ảnh
ThumbnailPath	NVARCHAR(500)	NULL	Ảnh nhỏ cho dashboard
ImageMimeType	VARCHAR(50)	NOT NULL	Ví dụ image/jpeg
FileSizeKB	INT	NULL	Dung lượng
CaptureStatus	VARCHAR(20)	NOT NULL	UPLOADED, FAILED, PROCESSING

PK: CaptureId
FK: DirectionId → ParkingDirection(DirectionId)
FK: CameraId → Camera(CameraId)

AIRecognitionResult
Column	Data type	Null	Ghi chú
AIResultId	BIGINT IDENTITY	NOT NULL	PK
CaptureId	BIGINT	NOT NULL	FK
VehicleId	BIGINT	NULL	FK, null nếu chưa xác định
ModelName	NVARCHAR(100)	NOT NULL	Ví dụ YOLOv8
ModelVersion	NVARCHAR(50)	NULL	Version model
VehicleDetected	BIT	NOT NULL	Có phát hiện xe không
VehicleType	NVARCHAR(30)	NULL	Loại xe
VehicleConfidence	DECIMAL(5,4)	NULL	Confidence 0–1
LicensePlateText	NVARCHAR(20)	NULL	Biển số đọc được
PlateConfidence	DECIMAL(5,4)	NULL	Confidence biển số
IsPlateReadable	BIT	NOT NULL	Có đọc được biển số không
IsValidVehicle	BIT	NOT NULL	Có hợp lệ để mở cổng không
DecisionReason	NVARCHAR(255)	NULL	Lý do AI
ProcessedAt	DATETIME2(0)	NOT NULL	Thời điểm xử lý
ProcessingMs	INT	NULL	Thời gian xử lý ms
RawJsonPath	NVARCHAR(500)	NULL	Lưu JSON kết quả nếu cần

PK: AIResultId
FK: CaptureId → CaptureImage(CaptureId)
FK: VehicleId → Vehicle(VehicleId)

GateAccessEvent
Column	Data type	Null	Ghi chú
EventId	BIGINT IDENTITY	NOT NULL	PK
DirectionId	TINYINT	NOT NULL	FK
GateId	INT	NOT NULL	FK
SensorId	INT	NULL	FK
CameraId	INT	NULL	FK
CaptureId	BIGINT	NULL	FK
AIResultId	BIGINT	NULL	FK
VehicleId	BIGINT	NULL	FK
EventTime	DATETIME2(0)	NOT NULL	Thời điểm sự kiện
TriggerSource	VARCHAR(20)	NOT NULL	SENSOR, RFID, MANUAL, API
AccessDecision	VARCHAR(20)	NOT NULL	OPEN, DENY, REVIEW
GateOpened	BIT	NOT NULL	Có mở cổng không
ServoAngle	INT	NULL	Góc servo khi mở
Reason	NVARCHAR(255)	NULL	Lý do mở/từ chối
CreatedAt	DATETIME2(0)	NOT NULL	Ngày tạo record

PK: EventId
FK: nhiều bảng thiết bị, ảnh, AI, xe.

ParkingSession
Column	Data type	Null	Ghi chú
SessionId	BIGINT IDENTITY	NOT NULL	PK
VehicleId	BIGINT	NULL	FK
LicensePlate	NVARCHAR(20)	NOT NULL	Biển số tại phiên gửi
EntryEventId	BIGINT	NOT NULL	FK đến event vào
ExitEventId	BIGINT	NULL	FK đến event ra
EntryTime	DATETIME2(0)	NOT NULL	Giờ vào
ExitTime	DATETIME2(0)	NULL	Giờ ra
DurationMinutes	computed	NULL	Tự tính phút gửi
ParkingStatus	VARCHAR(20)	NOT NULL	PARKING, COMPLETED
FeeAmount	DECIMAL(12,2)	NULL	Phí gửi xe

PK: SessionId
FK: VehicleId → Vehicle(VehicleId)
FK: EntryEventId, ExitEventId → GateAccessEvent(EventId)

SensorReading
Column	Data type	Null	Ghi chú
ReadingId	BIGINT IDENTITY	NOT NULL	PK
SensorId	INT	NOT NULL	FK
DirectionId	TINYINT	NOT NULL	FK
ReadingTime	DATETIME2(0)	NOT NULL	Thời điểm đo
DistanceCm	DECIMAL(6,2)	NOT NULL	Khoảng cách
IsObjectDetected	BIT	NOT NULL	Có vật thể không
RawValue	NVARCHAR(100)	NULL	Dữ liệu raw
Note	NVARCHAR(255)	NULL	Ghi chú

PK: ReadingId

RFIDCard
Column	Data type	Null	Ghi chú
RFIDCardId	BIGINT IDENTITY	NOT NULL	PK
VehicleId	BIGINT	NULL	FK
CardUID	VARCHAR(100)	NOT NULL	UID thẻ RFID
OwnerName	NVARCHAR(100)	NULL	Chủ thẻ
Status	VARCHAR(20)	NOT NULL	ACTIVE, BLOCKED, EXPIRED
IssuedAt	DATETIME2(0)	NOT NULL	Ngày phát hành
ExpiredAt	DATETIME2(0)	NULL	Ngày hết hạn

PK: RFIDCardId
Unique: CardUID

3. Quan hệ giữa các bảng

Quan hệ chính:

ParkingDirection 1 — n Gate
ParkingDirection 1 — n Sensor
ParkingDirection 1 — n Camera
Gate 1 — n Servo
Camera 1 — n CaptureImage
CaptureImage 1 — 1 AIRecognitionResult
Vehicle 1 — n AIRecognitionResult
Vehicle 1 — n GateAccessEvent
Vehicle 1 — n ParkingSession
GateAccessEvent 1 — n hoặc 1 — 1 với ParkingSession tùy logic entry/exit
Sensor 1 — n SensorReading
Vehicle 1 — n RFIDCard

Luồng dữ liệu database:

Ultrasonic phát hiện vật thể → tạo SensorReading → ESP32-CAM chụp ảnh → tạo CaptureImage → AI YOLO xử lý → tạo AIRecognitionResult → nếu hợp lệ thì tạo GateAccessEvent với AccessDecision = 'OPEN' → nếu là cổng vào thì tạo ParkingSession, nếu là cổng ra thì cập nhật ParkingSession.ExitTime.

4. SQL Server CREATE TABLE script đầy đủ
IF DB_ID(N'SmartParkingDB') IS NULL
BEGIN
    CREATE DATABASE SmartParkingDB;
END
GO

USE SmartParkingDB;
GO

DROP TABLE IF EXISTS ManualGateCommand;
DROP TABLE IF EXISTS DashboardUser;
DROP TABLE IF EXISTS RFIDCard;
DROP TABLE IF EXISTS ParkingSession;
DROP TABLE IF EXISTS GateAccessEvent;
DROP TABLE IF EXISTS AIRecognitionResult;
DROP TABLE IF EXISTS CaptureImage;
DROP TABLE IF EXISTS SensorReading;
DROP TABLE IF EXISTS Vehicle;
DROP TABLE IF EXISTS Servo;
DROP TABLE IF EXISTS Camera;
DROP TABLE IF EXISTS Sensor;
DROP TABLE IF EXISTS Gate;
DROP TABLE IF EXISTS ParkingDirection;
GO

CREATE TABLE ParkingDirection (
    DirectionId TINYINT IDENTITY(1,1) NOT NULL,
    DirectionCode VARCHAR(10) NOT NULL,
    DirectionName NVARCHAR(50) NOT NULL,
    Description NVARCHAR(255) NULL,

    CONSTRAINT PK_ParkingDirection PRIMARY KEY (DirectionId),
    CONSTRAINT UQ_ParkingDirection_Code UNIQUE (DirectionCode),
    CONSTRAINT CK_ParkingDirection_Code CHECK (DirectionCode IN ('ENTRY', 'EXIT'))
);
GO

CREATE TABLE Gate (
    GateId INT IDENTITY(1,1) NOT NULL,
    DirectionId TINYINT NOT NULL,
    GateCode VARCHAR(50) NOT NULL,
    GateName NVARCHAR(100) NOT NULL,
    GateStatus VARCHAR(20) NOT NULL CONSTRAINT DF_Gate_Status DEFAULT 'CLOSED',
    LastOpenedAt DATETIME2(0) NULL,
    CreatedAt DATETIME2(0) NOT NULL CONSTRAINT DF_Gate_CreatedAt DEFAULT SYSDATETIME(),

    CONSTRAINT PK_Gate PRIMARY KEY (GateId),
    CONSTRAINT UQ_Gate_Code UNIQUE (GateCode),
    CONSTRAINT FK_Gate_Direction FOREIGN KEY (DirectionId)
        REFERENCES ParkingDirection(DirectionId),
    CONSTRAINT CK_Gate_Status CHECK (GateStatus IN ('OPEN', 'CLOSED', 'OPENING', 'CLOSING', 'ERROR', 'OFFLINE'))
);
GO

CREATE TABLE Sensor (
    SensorId INT IDENTITY(1,1) NOT NULL,
    DirectionId TINYINT NOT NULL,
    SensorCode VARCHAR(50) NOT NULL,
    SensorType VARCHAR(30) NOT NULL CONSTRAINT DF_Sensor_Type DEFAULT 'ULTRASONIC',
    TriggerDistanceCm DECIMAL(6,2) NOT NULL CONSTRAINT DF_Sensor_Trigger DEFAULT 20.00,
    Status VARCHAR(20) NOT NULL CONSTRAINT DF_Sensor_Status DEFAULT 'ACTIVE',
    LastDistanceCm DECIMAL(6,2) NULL,
    LastSeenAt DATETIME2(0) NULL,

    CONSTRAINT PK_Sensor PRIMARY KEY (SensorId),
    CONSTRAINT UQ_Sensor_Code UNIQUE (SensorCode),
    CONSTRAINT FK_Sensor_Direction FOREIGN KEY (DirectionId)
        REFERENCES ParkingDirection(DirectionId),
    CONSTRAINT CK_Sensor_Type CHECK (SensorType IN ('ULTRASONIC')),
    CONSTRAINT CK_Sensor_Status CHECK (Status IN ('ACTIVE', 'OFFLINE', 'ERROR')),
    CONSTRAINT CK_Sensor_Trigger CHECK (TriggerDistanceCm > 0)
);
GO

CREATE TABLE Camera (
    CameraId INT IDENTITY(1,1) NOT NULL,
    DirectionId TINYINT NOT NULL,
    CameraCode VARCHAR(50) NOT NULL,
    CameraName NVARCHAR(100) NOT NULL,
    IpAddress VARCHAR(45) NULL,
    SnapshotEndpoint NVARCHAR(500) NULL,
    StreamUrl NVARCHAR(500) NULL,
    Status VARCHAR(20) NOT NULL CONSTRAINT DF_Camera_Status DEFAULT 'ACTIVE',
    LastSeenAt DATETIME2(0) NULL,

    CONSTRAINT PK_Camera PRIMARY KEY (CameraId),
    CONSTRAINT UQ_Camera_Code UNIQUE (CameraCode),
    CONSTRAINT FK_Camera_Direction FOREIGN KEY (DirectionId)
        REFERENCES ParkingDirection(DirectionId),
    CONSTRAINT CK_Camera_Status CHECK (Status IN ('ACTIVE', 'OFFLINE', 'ERROR'))
);
GO

CREATE TABLE Servo (
    ServoId INT IDENTITY(1,1) NOT NULL,
    GateId INT NOT NULL,
    ServoCode VARCHAR(50) NOT NULL,
    MinAngle INT NOT NULL CONSTRAINT DF_Servo_MinAngle DEFAULT 0,
    MaxAngle INT NOT NULL CONSTRAINT DF_Servo_MaxAngle DEFAULT 90,
    CurrentAngle INT NULL,
    Status VARCHAR(20) NOT NULL CONSTRAINT DF_Servo_Status DEFAULT 'ACTIVE',
    LastMovedAt DATETIME2(0) NULL,

    CONSTRAINT PK_Servo PRIMARY KEY (ServoId),
    CONSTRAINT UQ_Servo_Code UNIQUE (ServoCode),
    CONSTRAINT FK_Servo_Gate FOREIGN KEY (GateId)
        REFERENCES Gate(GateId),
    CONSTRAINT CK_Servo_Status CHECK (Status IN ('ACTIVE', 'OFFLINE', 'ERROR')),
    CONSTRAINT CK_Servo_Angle CHECK (MinAngle >= 0 AND MaxAngle <= 180 AND MinAngle < MaxAngle),
    CONSTRAINT CK_Servo_CurrentAngle CHECK (CurrentAngle IS NULL OR CurrentAngle BETWEEN 0 AND 180)
);
GO

CREATE TABLE Vehicle (
    VehicleId BIGINT IDENTITY(1,1) NOT NULL,
    LicensePlate NVARCHAR(20) NOT NULL,
    VehicleType NVARCHAR(30) NULL,
    OwnerName NVARCHAR(100) NULL,
    FirstSeenAt DATETIME2(0) NOT NULL CONSTRAINT DF_Vehicle_FirstSeenAt DEFAULT SYSDATETIME(),
    LastSeenAt DATETIME2(0) NULL,

    CONSTRAINT PK_Vehicle PRIMARY KEY (VehicleId),
    CONSTRAINT UQ_Vehicle_LicensePlate UNIQUE (LicensePlate)
);
GO

CREATE TABLE SensorReading (
    ReadingId BIGINT IDENTITY(1,1) NOT NULL,
    SensorId INT NOT NULL,
    DirectionId TINYINT NOT NULL,
    ReadingTime DATETIME2(0) NOT NULL CONSTRAINT DF_SensorReading_Time DEFAULT SYSDATETIME(),
    DistanceCm DECIMAL(6,2) NOT NULL,
    IsObjectDetected BIT NOT NULL,
    RawValue NVARCHAR(100) NULL,
    Note NVARCHAR(255) NULL,

    CONSTRAINT PK_SensorReading PRIMARY KEY (ReadingId),
    CONSTRAINT FK_SensorReading_Sensor FOREIGN KEY (SensorId)
        REFERENCES Sensor(SensorId),
    CONSTRAINT FK_SensorReading_Direction FOREIGN KEY (DirectionId)
        REFERENCES ParkingDirection(DirectionId),
    CONSTRAINT CK_SensorReading_Distance CHECK (DistanceCm >= 0)
);
GO

CREATE TABLE CaptureImage (
    CaptureId BIGINT IDENTITY(1,1) NOT NULL,
    DirectionId TINYINT NOT NULL,
    CameraId INT NOT NULL,
    CapturedAt DATETIME2(0) NOT NULL CONSTRAINT DF_CaptureImage_CapturedAt DEFAULT SYSDATETIME(),
    ImagePath NVARCHAR(500) NOT NULL,
    ThumbnailPath NVARCHAR(500) NULL,
    ImageMimeType VARCHAR(50) NOT NULL CONSTRAINT DF_CaptureImage_Mime DEFAULT 'image/jpeg',
    FileSizeKB INT NULL,
    CaptureStatus VARCHAR(20) NOT NULL CONSTRAINT DF_CaptureImage_Status DEFAULT 'UPLOADED',

    CONSTRAINT PK_CaptureImage PRIMARY KEY (CaptureId),
    CONSTRAINT FK_CaptureImage_Direction FOREIGN KEY (DirectionId)
        REFERENCES ParkingDirection(DirectionId),
    CONSTRAINT FK_CaptureImage_Camera FOREIGN KEY (CameraId)
        REFERENCES Camera(CameraId),
    CONSTRAINT CK_CaptureImage_Status CHECK (CaptureStatus IN ('UPLOADED', 'FAILED', 'PROCESSING')),
    CONSTRAINT CK_CaptureImage_FileSize CHECK (FileSizeKB IS NULL OR FileSizeKB >= 0)
);
GO

CREATE TABLE AIRecognitionResult (
    AIResultId BIGINT IDENTITY(1,1) NOT NULL,
    CaptureId BIGINT NOT NULL,
    VehicleId BIGINT NULL,
    ModelName NVARCHAR(100) NOT NULL,
    ModelVersion NVARCHAR(50) NULL,
    VehicleDetected BIT NOT NULL CONSTRAINT DF_AIResult_VehicleDetected DEFAULT 0,
    VehicleType NVARCHAR(30) NULL,
    VehicleConfidence DECIMAL(5,4) NULL,
    LicensePlateText NVARCHAR(20) NULL,
    PlateConfidence DECIMAL(5,4) NULL,
    IsPlateReadable BIT NOT NULL CONSTRAINT DF_AIResult_IsPlateReadable DEFAULT 0,
    IsValidVehicle BIT NOT NULL CONSTRAINT DF_AIResult_IsValidVehicle DEFAULT 0,
    DecisionReason NVARCHAR(255) NULL,
    ProcessedAt DATETIME2(0) NOT NULL CONSTRAINT DF_AIResult_ProcessedAt DEFAULT SYSDATETIME(),
    ProcessingMs INT NULL,
    RawJsonPath NVARCHAR(500) NULL,

    CONSTRAINT PK_AIRecognitionResult PRIMARY KEY (AIResultId),
    CONSTRAINT UQ_AIRecognitionResult_Capture UNIQUE (CaptureId),
    CONSTRAINT FK_AIRecognitionResult_Capture FOREIGN KEY (CaptureId)
        REFERENCES CaptureImage(CaptureId),
    CONSTRAINT FK_AIRecognitionResult_Vehicle FOREIGN KEY (VehicleId)
        REFERENCES Vehicle(VehicleId),
    CONSTRAINT CK_AIResult_VehicleConfidence CHECK (VehicleConfidence IS NULL OR VehicleConfidence BETWEEN 0 AND 1),
    CONSTRAINT CK_AIResult_PlateConfidence CHECK (PlateConfidence IS NULL OR PlateConfidence BETWEEN 0 AND 1),
    CONSTRAINT CK_AIResult_ProcessingMs CHECK (ProcessingMs IS NULL OR ProcessingMs >= 0)
);
GO

CREATE TABLE GateAccessEvent (
    EventId BIGINT IDENTITY(1,1) NOT NULL,
    DirectionId TINYINT NOT NULL,
    GateId INT NOT NULL,
    SensorId INT NULL,
    CameraId INT NULL,
    CaptureId BIGINT NULL,
    AIResultId BIGINT NULL,
    VehicleId BIGINT NULL,
    EventTime DATETIME2(0) NOT NULL CONSTRAINT DF_GateAccessEvent_EventTime DEFAULT SYSDATETIME(),
    TriggerSource VARCHAR(20) NOT NULL,
    AccessDecision VARCHAR(20) NOT NULL,
    GateOpened BIT NOT NULL,
    ServoAngle INT NULL,
    Reason NVARCHAR(255) NULL,
    CreatedAt DATETIME2(0) NOT NULL CONSTRAINT DF_GateAccessEvent_CreatedAt DEFAULT SYSDATETIME(),

    CONSTRAINT PK_GateAccessEvent PRIMARY KEY (EventId),
    CONSTRAINT FK_GateAccessEvent_Direction FOREIGN KEY (DirectionId)
        REFERENCES ParkingDirection(DirectionId),
    CONSTRAINT FK_GateAccessEvent_Gate FOREIGN KEY (GateId)
        REFERENCES Gate(GateId),
    CONSTRAINT FK_GateAccessEvent_Sensor FOREIGN KEY (SensorId)
        REFERENCES Sensor(SensorId),
    CONSTRAINT FK_GateAccessEvent_Camera FOREIGN KEY (CameraId)
        REFERENCES Camera(CameraId),
    CONSTRAINT FK_GateAccessEvent_Capture FOREIGN KEY (CaptureId)
        REFERENCES CaptureImage(CaptureId),
    CONSTRAINT FK_GateAccessEvent_AIResult FOREIGN KEY (AIResultId)
        REFERENCES AIRecognitionResult(AIResultId),
    CONSTRAINT FK_GateAccessEvent_Vehicle FOREIGN KEY (VehicleId)
        REFERENCES Vehicle(VehicleId),
    CONSTRAINT CK_GateAccessEvent_TriggerSource CHECK (TriggerSource IN ('SENSOR', 'RFID', 'MANUAL', 'API')),
    CONSTRAINT CK_GateAccessEvent_AccessDecision CHECK (AccessDecision IN ('OPEN', 'DENY', 'REVIEW')),
    CONSTRAINT CK_GateAccessEvent_ServoAngle CHECK (ServoAngle IS NULL OR ServoAngle BETWEEN 0 AND 180)
);
GO

CREATE TABLE ParkingSession (
    SessionId BIGINT IDENTITY(1,1) NOT NULL,
    VehicleId BIGINT NULL,
    LicensePlate NVARCHAR(20) NOT NULL,
    EntryEventId BIGINT NOT NULL,
    ExitEventId BIGINT NULL,
    EntryTime DATETIME2(0) NOT NULL,
    ExitTime DATETIME2(0) NULL,
    DurationMinutes AS (
        CASE 
            WHEN ExitTime IS NULL THEN NULL
            ELSE DATEDIFF(MINUTE, EntryTime, ExitTime)
        END
    ),
    ParkingStatus VARCHAR(20) NOT NULL CONSTRAINT DF_ParkingSession_Status DEFAULT 'PARKING',
    FeeAmount DECIMAL(12,2) NULL,

    CONSTRAINT PK_ParkingSession PRIMARY KEY (SessionId),
    CONSTRAINT FK_ParkingSession_Vehicle FOREIGN KEY (VehicleId)
        REFERENCES Vehicle(VehicleId),
    CONSTRAINT FK_ParkingSession_EntryEvent FOREIGN KEY (EntryEventId)
        REFERENCES GateAccessEvent(EventId),
    CONSTRAINT FK_ParkingSession_ExitEvent FOREIGN KEY (ExitEventId)
        REFERENCES GateAccessEvent(EventId),
    CONSTRAINT CK_ParkingSession_Status CHECK (ParkingStatus IN ('PARKING', 'COMPLETED', 'UNKNOWN_EXIT')),
    CONSTRAINT CK_ParkingSession_Time CHECK (ExitTime IS NULL OR ExitTime >= EntryTime),
    CONSTRAINT CK_ParkingSession_Fee CHECK (FeeAmount IS NULL OR FeeAmount >= 0)
);
GO

CREATE TABLE RFIDCard (
    RFIDCardId BIGINT IDENTITY(1,1) NOT NULL,
    VehicleId BIGINT NULL,
    CardUID VARCHAR(100) NOT NULL,
    OwnerName NVARCHAR(100) NULL,
    Status VARCHAR(20) NOT NULL CONSTRAINT DF_RFIDCard_Status DEFAULT 'ACTIVE',
    IssuedAt DATETIME2(0) NOT NULL CONSTRAINT DF_RFIDCard_IssuedAt DEFAULT SYSDATETIME(),
    ExpiredAt DATETIME2(0) NULL,

    CONSTRAINT PK_RFIDCard PRIMARY KEY (RFIDCardId),
    CONSTRAINT UQ_RFIDCard_CardUID UNIQUE (CardUID),
    CONSTRAINT FK_RFIDCard_Vehicle FOREIGN KEY (VehicleId)
        REFERENCES Vehicle(VehicleId),
    CONSTRAINT CK_RFIDCard_Status CHECK (Status IN ('ACTIVE', 'BLOCKED', 'EXPIRED')),
    CONSTRAINT CK_RFIDCard_Time CHECK (ExpiredAt IS NULL OR ExpiredAt >= IssuedAt)
);
GO

CREATE TABLE DashboardUser (
    UserId INT IDENTITY(1,1) NOT NULL,
    Username VARCHAR(50) NOT NULL,
    PasswordHash NVARCHAR(255) NOT NULL,
    FullName NVARCHAR(100) NOT NULL,
    Role VARCHAR(20) NOT NULL,
    IsActive BIT NOT NULL CONSTRAINT DF_DashboardUser_IsActive DEFAULT 1,
    CreatedAt DATETIME2(0) NOT NULL CONSTRAINT DF_DashboardUser_CreatedAt DEFAULT SYSDATETIME(),

    CONSTRAINT PK_DashboardUser PRIMARY KEY (UserId),
    CONSTRAINT UQ_DashboardUser_Username UNIQUE (Username),
    CONSTRAINT CK_DashboardUser_Role CHECK (Role IN ('ADMIN', 'STAFF', 'VIEWER'))
);
GO

CREATE TABLE ManualGateCommand (
    CommandId BIGINT IDENTITY(1,1) NOT NULL,
    GateId INT NOT NULL,
    UserId INT NOT NULL,
    CommandType VARCHAR(20) NOT NULL,
    CommandStatus VARCHAR(20) NOT NULL CONSTRAINT DF_ManualGateCommand_Status DEFAULT 'PENDING',
    RequestedAt DATETIME2(0) NOT NULL CONSTRAINT DF_ManualGateCommand_RequestedAt DEFAULT SYSDATETIME(),
    ExecutedAt DATETIME2(0) NULL,
    Reason NVARCHAR(255) NULL,

    CONSTRAINT PK_ManualGateCommand PRIMARY KEY (CommandId),
    CONSTRAINT FK_ManualGateCommand_Gate FOREIGN KEY (GateId)
        REFERENCES Gate(GateId),
    CONSTRAINT FK_ManualGateCommand_User FOREIGN KEY (UserId)
        REFERENCES DashboardUser(UserId),
    CONSTRAINT CK_ManualGateCommand_Type CHECK (CommandType IN ('OPEN', 'CLOSE')),
    CONSTRAINT CK_ManualGateCommand_Status CHECK (CommandStatus IN ('PENDING', 'EXECUTED', 'FAILED', 'CANCELLED'))
);
GO

CREATE INDEX IX_GateAccessEvent_EventTime
ON GateAccessEvent(EventTime DESC);

CREATE INDEX IX_ParkingSession_LicensePlate
ON ParkingSession(LicensePlate);

CREATE INDEX IX_ParkingSession_EntryTime
ON ParkingSession(EntryTime DESC);

CREATE INDEX IX_SensorReading_Time
ON SensorReading(ReadingTime DESC);

CREATE INDEX IX_CaptureImage_CapturedAt
ON CaptureImage(CapturedAt DESC);
GO
5. Dữ liệu mẫu INSERT INTO để demo dashboard
USE SmartParkingDB;
GO

INSERT INTO ParkingDirection (DirectionCode, DirectionName, Description)
VALUES
('ENTRY', N'Cổng vào', N'Hướng xe đi vào bãi'),
('EXIT', N'Cổng ra', N'Hướng xe đi ra khỏi bãi');

DECLARE @EntryDirectionId TINYINT = (SELECT DirectionId FROM ParkingDirection WHERE DirectionCode = 'ENTRY');
DECLARE @ExitDirectionId  TINYINT = (SELECT DirectionId FROM ParkingDirection WHERE DirectionCode = 'EXIT');

INSERT INTO Gate (DirectionId, GateCode, GateName, GateStatus, LastOpenedAt)
VALUES
(@EntryDirectionId, 'GATE_ENTRY_01', N'Cổng vào số 1', 'CLOSED', '2026-06-08T08:00:05'),
(@ExitDirectionId,  'GATE_EXIT_01',  N'Cổng ra số 1',  'CLOSED', '2026-06-08T10:30:05');

DECLARE @EntryGateId INT = (SELECT GateId FROM Gate WHERE GateCode = 'GATE_ENTRY_01');
DECLARE @ExitGateId  INT = (SELECT GateId FROM Gate WHERE GateCode = 'GATE_EXIT_01');

INSERT INTO Sensor (DirectionId, SensorCode, SensorType, TriggerDistanceCm, Status, LastDistanceCm, LastSeenAt)
VALUES
(@EntryDirectionId, 'US_ENTRY_01', 'ULTRASONIC', 20.00, 'ACTIVE', 12.40, '2026-06-08T12:15:00'),
(@ExitDirectionId,  'US_EXIT_01',  'ULTRASONIC', 20.00, 'ACTIVE', 35.20, '2026-06-08T12:15:00');

DECLARE @EntrySensorId INT = (SELECT SensorId FROM Sensor WHERE SensorCode = 'US_ENTRY_01');
DECLARE @ExitSensorId  INT = (SELECT SensorId FROM Sensor WHERE SensorCode = 'US_EXIT_01');

INSERT INTO Camera (DirectionId, CameraCode, CameraName, IpAddress, SnapshotEndpoint, StreamUrl, Status, LastSeenAt)
VALUES
(@EntryDirectionId, 'CAM_ENTRY_01', N'ESP32-CAM cổng vào', '192.168.1.21',
 N'http://192.168.1.21/capture',
 N'http://192.168.1.21/stream',
 'ACTIVE', '2026-06-08T12:15:00'),

(@ExitDirectionId, 'CAM_EXIT_01', N'ESP32-CAM cổng ra', '192.168.1.22',
 N'http://192.168.1.22/capture',
 N'http://192.168.1.22/stream',
 'ACTIVE', '2026-06-08T12:15:00');

DECLARE @EntryCameraId INT = (SELECT CameraId FROM Camera WHERE CameraCode = 'CAM_ENTRY_01');
DECLARE @ExitCameraId  INT = (SELECT CameraId FROM Camera WHERE CameraCode = 'CAM_EXIT_01');

INSERT INTO Servo (GateId, ServoCode, MinAngle, MaxAngle, CurrentAngle, Status, LastMovedAt)
VALUES
(@EntryGateId, 'SERVO_ENTRY_01', 0, 90, 0, 'ACTIVE', '2026-06-08T12:15:05'),
(@ExitGateId,  'SERVO_EXIT_01',  0, 90, 0, 'ACTIVE', '2026-06-08T10:30:05');

INSERT INTO DashboardUser (Username, PasswordHash, FullName, Role)
VALUES
('admin', 'demo_hash_only_not_real_password', N'Quản trị viên', 'ADMIN'),
('staff01', 'demo_hash_only_not_real_password', N'Nhân viên bãi xe', 'STAFF');

DECLARE @AdminUserId INT = (SELECT UserId FROM DashboardUser WHERE Username = 'admin');

INSERT INTO Vehicle (LicensePlate, VehicleType, OwnerName, FirstSeenAt, LastSeenAt)
VALUES
(N'59A-123.45', N'car', N'Nguyễn Văn A', '2026-06-08T08:00:00', '2026-06-08T10:30:00'),
(N'51F-888.88', N'motorbike', N'Trần Văn B', '2026-06-08T12:15:00', '2026-06-08T12:15:00');

DECLARE @Vehicle1Id BIGINT = (SELECT VehicleId FROM Vehicle WHERE LicensePlate = N'59A-123.45');
DECLARE @Vehicle2Id BIGINT = (SELECT VehicleId FROM Vehicle WHERE LicensePlate = N'51F-888.88');

INSERT INTO RFIDCard (VehicleId, CardUID, OwnerName, Status, IssuedAt, ExpiredAt)
VALUES
(@Vehicle1Id, 'RFID-DEMO-0001', N'Nguyễn Văn A', 'ACTIVE', '2026-06-01T00:00:00', '2027-06-01T00:00:00');

INSERT INTO SensorReading (SensorId, DirectionId, ReadingTime, DistanceCm, IsObjectDetected, RawValue, Note)
VALUES
(@EntrySensorId, @EntryDirectionId, '2026-06-08T08:00:00', 13.50, 1, N'13.50', N'Xe đến cổng vào'),
(@ExitSensorId,  @ExitDirectionId,  '2026-06-08T10:30:00', 14.20, 1, N'14.20', N'Xe đến cổng ra'),
(@EntrySensorId, @EntryDirectionId, '2026-06-08T12:15:00', 12.40, 1, N'12.40', N'Xe máy đến cổng vào'),
(@EntrySensorId, @EntryDirectionId, '2026-06-08T12:20:00', 8.10, 1, N'8.10', N'Vật thể không hợp lệ');

DECLARE @CapEntry1 BIGINT;
DECLARE @AIEntry1 BIGINT;
DECLARE @EventEntry1 BIGINT;

INSERT INTO CaptureImage (DirectionId, CameraId, CapturedAt, ImagePath, ThumbnailPath, FileSizeKB, CaptureStatus)
VALUES
(@EntryDirectionId, @EntryCameraId, '2026-06-08T08:00:01',
 N'/uploads/parking/entry/20260608_080001_59A12345.jpg',
 N'/uploads/parking/entry/thumb_20260608_080001_59A12345.jpg',
 245, 'UPLOADED');

SET @CapEntry1 = SCOPE_IDENTITY();

INSERT INTO AIRecognitionResult (
    CaptureId, VehicleId, ModelName, ModelVersion,
    VehicleDetected, VehicleType, VehicleConfidence,
    LicensePlateText, PlateConfidence,
    IsPlateReadable, IsValidVehicle, DecisionReason,
    ProcessedAt, ProcessingMs, RawJsonPath
)
VALUES (
    @CapEntry1, @Vehicle1Id, N'YOLOv8 + PlateOCR', N'v1.0',
    1, N'car', 0.9620,
    N'59A-123.45', 0.9310,
    1, 1, N'Valid vehicle and readable license plate',
    '2026-06-08T08:00:03', 420,
    N'/uploads/ai-json/20260608_080001_59A12345.json'
);

SET @AIEntry1 = SCOPE_IDENTITY();

INSERT INTO GateAccessEvent (
    DirectionId, GateId, SensorId, CameraId, CaptureId, AIResultId, VehicleId,
    EventTime, TriggerSource, AccessDecision, GateOpened, ServoAngle, Reason
)
VALUES (
    @EntryDirectionId, @EntryGateId, @EntrySensorId, @EntryCameraId, @CapEntry1, @AIEntry1, @Vehicle1Id,
    '2026-06-08T08:00:04', 'SENSOR', 'OPEN', 1, 90, N'AI accepted vehicle'
);

SET @EventEntry1 = SCOPE_IDENTITY();

DECLARE @CapExit1 BIGINT;
DECLARE @AIExit1 BIGINT;
DECLARE @EventExit1 BIGINT;

INSERT INTO CaptureImage (DirectionId, CameraId, CapturedAt, ImagePath, ThumbnailPath, FileSizeKB, CaptureStatus)
VALUES
(@ExitDirectionId, @ExitCameraId, '2026-06-08T10:30:01',
 N'/uploads/parking/exit/20260608_103001_59A12345.jpg',
 N'/uploads/parking/exit/thumb_20260608_103001_59A12345.jpg',
 238, 'UPLOADED');

SET @CapExit1 = SCOPE_IDENTITY();

INSERT INTO AIRecognitionResult (
    CaptureId, VehicleId, ModelName, ModelVersion,
    VehicleDetected, VehicleType, VehicleConfidence,
    LicensePlateText, PlateConfidence,
    IsPlateReadable, IsValidVehicle, DecisionReason,
    ProcessedAt, ProcessingMs, RawJsonPath
)
VALUES (
    @CapExit1, @Vehicle1Id, N'YOLOv8 + PlateOCR', N'v1.0',
    1, N'car', 0.9550,
    N'59A-123.45', 0.9220,
    1, 1, N'License plate matched active parking session',
    '2026-06-08T10:30:03', 390,
    N'/uploads/ai-json/20260608_103001_59A12345.json'
);

SET @AIExit1 = SCOPE_IDENTITY();

INSERT INTO GateAccessEvent (
    DirectionId, GateId, SensorId, CameraId, CaptureId, AIResultId, VehicleId,
    EventTime, TriggerSource, AccessDecision, GateOpened, ServoAngle, Reason
)
VALUES (
    @ExitDirectionId, @ExitGateId, @ExitSensorId, @ExitCameraId, @CapExit1, @AIExit1, @Vehicle1Id,
    '2026-06-08T10:30:04', 'SENSOR', 'OPEN', 1, 90, N'Vehicle exited successfully'
);

SET @EventExit1 = SCOPE_IDENTITY();

INSERT INTO ParkingSession (
    VehicleId, LicensePlate, EntryEventId, ExitEventId,
    EntryTime, ExitTime, ParkingStatus, FeeAmount
)
VALUES (
    @Vehicle1Id, N'59A-123.45', @EventEntry1, @EventExit1,
    '2026-06-08T08:00:04', '2026-06-08T10:30:04',
    'COMPLETED', 10000.00
);

DECLARE @CapEntry2 BIGINT;
DECLARE @AIEntry2 BIGINT;
DECLARE @EventEntry2 BIGINT;

INSERT INTO CaptureImage (DirectionId, CameraId, CapturedAt, ImagePath, ThumbnailPath, FileSizeKB, CaptureStatus)
VALUES
(@EntryDirectionId, @EntryCameraId, '2026-06-08T12:15:01',
 N'/uploads/parking/entry/20260608_121501_51F88888.jpg',
 N'/uploads/parking/entry/thumb_20260608_121501_51F88888.jpg',
 198, 'UPLOADED');

SET @CapEntry2 = SCOPE_IDENTITY();

INSERT INTO AIRecognitionResult (
    CaptureId, VehicleId, ModelName, ModelVersion,
    VehicleDetected, VehicleType, VehicleConfidence,
    LicensePlateText, PlateConfidence,
    IsPlateReadable, IsValidVehicle, DecisionReason,
    ProcessedAt, ProcessingMs, RawJsonPath
)
VALUES (
    @CapEntry2, @Vehicle2Id, N'YOLOv8 + PlateOCR', N'v1.0',
    1, N'motorbike', 0.9440,
    N'51F-888.88', 0.9010,
    1, 1, N'Valid motorbike and readable license plate',
    '2026-06-08T12:15:03', 410,
    N'/uploads/ai-json/20260608_121501_51F88888.json'
);

SET @AIEntry2 = SCOPE_IDENTITY();

INSERT INTO GateAccessEvent (
    DirectionId, GateId, SensorId, CameraId, CaptureId, AIResultId, VehicleId,
    EventTime, TriggerSource, AccessDecision, GateOpened, ServoAngle, Reason
)
VALUES (
    @EntryDirectionId, @EntryGateId, @EntrySensorId, @EntryCameraId, @CapEntry2, @AIEntry2, @Vehicle2Id,
    '2026-06-08T12:15:04', 'SENSOR', 'OPEN', 1, 90, N'AI accepted motorbike'
);

SET @EventEntry2 = SCOPE_IDENTITY();

INSERT INTO ParkingSession (
    VehicleId, LicensePlate, EntryEventId, ExitEventId,
    EntryTime, ExitTime, ParkingStatus, FeeAmount
)
VALUES (
    @Vehicle2Id, N'51F-888.88', @EventEntry2, NULL,
    '2026-06-08T12:15:04', NULL,
    'PARKING', NULL
);

DECLARE @CapDeny BIGINT;
DECLARE @AIDeny BIGINT;

INSERT INTO CaptureImage (DirectionId, CameraId, CapturedAt, ImagePath, ThumbnailPath, FileSizeKB, CaptureStatus)
VALUES
(@EntryDirectionId, @EntryCameraId, '2026-06-08T12:20:01',
 N'/uploads/parking/entry/20260608_122001_unknown.jpg',
 N'/uploads/parking/entry/thumb_20260608_122001_unknown.jpg',
 176, 'UPLOADED');

SET @CapDeny = SCOPE_IDENTITY();

INSERT INTO AIRecognitionResult (
    CaptureId, VehicleId, ModelName, ModelVersion,
    VehicleDetected, VehicleType, VehicleConfidence,
    LicensePlateText, PlateConfidence,
    IsPlateReadable, IsValidVehicle, DecisionReason,
    ProcessedAt, ProcessingMs, RawJsonPath
)
VALUES (
    @CapDeny, NULL, N'YOLOv8 + PlateOCR', N'v1.0',
    0, NULL, 0.2200,
    NULL, NULL,
    0, 0, N'No valid vehicle detected',
    '2026-06-08T12:20:03', 360,
    N'/uploads/ai-json/20260608_122001_unknown.json'
);

SET @AIDeny = SCOPE_IDENTITY();

INSERT INTO GateAccessEvent (
    DirectionId, GateId, SensorId, CameraId, CaptureId, AIResultId, VehicleId,
    EventTime, TriggerSource, AccessDecision, GateOpened, ServoAngle, Reason
)
VALUES (
    @EntryDirectionId, @EntryGateId, @EntrySensorId, @EntryCameraId, @CapDeny, @AIDeny, NULL,
    '2026-06-08T12:20:04', 'SENSOR', 'DENY', 0, 0, N'AI rejected object'
);

INSERT INTO ManualGateCommand (GateId, UserId, CommandType, CommandStatus, RequestedAt, ExecutedAt, Reason)
VALUES
(@EntryGateId, @AdminUserId, 'OPEN', 'EXECUTED', '2026-06-08T13:00:00', '2026-06-08T13:00:02', N'Manual test from dashboard');
GO
6. Vì sao không nên lưu video/live feed trực tiếp trong SQL Server?

Không nên lưu video hoặc live feed trực tiếp trong SQL Server bằng VARBINARY(MAX) vì video là dữ liệu nặng, ghi liên tục, tốc độ cao. Nếu đưa trực tiếp vào database, database sẽ phình rất nhanh, transaction log tăng mạnh, backup/restore chậm, query dashboard bị ảnh hưởng, và chi phí lưu trữ tăng không cần thiết.

Live feed cũng không phải dữ liệu dạng quan hệ. Nó là luồng streaming thời gian thực, phù hợp hơn với HTTP stream, RTSP, WebSocket, file server, NAS, cloud object storage hoặc thư mục upload của backend. SQL Server chỉ nên lưu metadata như:

ImagePath = '/uploads/parking/entry/20260608_080001_59A12345.jpg'
StreamUrl = 'http://192.168.1.21/stream'
RawJsonPath = '/uploads/ai-json/20260608_080001_59A12345.json'

Cách đúng là:

Ảnh/video nằm ở file storage hoặc cloud storage.
SQL Server chỉ lưu đường dẫn, thời gian chụp, camera nào chụp, kết quả AI, confidence score, biển số, và quyết định mở cổng.

Thiết kế này giúp dashboard tải nhanh hơn, database nhẹ hơn, backup dễ hơn, và backend dễ mở rộng hơn.
