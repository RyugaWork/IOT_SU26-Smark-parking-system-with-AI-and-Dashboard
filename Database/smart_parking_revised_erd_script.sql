/* =========================================================
   Smart Parking System with AI and Dashboard
   SQL Server Database Script
   Version: Revised ERD Script
   Notes:
   - ParkingEvents is the central transaction table.
   - DashboardUsers is linked to GateCommands through RequestedByUserId.
   - DeviceHeartbeats is kept as an independent monitoring/log table.
   - ImageRecords stores image paths only, not binary image/video data.
   ========================================================= */

IF DB_ID(N'SmartParkingDB') IS NULL
BEGIN
    CREATE DATABASE SmartParkingDB;
END
GO

USE SmartParkingDB;
GO

/* =========================================================
   Drop tables in reverse dependency order
   ========================================================= */

DROP TABLE IF EXISTS dbo.GateCommands;
DROP TABLE IF EXISTS dbo.ImageRecords;
DROP TABLE IF EXISTS dbo.AiDetections;
DROP TABLE IF EXISTS dbo.ParkingEvents;
DROP TABLE IF EXISTS dbo.Sensors;
DROP TABLE IF EXISTS dbo.Cameras;
DROP TABLE IF EXISTS dbo.DeviceHeartbeats;
DROP TABLE IF EXISTS dbo.VehicleWhitelist;
DROP TABLE IF EXISTS dbo.DashboardUsers;
DROP TABLE IF EXISTS dbo.Gates;
GO

/* =========================================================
   1. Gates
   Purpose: Store entry/exit gate information.
   ========================================================= */

CREATE TABLE dbo.Gates (
    GateId INT IDENTITY(1,1) PRIMARY KEY,
    GateCode VARCHAR(50) NOT NULL UNIQUE,
    GateName NVARCHAR(100) NOT NULL,
    Direction VARCHAR(10) NOT NULL
        CHECK (Direction IN ('IN', 'OUT')),
    Status VARCHAR(20) NOT NULL DEFAULT 'CLOSED'
        CHECK (Status IN ('OPEN', 'CLOSED', 'ERROR')),
    CreatedAt DATETIME2 NOT NULL DEFAULT SYSDATETIME()
);
GO

/* =========================================================
   2. DashboardUsers
   Purpose: Store dashboard login accounts.
   PasswordHash must store hashed password only, not plaintext.
   ========================================================= */

CREATE TABLE dbo.DashboardUsers (
    UserId INT IDENTITY(1,1) PRIMARY KEY,
    Username VARCHAR(50) NOT NULL UNIQUE,
    PasswordHash NVARCHAR(255) NOT NULL,
    Role VARCHAR(20) NOT NULL DEFAULT 'STAFF'
        CHECK (Role IN ('ADMIN', 'STAFF')),
    CreatedAt DATETIME2 NOT NULL DEFAULT SYSDATETIME()
);
GO

/* =========================================================
   3. VehicleWhitelist
   Purpose: Store vehicles that are allowed or denied.
   ========================================================= */

CREATE TABLE dbo.VehicleWhitelist (
    VehicleId INT IDENTITY(1,1) PRIMARY KEY,
    PlateNumber VARCHAR(20) NOT NULL UNIQUE,
    OwnerName NVARCHAR(100) NULL,
    VehicleType VARCHAR(30) NULL,
    IsAllowed BIT NOT NULL DEFAULT 1,
    CreatedAt DATETIME2 NOT NULL DEFAULT SYSDATETIME()
);
GO

/* =========================================================
   4. Cameras
   Purpose: Store ESP32-CAM information.
   ========================================================= */

CREATE TABLE dbo.Cameras (
    CameraId INT IDENTITY(1,1) PRIMARY KEY,
    CameraCode VARCHAR(50) NOT NULL UNIQUE,
    GateId INT NOT NULL,
    IpAddress VARCHAR(50) NULL,
    Location NVARCHAR(100) NULL,
    IsActive BIT NOT NULL DEFAULT 1,
    CreatedAt DATETIME2 NOT NULL DEFAULT SYSDATETIME(),

    CONSTRAINT FK_Cameras_Gates
        FOREIGN KEY (GateId) REFERENCES dbo.Gates(GateId)
);
GO

/* =========================================================
   5. Sensors
   Purpose: Store ultrasonic sensor information.
   ========================================================= */

CREATE TABLE dbo.Sensors (
    SensorId INT IDENTITY(1,1) PRIMARY KEY,
    SensorCode VARCHAR(50) NOT NULL UNIQUE,
    GateId INT NOT NULL,
    ArduinoRole VARCHAR(20) NOT NULL
        CHECK (ArduinoRole IN ('MASTER', 'SLAVE')),
    SensorType VARCHAR(50) NOT NULL DEFAULT 'ULTRASONIC',
    TriggerDistanceCm FLOAT NOT NULL DEFAULT 20,
    LastDistanceCm FLOAT NULL,
    LastUpdatedAt DATETIME2 NULL,

    CONSTRAINT CK_Sensors_TriggerDistance
        CHECK (TriggerDistanceCm > 0),

    CONSTRAINT CK_Sensors_LastDistance
        CHECK (LastDistanceCm IS NULL OR LastDistanceCm >= 0),

    CONSTRAINT FK_Sensors_Gates
        FOREIGN KEY (GateId) REFERENCES dbo.Gates(GateId)
);
GO

/* =========================================================
   6. ParkingEvents
   Purpose: Central transaction table for vehicle entry/exit events.
   ========================================================= */

CREATE TABLE dbo.ParkingEvents (
    EventId INT IDENTITY(1,1) PRIMARY KEY,
    EventCode VARCHAR(50) NOT NULL UNIQUE,

    GateId INT NOT NULL,
    CameraId INT NULL,
    SensorId INT NULL,
    VehicleId INT NULL,

    Direction VARCHAR(10) NOT NULL
        CHECK (Direction IN ('IN', 'OUT')),

    EventTime DATETIME2 NOT NULL DEFAULT SYSDATETIME(),

    PlateNumber VARCHAR(20) NULL,
    VehicleType VARCHAR(30) NULL,

    AiStatus VARCHAR(20) NOT NULL DEFAULT 'PENDING'
        CHECK (AiStatus IN ('PENDING', 'DETECTED', 'FAILED', 'NO_VEHICLE')),

    ReviewStatus VARCHAR(20) NOT NULL DEFAULT 'PENDING'
        CHECK (ReviewStatus IN ('PENDING', 'APPROVED', 'REJECTED', 'MANUAL_REVIEW')),

    GateDecision VARCHAR(20) NOT NULL DEFAULT 'WAITING'
        CHECK (GateDecision IN ('WAITING', 'OPEN', 'DENY', 'MANUAL')),

    GateOpened BIT NOT NULL DEFAULT 0,
    Note NVARCHAR(255) NULL,

    CreatedAt DATETIME2 NOT NULL DEFAULT SYSDATETIME(),

    CONSTRAINT FK_ParkingEvents_Gates
        FOREIGN KEY (GateId) REFERENCES dbo.Gates(GateId),

    CONSTRAINT FK_ParkingEvents_Cameras
        FOREIGN KEY (CameraId) REFERENCES dbo.Cameras(CameraId),

    CONSTRAINT FK_ParkingEvents_Sensors
        FOREIGN KEY (SensorId) REFERENCES dbo.Sensors(SensorId),

    CONSTRAINT FK_ParkingEvents_VehicleWhitelist
        FOREIGN KEY (VehicleId) REFERENCES dbo.VehicleWhitelist(VehicleId)
);
GO

/* =========================================================
   7. AiDetections
   Purpose: Store YOLO/OCR inference results.
   ========================================================= */

CREATE TABLE dbo.AiDetections (
    DetectionId INT IDENTITY(1,1) PRIMARY KEY,
    EventId INT NOT NULL,

    ModelName VARCHAR(100) NULL,
    VehicleClass VARCHAR(50) NULL,
    VehicleConfidence FLOAT NULL,

    PlateDetected BIT NOT NULL DEFAULT 0,
    PlateNumber VARCHAR(20) NULL,
    PlateConfidence FLOAT NULL,

    IsValidVehicle BIT NOT NULL DEFAULT 0,
    InferenceTimeMs INT NULL,

    RawJson NVARCHAR(MAX) NULL,
    CreatedAt DATETIME2 NOT NULL DEFAULT SYSDATETIME(),

    CONSTRAINT CK_AiDetections_VehicleConfidence
        CHECK (VehicleConfidence IS NULL OR VehicleConfidence BETWEEN 0 AND 1),

    CONSTRAINT CK_AiDetections_PlateConfidence
        CHECK (PlateConfidence IS NULL OR PlateConfidence BETWEEN 0 AND 1),

    CONSTRAINT CK_AiDetections_InferenceTime
        CHECK (InferenceTimeMs IS NULL OR InferenceTimeMs >= 0),

    CONSTRAINT FK_AiDetections_ParkingEvents
        FOREIGN KEY (EventId) REFERENCES dbo.ParkingEvents(EventId)
);
GO

/* =========================================================
   8. ImageRecords
   Purpose: Store image paths only.
   Do not store binary images or live video streams in SQL Server.
   ========================================================= */

CREATE TABLE dbo.ImageRecords (
    ImageId INT IDENTITY(1,1) PRIMARY KEY,
    EventId INT NOT NULL,

    OriginalImagePath NVARCHAR(255) NOT NULL,
    DetectedImagePath NVARCHAR(255) NULL,

    UploadedAt DATETIME2 NOT NULL DEFAULT SYSDATETIME(),

    CONSTRAINT FK_ImageRecords_ParkingEvents
        FOREIGN KEY (EventId) REFERENCES dbo.ParkingEvents(EventId)
);
GO

/* =========================================================
   9. GateCommands
   Purpose: Store open/close commands sent by AI, dashboard, or manual control.
   DashboardUsers is linked through RequestedByUserId.
   ========================================================= */

CREATE TABLE dbo.GateCommands (
    CommandId INT IDENTITY(1,1) PRIMARY KEY,
    GateId INT NOT NULL,
    EventId INT NULL,

    Command VARCHAR(20) NOT NULL
        CHECK (Command IN ('OPEN', 'CLOSE')),

    Source VARCHAR(20) NOT NULL
        CHECK (Source IN ('AI', 'DASHBOARD', 'MANUAL')),

    Status VARCHAR(20) NOT NULL DEFAULT 'PENDING'
        CHECK (Status IN ('PENDING', 'SENT', 'ACK', 'FAILED')),

    RequestedBy NVARCHAR(100) NULL,
    RequestedByUserId INT NULL,

    RequestedAt DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    AcknowledgedAt DATETIME2 NULL,

    CONSTRAINT FK_GateCommands_Gates
        FOREIGN KEY (GateId) REFERENCES dbo.Gates(GateId),

    CONSTRAINT FK_GateCommands_ParkingEvents
        FOREIGN KEY (EventId) REFERENCES dbo.ParkingEvents(EventId),

    CONSTRAINT FK_GateCommands_DashboardUsers
        FOREIGN KEY (RequestedByUserId) REFERENCES dbo.DashboardUsers(UserId)
);
GO

/* =========================================================
   10. DeviceHeartbeats
   Purpose: Store generic online/offline/error status logs.
   This table intentionally remains independent because it supports
   multiple device types through DeviceType and DeviceCode.
   ========================================================= */

CREATE TABLE dbo.DeviceHeartbeats (
    HeartbeatId INT IDENTITY(1,1) PRIMARY KEY,
    DeviceType VARCHAR(20) NOT NULL
        CHECK (DeviceType IN ('CAMERA', 'ARDUINO', 'SENSOR')),
    DeviceCode VARCHAR(50) NOT NULL,
    Status VARCHAR(20) NOT NULL
        CHECK (Status IN ('ONLINE', 'OFFLINE', 'ERROR')),
    IpAddress VARCHAR(50) NULL,
    Message NVARCHAR(255) NULL,
    LastSeenAt DATETIME2 NOT NULL DEFAULT SYSDATETIME()
);
GO

/* =========================================================
   Indexes for backend and dashboard queries
   ========================================================= */

CREATE INDEX IX_Cameras_GateId
ON dbo.Cameras(GateId);
GO

CREATE INDEX IX_Sensors_GateId
ON dbo.Sensors(GateId);
GO

CREATE INDEX IX_ParkingEvents_EventTime
ON dbo.ParkingEvents(EventTime DESC);
GO

CREATE INDEX IX_ParkingEvents_GateId
ON dbo.ParkingEvents(GateId);
GO

CREATE INDEX IX_ParkingEvents_CameraId
ON dbo.ParkingEvents(CameraId);
GO

CREATE INDEX IX_ParkingEvents_SensorId
ON dbo.ParkingEvents(SensorId);
GO

CREATE INDEX IX_ParkingEvents_VehicleId
ON dbo.ParkingEvents(VehicleId);
GO

CREATE INDEX IX_ParkingEvents_PlateNumber
ON dbo.ParkingEvents(PlateNumber);
GO

CREATE INDEX IX_ParkingEvents_AiStatus
ON dbo.ParkingEvents(AiStatus);
GO

CREATE INDEX IX_ParkingEvents_ReviewStatus
ON dbo.ParkingEvents(ReviewStatus);
GO

CREATE INDEX IX_ParkingEvents_GateDecision
ON dbo.ParkingEvents(GateDecision);
GO

CREATE INDEX IX_AiDetections_EventId
ON dbo.AiDetections(EventId);
GO

CREATE INDEX IX_ImageRecords_EventId
ON dbo.ImageRecords(EventId);
GO

CREATE INDEX IX_GateCommands_GateId
ON dbo.GateCommands(GateId);
GO

CREATE INDEX IX_GateCommands_EventId
ON dbo.GateCommands(EventId);
GO

CREATE INDEX IX_GateCommands_RequestedByUserId
ON dbo.GateCommands(RequestedByUserId);
GO

CREATE INDEX IX_DeviceHeartbeats_DeviceCode_LastSeenAt
ON dbo.DeviceHeartbeats(DeviceCode, LastSeenAt DESC);
GO

/* =========================================================
   Sample data for demo
   ========================================================= */

INSERT INTO dbo.Gates (GateCode, GateName, Direction, Status)
VALUES
('GATE_IN_01',  N'Entrance Gate', 'IN',  'CLOSED'),
('GATE_OUT_01', N'Exit Gate',     'OUT', 'CLOSED');
GO

INSERT INTO dbo.DashboardUsers (Username, PasswordHash, Role)
VALUES
('admin', N'DEMO_HASH_ONLY_DO_NOT_USE_PLAIN_PASSWORD', 'ADMIN'),
('staff', N'DEMO_HASH_ONLY_DO_NOT_USE_PLAIN_PASSWORD', 'STAFF');
GO

INSERT INTO dbo.VehicleWhitelist (PlateNumber, OwnerName, VehicleType, IsAllowed)
VALUES
('59A12345', N'Nguyen Van A', 'CAR', 1),
('59B67890', N'Tran Thi B',   'MOTORBIKE', 1),
('51C99999', N'Blocked User', 'CAR', 0);
GO

INSERT INTO dbo.Cameras (CameraCode, GateId, IpAddress, Location)
VALUES
('CAM_IN_01',  1, '192.168.1.101', N'Entrance ESP32-CAM'),
('CAM_OUT_01', 2, '192.168.1.102', N'Exit ESP32-CAM');
GO

INSERT INTO dbo.Sensors (SensorCode, GateId, ArduinoRole, SensorType, TriggerDistanceCm)
VALUES
('SENSOR_IN_01',  1, 'SLAVE', 'ULTRASONIC', 20),
('SENSOR_OUT_01', 2, 'SLAVE', 'ULTRASONIC', 20);
GO

INSERT INTO dbo.ParkingEvents
(
    EventCode,
    GateId,
    CameraId,
    SensorId,
    VehicleId,
    Direction,
    PlateNumber,
    VehicleType,
    AiStatus,
    ReviewStatus,
    GateDecision,
    GateOpened,
    Note
)
VALUES
(
    'EVT_20240601_0001',
    1,
    1,
    1,
    1,
    'IN',
    '59A12345',
    'CAR',
    'DETECTED',
    'APPROVED',
    'OPEN',
    1,
    N'Valid vehicle detected at entrance gate.'
),
(
    'EVT_20240601_0002',
    1,
    1,
    1,
    NULL,
    'IN',
    NULL,
    NULL,
    'FAILED',
    'MANUAL_REVIEW',
    'MANUAL',
    0,
    N'Low confidence or unreadable license plate.'
);
GO

INSERT INTO dbo.AiDetections
(
    EventId,
    ModelName,
    VehicleClass,
    VehicleConfidence,
    PlateDetected,
    PlateNumber,
    PlateConfidence,
    IsValidVehicle,
    InferenceTimeMs,
    RawJson
)
VALUES
(
    1,
    'YOLO-LicensePlate-Demo',
    'car',
    0.93,
    1,
    '59A12345',
    0.88,
    1,
    145,
    N'{"vehicle":"car","vehicle_confidence":0.93,"plate":"59A12345","plate_confidence":0.88}'
),
(
    2,
    'YOLO-LicensePlate-Demo',
    NULL,
    NULL,
    0,
    NULL,
    NULL,
    0,
    160,
    N'{"status":"failed","reason":"low_confidence"}'
);
GO

INSERT INTO dbo.ImageRecords
(
    EventId,
    OriginalImagePath,
    DetectedImagePath
)
VALUES
(
    1,
    N'/uploads/original/EVT_20240601_0001.jpg',
    N'/uploads/detected/EVT_20240601_0001_detected.jpg'
),
(
    2,
    N'/uploads/original/EVT_20240601_0002.jpg',
    NULL
);
GO

INSERT INTO dbo.GateCommands
(
    GateId,
    EventId,
    Command,
    Source,
    Status,
    RequestedBy,
    RequestedByUserId,
    AcknowledgedAt
)
VALUES
(
    1,
    1,
    'OPEN',
    'AI',
    'ACK',
    N'AI Module',
    NULL,
    SYSDATETIME()
),
(
    1,
    2,
    'OPEN',
    'DASHBOARD',
    'PENDING',
    N'staff',
    2,
    NULL
);
GO

INSERT INTO dbo.DeviceHeartbeats
(
    DeviceType,
    DeviceCode,
    Status,
    IpAddress,
    Message
)
VALUES
('CAMERA',  'CAM_IN_01',     'ONLINE', '192.168.1.101', N'Camera is online.'),
('CAMERA',  'CAM_OUT_01',    'ONLINE', '192.168.1.102', N'Camera is online.'),
('SENSOR',  'SENSOR_IN_01',  'ONLINE', NULL,            N'Ultrasonic sensor is active.'),
('SENSOR',  'SENSOR_OUT_01', 'ONLINE', NULL,            N'Ultrasonic sensor is active.'),
('ARDUINO', 'ARDUINO_MAIN',  'ONLINE', NULL,            N'Main controller is active.');
GO

/* =========================================================
   Quick verification queries
   ========================================================= */

SELECT * FROM dbo.Gates;
SELECT * FROM dbo.DashboardUsers;
SELECT * FROM dbo.VehicleWhitelist;
SELECT * FROM dbo.Cameras;
SELECT * FROM dbo.Sensors;
SELECT * FROM dbo.ParkingEvents;
SELECT * FROM dbo.AiDetections;
SELECT * FROM dbo.ImageRecords;
SELECT * FROM dbo.GateCommands;
SELECT * FROM dbo.DeviceHeartbeats;
GO

/* =========================================================
   ERD relationship check
   ========================================================= */

SELECT
    fk.name AS ForeignKeyName,
    OBJECT_NAME(fk.parent_object_id) AS ChildTable,
    COL_NAME(fkc.parent_object_id, fkc.parent_column_id) AS ChildColumn,
    OBJECT_NAME(fk.referenced_object_id) AS ParentTable,
    COL_NAME(fkc.referenced_object_id, fkc.referenced_column_id) AS ParentColumn
FROM sys.foreign_keys AS fk
INNER JOIN sys.foreign_key_columns AS fkc
    ON fk.object_id = fkc.constraint_object_id
ORDER BY ChildTable, ForeignKeyName;
GO
