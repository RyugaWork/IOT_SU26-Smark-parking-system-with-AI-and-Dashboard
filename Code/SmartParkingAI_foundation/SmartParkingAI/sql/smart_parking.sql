/*
    Smart Parking System - IoT102
    SQL Server mock database for FastAPI + Dashboard prototype.
*/

IF DB_ID('SmartParkingIOT102') IS NULL
BEGIN
    CREATE DATABASE SmartParkingIOT102;
END
GO

USE SmartParkingIOT102;
GO

IF OBJECT_ID('dbo.camera_events', 'U') IS NOT NULL
    DROP TABLE dbo.camera_events;
GO

IF OBJECT_ID('dbo.parking_logs', 'U') IS NOT NULL
    DROP TABLE dbo.parking_logs;
GO

IF OBJECT_ID('dbo.slots', 'U') IS NOT NULL
    DROP TABLE dbo.slots;
GO

CREATE TABLE dbo.slots (
    slot_id INT IDENTITY(1,1) PRIMARY KEY,
    slot_number VARCHAR(10) NOT NULL UNIQUE,
    sensor_distance_cm DECIMAL(6,2) NOT NULL,
    status VARCHAR(20) NOT NULL,
    last_sensor_time DATETIME NOT NULL DEFAULT GETDATE(),
    CONSTRAINT CK_slots_status CHECK (status IN ('AVAILABLE', 'OCCUPIED'))
);
GO

CREATE TABLE dbo.parking_logs (
    log_id INT IDENTITY(1,1) PRIMARY KEY,
    license_plate NVARCHAR(20) NULL,
    rfid_card_id VARCHAR(30) NULL,
    slot_id INT NOT NULL,
    entry_time DATETIME NOT NULL,
    exit_time DATETIME NULL,
    status VARCHAR(20) NOT NULL,
    vehicle_type NVARCHAR(30) NOT NULL DEFAULT N'Ô tô',
    entry_image_url NVARCHAR(255) NULL,
    exit_image_url NVARCHAR(255) NULL,
    fee_amount DECIMAL(12,2) NOT NULL DEFAULT 0,
    CONSTRAINT FK_parking_logs_slots FOREIGN KEY (slot_id) REFERENCES dbo.slots(slot_id),
    CONSTRAINT CK_parking_logs_status CHECK (status IN ('PARKED', 'COMPLETED'))
);
GO

CREATE TABLE dbo.camera_events (
    event_id INT IDENTITY(1,1) PRIMARY KEY,
    camera_id VARCHAR(20) NOT NULL,
    event_type VARCHAR(20) NOT NULL,
    license_plate NVARCHAR(20) NULL,
    vehicle_type NVARCHAR(30) NULL,
    image_url NVARCHAR(255) NULL,
    ai_confidence DECIMAL(5,2) NULL,
    decision VARCHAR(20) NULL,
    match_status VARCHAR(20) NULL,
    created_at DATETIME NOT NULL DEFAULT GETDATE(),
    CONSTRAINT CK_camera_events_event_type CHECK (event_type IN ('ENTRY', 'EXIT')),
    CONSTRAINT CK_camera_events_decision CHECK (decision IS NULL OR decision IN ('OPEN', 'CLOSE')),
    CONSTRAINT CK_camera_events_match_status CHECK (
        match_status IS NULL OR match_status IN ('MATCH', 'MISMATCH', 'ACCEPTED', 'FULL', 'UNKNOWN')
    )
);
GO

INSERT INTO dbo.slots (slot_number, sensor_distance_cm, status, last_sensor_time)
VALUES
('A01', 18.50, 'OCCUPIED', DATEADD(MINUTE, -2, GETDATE())),
('A02', 135.00, 'AVAILABLE', DATEADD(MINUTE, -4, GETDATE())),
('A03', 142.30, 'AVAILABLE', DATEADD(MINUTE, -3, GETDATE())),
('A04', 21.20, 'OCCUPIED', DATEADD(MINUTE, -1, GETDATE())),
('B01', 130.50, 'AVAILABLE', DATEADD(MINUTE, -6, GETDATE())),
('B02', 19.40, 'OCCUPIED', DATEADD(MINUTE, -1, GETDATE())),
('B03', 128.20, 'AVAILABLE', DATEADD(MINUTE, -5, GETDATE())),
('B04', 24.60, 'OCCUPIED', DATEADD(MINUTE, -2, GETDATE())),
('C01', 140.00, 'AVAILABLE', DATEADD(MINUTE, -3, GETDATE())),
('C02', 137.80, 'AVAILABLE', DATEADD(MINUTE, -4, GETDATE())),
('C03', 22.80, 'OCCUPIED', DATEADD(MINUTE, -1, GETDATE())),
('C04', 145.70, 'AVAILABLE', DATEADD(MINUTE, -5, GETDATE()));
GO

INSERT INTO dbo.parking_logs
(license_plate, rfid_card_id, slot_id, entry_time, exit_time, status, vehicle_type, entry_image_url, exit_image_url, fee_amount)
VALUES
(N'71AA-23210', 'FPT-SE201631', 1, DATEADD(HOUR, -5, GETDATE()), NULL, 'PARKED', N'Ô tô', 'images/entry_71AA23210.jpg', NULL, 0),
(N'59AB-48321', 'FPT-SE194059', 4, DATEADD(HOUR, -3, GETDATE()), NULL, 'PARKED', N'Ô tô', 'images/entry_59AB48321.jpg', NULL, 0),
(N'51F-889.10', 'FPT-SE192594', 6, DATEADD(HOUR, -2, GETDATE()), NULL, 'PARKED', N'Xe máy', 'images/entry_51F88910.jpg', NULL, 0),
(N'67AA-34345', 'FPT-SE192134', 8, DATEADD(MINUTE, -95, GETDATE()), NULL, 'PARKED', N'Xe máy', 'images/entry_67AA34345.jpg', NULL, 0),
(N'55BB-35453', 'FPT-IA170001', 11, DATEADD(MINUTE, -40, GETDATE()), NULL, 'PARKED', N'Ô tô', 'images/entry_55BB35453.jpg', NULL, 0),

(N'60A-112.45', 'FPT-BA180011', 2, DATEADD(HOUR, -7, GETDATE()), DATEADD(HOUR, -6, GETDATE()), 'COMPLETED', N'Ô tô', 'images/entry_60A11245.jpg', 'images/exit_60A11245.jpg', 10000),
(N'43C-992.11', 'FPT-IT180022', 3, DATEADD(HOUR, -6, GETDATE()), DATEADD(HOUR, -4, GETDATE()), 'COMPLETED', N'Ô tô', 'images/entry_43C99211.jpg', 'images/exit_43C99211.jpg', 20000),
(N'51X-721.88', 'FPT-GD190033', 5, DATEADD(HOUR, -4, GETDATE()), DATEADD(HOUR, -3, GETDATE()), 'COMPLETED', N'Xe máy', 'images/entry_51X72188.jpg', 'images/exit_51X72188.jpg', 5000),
(N'62B-678.90', 'FPT-SE200044', 7, DATEADD(HOUR, -3, GETDATE()), DATEADD(HOUR, -1, GETDATE()), 'COMPLETED', N'Ô tô', 'images/entry_62B67890.jpg', 'images/exit_62B67890.jpg', 20000),
(N'72D-456.12', 'FPT-AI210055', 9, DATEADD(HOUR, -2, GETDATE()), DATEADD(MINUTE, -30, GETDATE()), 'COMPLETED', N'Xe máy', 'images/entry_72D45612.jpg', 'images/exit_72D45612.jpg', 5000),
(N'50H-135.79', 'FPT-SE220066', 10, DATEADD(DAY, -1, DATEADD(HOUR, -5, GETDATE())), DATEADD(DAY, -1, DATEADD(HOUR, -3, GETDATE())), 'COMPLETED', N'Ô tô', 'images/entry_50H13579.jpg', 'images/exit_50H13579.jpg', 20000);
GO

SELECT * FROM dbo.slots ORDER BY slot_number;
SELECT * FROM dbo.parking_logs ORDER BY entry_time DESC;
GO
