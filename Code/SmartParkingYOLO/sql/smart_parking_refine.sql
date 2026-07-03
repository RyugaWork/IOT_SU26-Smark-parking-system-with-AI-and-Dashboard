/*
    Smart Parking System - Current Design SQL Server Schema
    Matches current Arduino + Slave + ESP32-CAM + YOLO flow.

    Current supported features:
    - Entry/Exit gate modules only
    - Ultrasonic object detection at each gate
    - ESP32-CAM sends image to YOLO server
    - YOLO returns OPEN or CLOSE
    - Master Arduino is the only board that controls the servo gate
    - Dashboard shows vehicle count, gate status, camera/sensor status, latest images, and recent events

    Intentionally NOT included:
    - License plate recognition
    - RFID card tracking
    - Individual parking slot sensors
    - Fee calculation
    - Exact vehicle identity matching
*/

IF DB_ID('SmartParkingIOT102') IS NULL
BEGIN
    CREATE DATABASE SmartParkingIOT102;
END
GO

USE SmartParkingIOT102;
GO

/* Drop old/current-design tables in dependency order */
IF OBJECT_ID('dbo.gate_state_logs', 'U') IS NOT NULL DROP TABLE dbo.gate_state_logs;
IF OBJECT_ID('dbo.detection_events', 'U') IS NOT NULL DROP TABLE dbo.detection_events;
IF OBJECT_ID('dbo.sensor_readings', 'U') IS NOT NULL DROP TABLE dbo.sensor_readings;
IF OBJECT_ID('dbo.device_heartbeats', 'U') IS NOT NULL DROP TABLE dbo.device_heartbeats;
IF OBJECT_ID('dbo.device_modules', 'U') IS NOT NULL DROP TABLE dbo.device_modules;
IF OBJECT_ID('dbo.gates', 'U') IS NOT NULL DROP TABLE dbo.gates;
IF OBJECT_ID('dbo.parking_occupancy', 'U') IS NOT NULL DROP TABLE dbo.parking_occupancy;
GO

/* Stores global capacity and current vehicle count. */
CREATE TABLE dbo.parking_occupancy (
    occupancy_id TINYINT NOT NULL PRIMARY KEY
        CONSTRAINT CK_parking_occupancy_single_row CHECK (occupancy_id = 1),
    capacity INT NOT NULL,
    vehicles_inside INT NOT NULL DEFAULT 0,
    updated_at DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    CONSTRAINT CK_parking_occupancy_capacity CHECK (capacity >= 0),
    CONSTRAINT CK_parking_occupancy_inside CHECK (vehicles_inside >= 0 AND vehicles_inside <= capacity)
);
GO

/* Stores current state of the entry and exit gates. */
CREATE TABLE dbo.gates (
    gate_id VARCHAR(20) NOT NULL PRIMARY KEY,        -- ENTRY_GATE / EXIT_GATE
    direction VARCHAR(10) NOT NULL,                 -- ENTRY / EXIT
    gate_state VARCHAR(20) NOT NULL DEFAULT 'CLOSED', -- CLOSED / OPENING / OPEN / CLOSING / ERROR
    last_decision VARCHAR(10) NULL,                 -- OPEN / CLOSE / NONE
    last_updated DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    CONSTRAINT CK_gates_direction CHECK (direction IN ('ENTRY', 'EXIT')),
    CONSTRAINT CK_gates_state CHECK (gate_state IN ('CLOSED', 'OPENING', 'OPEN', 'CLOSING', 'ERROR')),
    CONSTRAINT CK_gates_decision CHECK (last_decision IS NULL OR last_decision IN ('OPEN', 'CLOSE', 'NONE'))
);
GO

/* Stores logical modules in the system. */
CREATE TABLE dbo.device_modules (
    device_id VARCHAR(40) NOT NULL PRIMARY KEY,      -- MASTER_01, SLAVE_ENTRY_01, CAM_ENTRY_01, etc.
    device_type VARCHAR(20) NOT NULL,               -- MASTER / SLAVE / ESP32_CAM / YOLO_SERVER
    gate_id VARCHAR(20) NULL,
    i2c_address VARCHAR(10) NULL,                   -- 0x08 / 0x09 for Slave boards
    status VARCHAR(20) NOT NULL DEFAULT 'UNKNOWN',  -- ONLINE / OFFLINE / ERROR / UNKNOWN
    last_heartbeat DATETIME2 NULL,
    notes NVARCHAR(255) NULL,
    CONSTRAINT FK_device_modules_gates FOREIGN KEY (gate_id) REFERENCES dbo.gates(gate_id),
    CONSTRAINT CK_device_modules_type CHECK (device_type IN ('MASTER', 'SLAVE', 'ESP32_CAM', 'YOLO_SERVER')),
    CONSTRAINT CK_device_modules_status CHECK (status IN ('ONLINE', 'OFFLINE', 'ERROR', 'UNKNOWN'))
);
GO

/* Stores latest and historical ultrasonic readings from each gate module. */
CREATE TABLE dbo.sensor_readings (
    reading_id BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    gate_id VARCHAR(20) NOT NULL,
    slave_address VARCHAR(10) NOT NULL,
    sequence_id INT NULL,
    distance_cm DECIMAL(7,2) NULL,
    object_detected BIT NOT NULL DEFAULT 0,
    created_at DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    CONSTRAINT FK_sensor_readings_gates FOREIGN KEY (gate_id) REFERENCES dbo.gates(gate_id)
);
GO

/*
   Stores every ESP32-CAM / YOLO detection event.
   This is the main event/log table for the current design.
   No plate/RFID is stored because the current YOLO flow only detects object class and returns OPEN/CLOSE.
*/
CREATE TABLE dbo.detection_events (
    detection_id BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    gate_id VARCHAR(20) NOT NULL,
    direction VARCHAR(10) NOT NULL,                 -- ENTRY / EXIT
    sequence_id INT NULL,
    distance_cm DECIMAL(7,2) NULL,
    object_detected BIT NULL,
    raw_image_path NVARCHAR(255) NULL,
    annotated_image_path NVARCHAR(255) NULL,
    detected_class NVARCHAR(40) NULL,               -- car / motorcycle / bus / truck / person / none
    confidence DECIMAL(5,2) NULL,                   -- confidence as 0.00-100.00 percent
    decision VARCHAR(10) NOT NULL,                  -- OPEN / CLOSE
    event_status VARCHAR(20) NOT NULL DEFAULT 'OK', -- OK / TIMEOUT / ERROR / NO_DETECTION
    count_before INT NULL,
    count_after INT NULL,
    error_message NVARCHAR(255) NULL,
    created_at DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    CONSTRAINT FK_detection_events_gates FOREIGN KEY (gate_id) REFERENCES dbo.gates(gate_id),
    CONSTRAINT CK_detection_events_direction CHECK (direction IN ('ENTRY', 'EXIT')),
    CONSTRAINT CK_detection_events_decision CHECK (decision IN ('OPEN', 'CLOSE')),
    CONSTRAINT CK_detection_events_status CHECK (event_status IN ('OK', 'TIMEOUT', 'ERROR', 'NO_DETECTION')),
    CONSTRAINT CK_detection_events_confidence CHECK (confidence IS NULL OR (confidence >= 0 AND confidence <= 100))
);
GO

/* Stores physical gate-state reports from the Master side. */
CREATE TABLE dbo.gate_state_logs (
    gate_log_id BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    gate_id VARCHAR(20) NOT NULL,
    detection_id BIGINT NULL,
    gate_state VARCHAR(20) NOT NULL,
    source_device_id VARCHAR(40) NULL,              -- usually MASTER_01 or CAM_ENTRY_01 if relayed
    created_at DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    CONSTRAINT FK_gate_state_logs_gates FOREIGN KEY (gate_id) REFERENCES dbo.gates(gate_id),
    CONSTRAINT FK_gate_state_logs_detection FOREIGN KEY (detection_id) REFERENCES dbo.detection_events(detection_id),
    CONSTRAINT FK_gate_state_logs_device FOREIGN KEY (source_device_id) REFERENCES dbo.device_modules(device_id),
    CONSTRAINT CK_gate_state_logs_state CHECK (gate_state IN ('CLOSED', 'OPENING', 'OPEN', 'CLOSING', 'ERROR'))
);
GO

/* Stores heartbeat/status pings from backend-visible devices. */
CREATE TABLE dbo.device_heartbeats (
    heartbeat_id BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    device_id VARCHAR(40) NOT NULL,
    status VARCHAR(20) NOT NULL,
    ip_address VARCHAR(45) NULL,
    message NVARCHAR(255) NULL,
    created_at DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    CONSTRAINT FK_device_heartbeats_device FOREIGN KEY (device_id) REFERENCES dbo.device_modules(device_id),
    CONSTRAINT CK_device_heartbeats_status CHECK (status IN ('ONLINE', 'OFFLINE', 'ERROR', 'UNKNOWN'))
);
GO

/* Seed data for the current prototype */
INSERT INTO dbo.parking_occupancy (occupancy_id, capacity, vehicles_inside)
VALUES (1, 2, 0);
GO

INSERT INTO dbo.gates (gate_id, direction, gate_state, last_decision)
VALUES
('ENTRY_GATE', 'ENTRY', 'CLOSED', 'NONE'),
('EXIT_GATE', 'EXIT', 'CLOSED', 'NONE');
GO

INSERT INTO dbo.device_modules (device_id, device_type, gate_id, i2c_address, status, notes)
VALUES
('MASTER_01', 'MASTER', NULL, NULL, 'UNKNOWN', 'Arduino UNO Master: servo, LCD, LED, I2C controller'),
('SLAVE_ENTRY_01', 'SLAVE', 'ENTRY_GATE', '0x08', 'UNKNOWN', 'Entry Arduino UNO Slave: ultrasonic + ESP32-CAM UART'),
('SLAVE_EXIT_01', 'SLAVE', 'EXIT_GATE', '0x09', 'UNKNOWN', 'Exit Arduino UNO Slave: ultrasonic + ESP32-CAM UART'),
('CAM_ENTRY_01', 'ESP32_CAM', 'ENTRY_GATE', NULL, 'UNKNOWN', 'Entry ESP32-CAM sends JPEG to YOLO server'),
('CAM_EXIT_01', 'ESP32_CAM', 'EXIT_GATE', NULL, 'UNKNOWN', 'Exit ESP32-CAM sends JPEG to YOLO server'),
('YOLO_SERVER_01', 'YOLO_SERVER', NULL, NULL, 'UNKNOWN', 'FastAPI YOLO server');
GO

/* Dashboard helper views */
ALTER VIEW dbo.v_dashboard_overview AS
SELECT
    po.capacity,
    po.vehicles_inside,
    po.capacity - po.vehicles_inside AS available_capacity,
    (SELECT COUNT(*) FROM dbo.detection_events de WHERE de.direction = 'ENTRY' AND de.decision = 'OPEN' AND CAST(de.created_at AS DATE) = CAST(GETDATE() AS DATE)) AS entries_today,
    (SELECT COUNT(*) FROM dbo.detection_events de WHERE de.direction = 'EXIT' AND de.decision = 'OPEN' AND CAST(de.created_at AS DATE) = CAST(GETDATE() AS DATE)) AS exits_today,
    (SELECT gate_state FROM dbo.gates WHERE gate_id = 'ENTRY_GATE') AS entry_gate_state,
    (SELECT gate_state FROM dbo.gates WHERE gate_id = 'EXIT_GATE') AS exit_gate_state,
    po.updated_at
FROM dbo.parking_occupancy po
WHERE po.occupancy_id = 1;
GO

ALTER VIEW v_latest_sensor_status AS
SELECT sr.*
FROM dbo.sensor_readings sr
INNER JOIN (
    SELECT gate_id, MAX(created_at) AS max_created_at
    FROM dbo.sensor_readings
    GROUP BY gate_id
) latest ON sr.gate_id = latest.gate_id AND sr.created_at = latest.max_created_at;
GO

ALTER VIEW dbo.v_latest_detection_by_gate AS
SELECT de.*
FROM dbo.detection_events de
INNER JOIN (
    SELECT gate_id, MAX(created_at) AS max_created_at
    FROM dbo.detection_events
    GROUP BY gate_id
) latest ON de.gate_id = latest.gate_id AND de.created_at = latest.max_created_at;
GO

ALTER VIEW dbo.v_recent_detection_events AS
SELECT TOP 50
    detection_id,
    gate_id,
    direction,
    sequence_id,
    detected_class,
    confidence,
    decision,
    event_status,
    count_before,
    count_after,
    raw_image_path,
    annotated_image_path,
    created_at
FROM dbo.detection_events
ORDER BY created_at DESC;
GO

SELECT * FROM dbo.v_dashboard_overview;
SELECT * FROM dbo.v_latest_sensor_status;
SELECT * FROM dbo.v_latest_detection_by_gate;
SELECT * FROM dbo.v_recent_detection_events;
GO
