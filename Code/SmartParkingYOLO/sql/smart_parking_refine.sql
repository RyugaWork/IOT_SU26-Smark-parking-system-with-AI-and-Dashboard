IF DB_ID('SmartParkingIOT102') IS NULL
BEGIN
    CREATE DATABASE SmartParkingIOT102;
END
GO

USE SmartParkingIOT102;
GO

/* Drop old/current-design tables in dependency order */
IF OBJECT_ID('dbo.detection_events', 'U') IS NOT NULL DROP TABLE dbo.detection_events;
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



/* Dashboard helper views */
CREATE VIEW dbo.v_dashboard_overview AS
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

CREATE VIEW dbo.v_latest_detection_by_gate AS
SELECT de.*
FROM dbo.detection_events de
INNER JOIN (
    SELECT gate_id, MAX(created_at) AS max_created_at
    FROM dbo.detection_events
    GROUP BY gate_id
) latest ON de.gate_id = latest.gate_id AND de.created_at = latest.max_created_at;
GO

CREATE VIEW dbo.v_recent_detection_events AS
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
SELECT * FROM dbo.v_latest_detection_by_gate;
SELECT * FROM dbo.v_recent_detection_events;
GO
