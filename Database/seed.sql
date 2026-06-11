/* =========================================================
   Smart Parking System with AI and Dashboard
   Seed Data Script
   File: seed.sql
   Purpose:
   - Insert realistic demo data for all tables in SmartParkingDB.
   - Designed for the revised ERD schema:
     Gates, DashboardUsers, VehicleWhitelist, Cameras, Sensors,
     ParkingEvents, AiDetections, ImageRecords, GateCommands,
     DeviceHeartbeats.
   - Run this script AFTER running smart_parking_revised_erd_script.sql.

   Main seed volume:
   - 4 gates
   - 7 dashboard users
   - 150 whitelist vehicles
   - 4 cameras
   - 4 sensors
   - 1,500 parking events
   - 1,500 AI detections
   - 1,500 image records
   - ~2,000+ gate commands
   - ~1,000+ device heartbeat records

   To generate more data, change:
   - @VehicleTarget
   - @TotalEvents
   - @HeartbeatCycles
   ========================================================= */

USE SmartParkingDB;
GO

SET NOCOUNT ON;
GO

/* =========================================================
   0. Clean old seed data
   ========================================================= */

DELETE FROM dbo.GateCommands;
DELETE FROM dbo.ImageRecords;
DELETE FROM dbo.AiDetections;
DELETE FROM dbo.ParkingEvents;
DELETE FROM dbo.Sensors;
DELETE FROM dbo.Cameras;
DELETE FROM dbo.DeviceHeartbeats;
DELETE FROM dbo.VehicleWhitelist;
DELETE FROM dbo.DashboardUsers;
DELETE FROM dbo.Gates;
GO

DBCC CHECKIDENT ('dbo.GateCommands', RESEED, 0) WITH NO_INFOMSGS;
DBCC CHECKIDENT ('dbo.ImageRecords', RESEED, 0) WITH NO_INFOMSGS;
DBCC CHECKIDENT ('dbo.AiDetections', RESEED, 0) WITH NO_INFOMSGS;
DBCC CHECKIDENT ('dbo.ParkingEvents', RESEED, 0) WITH NO_INFOMSGS;
DBCC CHECKIDENT ('dbo.Sensors', RESEED, 0) WITH NO_INFOMSGS;
DBCC CHECKIDENT ('dbo.Cameras', RESEED, 0) WITH NO_INFOMSGS;
DBCC CHECKIDENT ('dbo.DeviceHeartbeats', RESEED, 0) WITH NO_INFOMSGS;
DBCC CHECKIDENT ('dbo.VehicleWhitelist', RESEED, 0) WITH NO_INFOMSGS;
DBCC CHECKIDENT ('dbo.DashboardUsers', RESEED, 0) WITH NO_INFOMSGS;
DBCC CHECKIDENT ('dbo.Gates', RESEED, 0) WITH NO_INFOMSGS;
GO

/* =========================================================
   1. Seed Gates
   ========================================================= */

INSERT INTO dbo.Gates (GateCode, GateName, Direction, Status)
VALUES
('GATE_IN_01',  N'Entrance Gate 01', 'IN',  'CLOSED'),
('GATE_OUT_01', N'Exit Gate 01',     'OUT', 'CLOSED'),
('GATE_IN_02',  N'Entrance Gate 02', 'IN',  'CLOSED'),
('GATE_OUT_02', N'Exit Gate 02',     'OUT', 'CLOSED');
GO

/* =========================================================
   2. Seed DashboardUsers
   PasswordHash values are demo placeholders only.
   Real systems must use BCrypt/Argon2/PBKDF2 hashing.
   ========================================================= */

INSERT INTO dbo.DashboardUsers (Username, PasswordHash, Role)
VALUES
('admin',     N'DEMO_HASH_ADMIN_001_DO_NOT_USE_PLAINTEXT', 'ADMIN'),
('manager',   N'DEMO_HASH_MANAGER_002_DO_NOT_USE_PLAINTEXT', 'ADMIN'),
('staff01',   N'DEMO_HASH_STAFF01_003_DO_NOT_USE_PLAINTEXT', 'STAFF'),
('staff02',   N'DEMO_HASH_STAFF02_004_DO_NOT_USE_PLAINTEXT', 'STAFF'),
('staff03',   N'DEMO_HASH_STAFF03_005_DO_NOT_USE_PLAINTEXT', 'STAFF'),
('operator01',N'DEMO_HASH_OPERATOR01_006_DO_NOT_USE_PLAINTEXT', 'STAFF'),
('security01',N'DEMO_HASH_SECURITY01_007_DO_NOT_USE_PLAINTEXT', 'STAFF');
GO

/* =========================================================
   3. Seed VehicleWhitelist
   ========================================================= */

DECLARE @VehicleTarget INT = 150;
DECLARE @i INT = 1;

WHILE @i <= @VehicleTarget
BEGIN
    INSERT INTO dbo.VehicleWhitelist
    (
        PlateNumber,
        OwnerName,
        VehicleType,
        IsAllowed,
        CreatedAt
    )
    VALUES
    (
        CONCAT(
            CASE WHEN @i % 3 = 0 THEN '51' ELSE '59' END,
            CHAR(65 + (@i % 4)),
            RIGHT('00000' + CAST(10000 + @i AS VARCHAR(10)), 5)
        ),
        CONCAT(N'Owner ', RIGHT('000' + CAST(@i AS NVARCHAR(10)), 3)),
        CASE
            WHEN @i % 5 = 0 THEN 'TRUCK'
            WHEN @i % 3 = 0 THEN 'MOTORBIKE'
            ELSE 'CAR'
        END,
        CASE
            WHEN @i % 17 = 0 THEN 0
            WHEN @i % 29 = 0 THEN 0
            ELSE 1
        END,
        DATEADD(DAY, -@i, SYSDATETIME())
    );

    SET @i += 1;
END;
GO

/* =========================================================
   4. Seed Cameras
   ========================================================= */

INSERT INTO dbo.Cameras (CameraCode, GateId, IpAddress, Location, IsActive)
VALUES
('CAM_IN_01',  (SELECT GateId FROM dbo.Gates WHERE GateCode = 'GATE_IN_01'),  '192.168.1.101', N'Entrance 01 ESP32-CAM', 1),
('CAM_OUT_01', (SELECT GateId FROM dbo.Gates WHERE GateCode = 'GATE_OUT_01'), '192.168.1.102', N'Exit 01 ESP32-CAM',     1),
('CAM_IN_02',  (SELECT GateId FROM dbo.Gates WHERE GateCode = 'GATE_IN_02'),  '192.168.1.103', N'Entrance 02 ESP32-CAM', 1),
('CAM_OUT_02', (SELECT GateId FROM dbo.Gates WHERE GateCode = 'GATE_OUT_02'), '192.168.1.104', N'Exit 02 ESP32-CAM',     1);
GO

/* =========================================================
   5. Seed Sensors
   ========================================================= */

INSERT INTO dbo.Sensors
(
    SensorCode,
    GateId,
    ArduinoRole,
    SensorType,
    TriggerDistanceCm,
    LastDistanceCm,
    LastUpdatedAt
)
VALUES
('SENSOR_IN_01',  (SELECT GateId FROM dbo.Gates WHERE GateCode = 'GATE_IN_01'),  'SLAVE', 'ULTRASONIC', 20, 18.5, SYSDATETIME()),
('SENSOR_OUT_01', (SELECT GateId FROM dbo.Gates WHERE GateCode = 'GATE_OUT_01'), 'SLAVE', 'ULTRASONIC', 20, 25.2, SYSDATETIME()),
('SENSOR_IN_02',  (SELECT GateId FROM dbo.Gates WHERE GateCode = 'GATE_IN_02'),  'SLAVE', 'ULTRASONIC', 20, 16.9, SYSDATETIME()),
('SENSOR_OUT_02', (SELECT GateId FROM dbo.Gates WHERE GateCode = 'GATE_OUT_02'), 'SLAVE', 'ULTRASONIC', 20, 30.1, SYSDATETIME());
GO

/* =========================================================
   6. Seed ParkingEvents + AiDetections + ImageRecords + GateCommands
   ========================================================= */

DECLARE @TotalEvents INT = 1500;
DECLARE @EventIndex INT = 1;
DECLARE @VehicleCount INT = (SELECT COUNT(*) FROM dbo.VehicleWhitelist);

DECLARE @GateCode VARCHAR(50);
DECLARE @Direction VARCHAR(10);
DECLARE @GateId INT;
DECLARE @CameraId INT;
DECLARE @SensorId INT;
DECLARE @VehicleId INT;
DECLARE @PlateNumber VARCHAR(20);
DECLARE @VehicleType VARCHAR(30);
DECLARE @IsAllowed BIT;

DECLARE @AiStatus VARCHAR(20);
DECLARE @ReviewStatus VARCHAR(20);
DECLARE @GateDecision VARCHAR(20);
DECLARE @GateOpened BIT;
DECLARE @Note NVARCHAR(255);

DECLARE @EventTime DATETIME2;
DECLARE @EventCode VARCHAR(50);
DECLARE @EventId INT;

DECLARE @VehicleConfidence FLOAT;
DECLARE @PlateDetected BIT;
DECLARE @PlateConfidence FLOAT;
DECLARE @IsValidVehicle BIT;
DECLARE @InferenceTimeMs INT;

DECLARE @DashboardUserId INT;
DECLARE @CloseCommandDelaySeconds INT;

WHILE @EventIndex <= @TotalEvents
BEGIN
    SET @EventTime = DATEADD(MINUTE, @EventIndex * 5, CAST('2026-06-01T06:00:00' AS DATETIME2));
    SET @EventCode = CONCAT('EVT_SEED_', RIGHT('000000' + CAST(@EventIndex AS VARCHAR(10)), 6));

    SET @Direction = CASE WHEN @EventIndex % 2 = 1 THEN 'IN' ELSE 'OUT' END;

    IF @Direction = 'IN'
    BEGIN
        SET @GateCode = CASE WHEN @EventIndex % 4 = 1 THEN 'GATE_IN_01' ELSE 'GATE_IN_02' END;
    END
    ELSE
    BEGIN
        SET @GateCode = CASE WHEN @EventIndex % 4 = 0 THEN 'GATE_OUT_01' ELSE 'GATE_OUT_02' END;
    END;

    SELECT @GateId = GateId
    FROM dbo.Gates
    WHERE GateCode = @GateCode;

    SELECT TOP 1 @CameraId = CameraId
    FROM dbo.Cameras
    WHERE GateId = @GateId
    ORDER BY CameraId;

    SELECT TOP 1 @SensorId = SensorId
    FROM dbo.Sensors
    WHERE GateId = @GateId
    ORDER BY SensorId;

    SET @VehicleId = NULL;
    SET @PlateNumber = NULL;
    SET @VehicleType = NULL;
    SET @IsAllowed = 0;

    /* Case A: no vehicle detected */
    IF @EventIndex % 41 = 0
    BEGIN
        SET @AiStatus = 'NO_VEHICLE';
        SET @ReviewStatus = 'REJECTED';
        SET @GateDecision = 'DENY';
        SET @GateOpened = 0;
        SET @Note = N'Sensor was triggered but AI detected no valid vehicle.';
    END
    /* Case B: unreadable plate / low confidence */
    ELSE IF @EventIndex % 17 = 0
    BEGIN
        SET @AiStatus = 'FAILED';
        SET @ReviewStatus = 'MANUAL_REVIEW';
        SET @GateDecision = 'MANUAL';
        SET @GateOpened = 0;
        SET @Note = N'Low confidence or unreadable license plate; manual review required.';
    END
    /* Case C: valid OCR / whitelist check */
    ELSE
    BEGIN
        SELECT
            @VehicleId = VehicleId,
            @PlateNumber = PlateNumber,
            @VehicleType = VehicleType,
            @IsAllowed = IsAllowed
        FROM
        (
            SELECT
                ROW_NUMBER() OVER (ORDER BY VehicleId) AS RowNo,
                VehicleId,
                PlateNumber,
                VehicleType,
                IsAllowed
            FROM dbo.VehicleWhitelist
        ) AS V
        WHERE V.RowNo = ((@EventIndex - 1) % @VehicleCount) + 1;

        SET @AiStatus = 'DETECTED';

        IF @IsAllowed = 1
        BEGIN
            SET @ReviewStatus = 'APPROVED';
            SET @GateDecision = 'OPEN';
            SET @GateOpened = 1;
            SET @Note = N'Whitelist vehicle detected and gate opened.';
        END
        ELSE
        BEGIN
            SET @ReviewStatus = 'REJECTED';
            SET @GateDecision = 'DENY';
            SET @GateOpened = 0;
            SET @Note = N'Vehicle detected but not allowed by whitelist.';
        END
    END;

    INSERT INTO dbo.ParkingEvents
    (
        EventCode,
        GateId,
        CameraId,
        SensorId,
        VehicleId,
        Direction,
        EventTime,
        PlateNumber,
        VehicleType,
        AiStatus,
        ReviewStatus,
        GateDecision,
        GateOpened,
        Note,
        CreatedAt
    )
    VALUES
    (
        @EventCode,
        @GateId,
        @CameraId,
        @SensorId,
        @VehicleId,
        @Direction,
        @EventTime,
        @PlateNumber,
        @VehicleType,
        @AiStatus,
        @ReviewStatus,
        @GateDecision,
        @GateOpened,
        @Note,
        @EventTime
    );

    SET @EventId = CONVERT(INT, SCOPE_IDENTITY());

    SET @VehicleConfidence =
        CASE
            WHEN @AiStatus = 'NO_VEHICLE' THEN NULL
            WHEN @AiStatus = 'FAILED' THEN CAST((35 + (@EventIndex % 20)) AS FLOAT) / 100.0
            ELSE CAST((70 + (@EventIndex % 29)) AS FLOAT) / 100.0
        END;

    SET @PlateDetected = CASE WHEN @PlateNumber IS NULL THEN 0 ELSE 1 END;

    SET @PlateConfidence =
        CASE
            WHEN @PlateNumber IS NULL THEN NULL
            WHEN @AiStatus = 'FAILED' THEN CAST((30 + (@EventIndex % 25)) AS FLOAT) / 100.0
            ELSE CAST((65 + (@EventIndex % 31)) AS FLOAT) / 100.0
        END;

    SET @IsValidVehicle = CASE WHEN @AiStatus = 'DETECTED' AND @IsAllowed = 1 THEN 1 ELSE 0 END;
    SET @InferenceTimeMs = 80 + (@EventIndex % 180);

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
        RawJson,
        CreatedAt
    )
    VALUES
    (
        @EventId,
        'YOLO-LicensePlate-Demo',
        CASE WHEN @AiStatus = 'NO_VEHICLE' THEN NULL ELSE LOWER(ISNULL(@VehicleType, 'unknown')) END,
        @VehicleConfidence,
        @PlateDetected,
        @PlateNumber,
        @PlateConfidence,
        @IsValidVehicle,
        @InferenceTimeMs,
        CONCAT(
            N'{"eventCode":"', @EventCode,
            N'","aiStatus":"', @AiStatus,
            N'","plate":"', ISNULL(@PlateNumber, 'UNKNOWN'),
            N'","gateDecision":"', @GateDecision,
            N'","inferenceTimeMs":', @InferenceTimeMs,
            N'}'
        ),
        DATEADD(SECOND, 1, @EventTime)
    );

    INSERT INTO dbo.ImageRecords
    (
        EventId,
        OriginalImagePath,
        DetectedImagePath,
        UploadedAt
    )
    VALUES
    (
        @EventId,
        CONCAT(N'/uploads/original/', @EventCode, N'.jpg'),
        CASE
            WHEN @AiStatus = 'DETECTED'
                THEN CONCAT(N'/uploads/detected/', @EventCode, N'_detected.jpg')
            ELSE NULL
        END,
        @EventTime
    );

    /* Gate command logic:
       - OPEN approved events: AI sends OPEN and CLOSE commands.
       - MANUAL events: Dashboard sends one pending OPEN command.
       - DENY events: no physical gate command is generated.
    */
    IF @GateDecision = 'OPEN'
    BEGIN
        INSERT INTO dbo.GateCommands
        (
            GateId,
            EventId,
            Command,
            Source,
            Status,
            RequestedBy,
            RequestedByUserId,
            RequestedAt,
            AcknowledgedAt
        )
        VALUES
        (
            @GateId,
            @EventId,
            'OPEN',
            'AI',
            'ACK',
            N'AI Module',
            NULL,
            DATEADD(SECOND, 2, @EventTime),
            DATEADD(SECOND, 3, @EventTime)
        );

        SET @CloseCommandDelaySeconds = 8 + (@EventIndex % 12);

        INSERT INTO dbo.GateCommands
        (
            GateId,
            EventId,
            Command,
            Source,
            Status,
            RequestedBy,
            RequestedByUserId,
            RequestedAt,
            AcknowledgedAt
        )
        VALUES
        (
            @GateId,
            @EventId,
            'CLOSE',
            'AI',
            'ACK',
            N'AI Module',
            NULL,
            DATEADD(SECOND, @CloseCommandDelaySeconds, @EventTime),
            DATEADD(SECOND, @CloseCommandDelaySeconds + 1, @EventTime)
        );
    END
    ELSE IF @GateDecision = 'MANUAL'
    BEGIN
        SELECT TOP 1 @DashboardUserId = UserId
        FROM dbo.DashboardUsers
        WHERE Role = 'STAFF'
        ORDER BY UserId;

        INSERT INTO dbo.GateCommands
        (
            GateId,
            EventId,
            Command,
            Source,
            Status,
            RequestedBy,
            RequestedByUserId,
            RequestedAt,
            AcknowledgedAt
        )
        VALUES
        (
            @GateId,
            @EventId,
            'OPEN',
            'DASHBOARD',
            'PENDING',
            N'staff01',
            @DashboardUserId,
            DATEADD(SECOND, 5, @EventTime),
            NULL
        );
    END;

    SET @EventIndex += 1;
END;
GO

/* =========================================================
   7. Seed DeviceHeartbeats
   Generic monitoring logs for cameras, sensors, and Arduino.
   ========================================================= */

DECLARE @HeartbeatCycles INT = 96;
DECLARE @Cycle INT = 0;
DECLARE @LastSeenAt DATETIME2;
DECLARE @HeartbeatStatus VARCHAR(20);
DECLARE @Message NVARCHAR(255);

WHILE @Cycle < @HeartbeatCycles
BEGIN
    SET @LastSeenAt = DATEADD(MINUTE, -(@Cycle * 10), SYSDATETIME());

    SET @HeartbeatStatus =
        CASE
            WHEN @Cycle % 37 = 0 THEN 'ERROR'
            WHEN @Cycle % 19 = 0 THEN 'OFFLINE'
            ELSE 'ONLINE'
        END;

    SET @Message =
        CASE
            WHEN @HeartbeatStatus = 'ONLINE' THEN N'Device heartbeat received.'
            WHEN @HeartbeatStatus = 'OFFLINE' THEN N'Device missed recent heartbeat.'
            ELSE N'Device reported abnormal status.'
        END;

    INSERT INTO dbo.DeviceHeartbeats
    (
        DeviceType,
        DeviceCode,
        Status,
        IpAddress,
        Message,
        LastSeenAt
    )
    SELECT
        'CAMERA',
        CameraCode,
        @HeartbeatStatus,
        IpAddress,
        @Message,
        @LastSeenAt
    FROM dbo.Cameras;

    INSERT INTO dbo.DeviceHeartbeats
    (
        DeviceType,
        DeviceCode,
        Status,
        IpAddress,
        Message,
        LastSeenAt
    )
    SELECT
        'SENSOR',
        SensorCode,
        @HeartbeatStatus,
        NULL,
        @Message,
        @LastSeenAt
    FROM dbo.Sensors;

    INSERT INTO dbo.DeviceHeartbeats
    (
        DeviceType,
        DeviceCode,
        Status,
        IpAddress,
        Message,
        LastSeenAt
    )
    VALUES
    ('ARDUINO', 'ARDUINO_MASTER', @HeartbeatStatus, NULL, @Message, @LastSeenAt),
    ('ARDUINO', 'ARDUINO_SLAVE_IN', @HeartbeatStatus, NULL, @Message, @LastSeenAt),
    ('ARDUINO', 'ARDUINO_SLAVE_OUT', @HeartbeatStatus, NULL, @Message, @LastSeenAt);

    SET @Cycle += 1;
END;
GO

/* =========================================================
   8. Update current gate status for realistic final state
   ========================================================= */

UPDATE dbo.Gates
SET Status = 'CLOSED';
GO

/* =========================================================
   9. Summary count for screenshot evidence
   ========================================================= */

SELECT 'Gates' AS TableName, COUNT(*) AS TotalRows FROM dbo.Gates
UNION ALL
SELECT 'DashboardUsers', COUNT(*) FROM dbo.DashboardUsers
UNION ALL
SELECT 'VehicleWhitelist', COUNT(*) FROM dbo.VehicleWhitelist
UNION ALL
SELECT 'Cameras', COUNT(*) FROM dbo.Cameras
UNION ALL
SELECT 'Sensors', COUNT(*) FROM dbo.Sensors
UNION ALL
SELECT 'ParkingEvents', COUNT(*) FROM dbo.ParkingEvents
UNION ALL
SELECT 'AiDetections', COUNT(*) FROM dbo.AiDetections
UNION ALL
SELECT 'ImageRecords', COUNT(*) FROM dbo.ImageRecords
UNION ALL
SELECT 'GateCommands', COUNT(*) FROM dbo.GateCommands
UNION ALL
SELECT 'DeviceHeartbeats', COUNT(*) FROM dbo.DeviceHeartbeats;
GO

/* =========================================================
   10. Dashboard-ready sample queries
   ========================================================= */

SELECT TOP 20 *
FROM dbo.ParkingEvents
ORDER BY EventTime DESC;
GO

SELECT
    Direction,
    AiStatus,
    ReviewStatus,
    GateDecision,
    COUNT(*) AS TotalEvents
FROM dbo.ParkingEvents
GROUP BY Direction, AiStatus, ReviewStatus, GateDecision
ORDER BY Direction, AiStatus, ReviewStatus, GateDecision;
GO

SELECT TOP 20
    pe.EventCode,
    pe.EventTime,
    pe.Direction,
    g.GateCode,
    pe.PlateNumber,
    pe.VehicleType,
    pe.AiStatus,
    pe.ReviewStatus,
    pe.GateDecision,
    ad.VehicleConfidence,
    ad.PlateConfidence,
    ir.OriginalImagePath,
    ir.DetectedImagePath
FROM dbo.ParkingEvents pe
LEFT JOIN dbo.Gates g
    ON pe.GateId = g.GateId
LEFT JOIN dbo.AiDetections ad
    ON pe.EventId = ad.EventId
LEFT JOIN dbo.ImageRecords ir
    ON pe.EventId = ir.EventId
ORDER BY pe.EventTime DESC;
GO

SELECT TOP 20
    gc.CommandId,
    g.GateCode,
    pe.EventCode,
    gc.Command,
    gc.Source,
    gc.Status,
    gc.RequestedBy,
    du.Username AS RequestedByUsername,
    gc.RequestedAt,
    gc.AcknowledgedAt
FROM dbo.GateCommands gc
LEFT JOIN dbo.Gates g
    ON gc.GateId = g.GateId
LEFT JOIN dbo.ParkingEvents pe
    ON gc.EventId = pe.EventId
LEFT JOIN dbo.DashboardUsers du
    ON gc.RequestedByUserId = du.UserId
ORDER BY gc.RequestedAt DESC;
GO

SELECT TOP 20
    DeviceType,
    DeviceCode,
    Status,
    IpAddress,
    Message,
    LastSeenAt
FROM dbo.DeviceHeartbeats
ORDER BY LastSeenAt DESC;
GO
