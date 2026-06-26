"""
parking_service.py

Business logic layer:
- Query dashboard data from SQL Server.
- Register entry event.
- Register exit event.
- Update slot status.
- Insert AI/camera event logs.

This keeps main.py clean.
"""

from datetime import datetime
from decimal import Decimal
from typing import Any, Dict, List, Optional

from database import get_connection, rows_to_dicts


def _to_json_value(value: Any) -> Any:
    if isinstance(value, datetime):
        return value.isoformat()
    if isinstance(value, Decimal):
        return float(value)
    return value


def _serialize_row(row: Dict[str, Any]) -> Dict[str, Any]:
    return {key: _to_json_value(value) for key, value in row.items()}


def _serialize_rows(rows: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
    return [_serialize_row(row) for row in rows]


def _resolve_image_url(path: Optional[str]) -> Optional[str]:
    """
    Database image path convention:
    - existing mock: images/entry_xxx.jpg -> /static/images/entry_xxx.jpg
    - uploaded: uploads/entry/xxx.jpg -> /static/uploads/entry/xxx.jpg
    """
    if not path:
        return None

    normalized = path.replace("\\", "/")

    if normalized.startswith("http://") or normalized.startswith("https://"):
        return normalized

    if normalized.startswith("/static/"):
        return normalized

    if normalized.startswith("static/"):
        return "/" + normalized

    return "/static/" + normalized


def _attach_image_urls(row: Dict[str, Any]) -> Dict[str, Any]:
    row = dict(row)
    row["entry_image_full_url"] = _resolve_image_url(row.get("entry_image_url"))
    row["exit_image_full_url"] = _resolve_image_url(row.get("exit_image_url"))
    return row


def get_slots() -> List[Dict[str, Any]]:
    sql = """
        SELECT slot_id, slot_number, sensor_distance_cm, status, last_sensor_time
        FROM dbo.slots
        ORDER BY slot_number
    """

    with get_connection() as conn:
        cursor = conn.cursor()
        cursor.execute(sql)
        return _serialize_rows(rows_to_dicts(cursor))


def get_parking_logs(limit: int = 50) -> List[Dict[str, Any]]:
    sql = """
        SELECT TOP (?)
            pl.log_id,
            pl.license_plate,
            pl.rfid_card_id,
            pl.slot_id,
            s.slot_number,
            pl.entry_time,
            pl.exit_time,
            pl.status,
            pl.vehicle_type,
            pl.entry_image_url,
            pl.exit_image_url,
            pl.fee_amount
        FROM dbo.parking_logs pl
        INNER JOIN dbo.slots s ON pl.slot_id = s.slot_id
        ORDER BY pl.entry_time DESC
    """

    with get_connection() as conn:
        cursor = conn.cursor()
        cursor.execute(sql, limit)
        rows = rows_to_dicts(cursor)

    rows = [_attach_image_urls(row) for row in rows]
    return _serialize_rows(rows)


def get_parked_logs() -> List[Dict[str, Any]]:
    sql = """
        SELECT
            pl.log_id,
            pl.license_plate,
            pl.rfid_card_id,
            pl.slot_id,
            s.slot_number,
            pl.entry_time,
            pl.exit_time,
            pl.status,
            pl.vehicle_type,
            pl.entry_image_url,
            pl.exit_image_url,
            pl.fee_amount
        FROM dbo.parking_logs pl
        INNER JOIN dbo.slots s ON pl.slot_id = s.slot_id
        WHERE pl.status = 'PARKED'
        ORDER BY pl.entry_time DESC
    """

    with get_connection() as conn:
        cursor = conn.cursor()
        cursor.execute(sql)
        rows = rows_to_dicts(cursor)

    rows = [_attach_image_urls(row) for row in rows]
    return _serialize_rows(rows)


def get_completed_logs(limit: int = 10) -> List[Dict[str, Any]]:
    sql = """
        SELECT TOP (?)
            pl.log_id,
            pl.license_plate,
            pl.rfid_card_id,
            pl.slot_id,
            s.slot_number,
            pl.entry_time,
            pl.exit_time,
            pl.status,
            pl.vehicle_type,
            pl.entry_image_url,
            pl.exit_image_url,
            pl.fee_amount
        FROM dbo.parking_logs pl
        INNER JOIN dbo.slots s ON pl.slot_id = s.slot_id
        WHERE pl.status = 'COMPLETED'
        ORDER BY pl.exit_time DESC
    """

    with get_connection() as conn:
        cursor = conn.cursor()
        cursor.execute(sql, limit)
        rows = rows_to_dicts(cursor)

    rows = [_attach_image_urls(row) for row in rows]
    return _serialize_rows(rows)


def _get_scalar(sql: str, *params) -> int:
    with get_connection() as conn:
        cursor = conn.cursor()
        cursor.execute(sql, *params)
        value = cursor.fetchone()[0]
        return int(value or 0)


def get_dashboard_data() -> Dict[str, Any]:
    parking_logs = get_parking_logs(limit=20)
    parked_logs = get_parked_logs()
    completed_logs = get_completed_logs(limit=20)
    slots = get_slots()

    latest_entry = parking_logs[0] if parking_logs else None
    latest_exit = completed_logs[0] if completed_logs else None

    entries_today = _get_scalar("""
        SELECT COUNT(*)
        FROM dbo.parking_logs
        WHERE CAST(entry_time AS DATE) = CAST(GETDATE() AS DATE)
    """)

    exits_today = _get_scalar("""
        SELECT COUNT(*)
        FROM dbo.parking_logs
        WHERE exit_time IS NOT NULL
          AND CAST(exit_time AS DATE) = CAST(GETDATE() AS DATE)
    """)

    available_slots = len([slot for slot in slots if slot["status"] == "AVAILABLE"])
    occupied_slots = len([slot for slot in slots if slot["status"] == "OCCUPIED"])

    # TODO: Replace this mock gate status with real Arduino/ESP32 status.
    gate_status = "OPEN"

    plate_match = bool(latest_exit and latest_exit.get("license_plate"))

    return {
        "systemStatus": "ONLINE",
        "serverTime": datetime.now().isoformat(),
        "gateStatus": gate_status,

        "vehiclesInside": len(parked_logs),
        "entriesToday": entries_today,
        "exitsToday": exits_today,
        "totalSlots": len(slots),
        "availableSlots": available_slots,
        "occupiedSlots": occupied_slots,

        "latestEntry": latest_entry,
        "latestExit": latest_exit,
        "plateMatch": plate_match,

        "recentEntries": parking_logs[:3],
        "recentExits": completed_logs[:3],
        "parkedLogs": parked_logs,
        "parkingLogs": parking_logs,
        "slots": slots,
    }


def _find_available_slot(cursor) -> Optional[int]:
    cursor.execute("""
        SELECT TOP 1 slot_id
        FROM dbo.slots
        WHERE status = 'AVAILABLE'
        ORDER BY slot_number
    """)
    row = cursor.fetchone()
    return int(row[0]) if row else None


def _calculate_fee(vehicle_type: str, entry_time: datetime, exit_time: datetime) -> int:
    duration_minutes = max(1, int((exit_time - entry_time).total_seconds() / 60))
    started_hours = (duration_minutes + 59) // 60

    if vehicle_type and "máy" in vehicle_type.lower():
        rate = 5000
    else:
        rate = 10000

    return started_hours * rate


def _insert_camera_event(
    cursor,
    camera_id: str,
    event_type: str,
    license_plate: str,
    vehicle_type: str,
    image_url: str,
    ai_confidence: float,
    decision: str,
    match_status: str
):
    """
    camera_events is for raw AI/camera logs.
    If you do not want this table, remove this function and its calls.
    """
    cursor.execute("""
        INSERT INTO dbo.camera_events
        (camera_id, event_type, license_plate, vehicle_type, image_url,
         ai_confidence, decision, match_status, created_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, GETDATE())
    """, camera_id, event_type, license_plate, vehicle_type, image_url,
         ai_confidence, decision, match_status)


def register_entry(
    license_plate: str,
    vehicle_type: str,
    image_url: str,
    ai_confidence: float = 0.0,
    slot_id: Optional[int] = None,
    rfid_card_id: Optional[str] = None,
) -> Dict[str, Any]:
    """
    Register a vehicle entering the parking lot.
    """
    with get_connection() as conn:
        cursor = conn.cursor()

        if slot_id is None:
            slot_id = _find_available_slot(cursor)

        if slot_id is None:
            decision = "CLOSE"
            _insert_camera_event(
                cursor, "ENTRY_CAM", "ENTRY", license_plate, vehicle_type,
                image_url, ai_confidence, decision, "FULL"
            )
            return {
                "decision": decision,
                "message": "No available parking slot",
                "license_plate": license_plate,
                "vehicle_type": vehicle_type,
            }

        cursor.execute("""
            INSERT INTO dbo.parking_logs
            (license_plate, rfid_card_id, slot_id, entry_time, exit_time,
             status, vehicle_type, entry_image_url, exit_image_url, fee_amount)
            VALUES (?, ?, ?, GETDATE(), NULL, 'PARKED', ?, ?, NULL, 0)
        """, license_plate, rfid_card_id, slot_id, vehicle_type, image_url)

        cursor.execute("""
            UPDATE dbo.slots
            SET status = 'OCCUPIED',
                sensor_distance_cm = 20.00,
                last_sensor_time = GETDATE()
            WHERE slot_id = ?
        """, slot_id)

        _insert_camera_event(
            cursor, "ENTRY_CAM", "ENTRY", license_plate, vehicle_type,
            image_url, ai_confidence, "OPEN", "ACCEPTED"
        )

    return {
        "decision": "OPEN",
        "message": "Entry accepted",
        "license_plate": license_plate,
        "vehicle_type": vehicle_type,
        "slot_id": slot_id,
    }


def register_exit(
    license_plate: str,
    vehicle_type: str,
    image_url: str,
    ai_confidence: float = 0.0,
) -> Dict[str, Any]:
    """
    Register a vehicle leaving the parking lot.
    """
    with get_connection() as conn:
        cursor = conn.cursor()

        cursor.execute("""
            SELECT TOP 1 log_id, slot_id, entry_time, vehicle_type
            FROM dbo.parking_logs
            WHERE license_plate = ?
              AND status = 'PARKED'
            ORDER BY entry_time DESC
        """, license_plate)

        parked = cursor.fetchone()

        if not parked:
            _insert_camera_event(
                cursor, "EXIT_CAM", "EXIT", license_plate, vehicle_type,
                image_url, ai_confidence, "CLOSE", "MISMATCH"
            )
            return {
                "decision": "CLOSE",
                "message": "No matching parked vehicle found",
                "license_plate": license_plate,
                "match_status": "MISMATCH",
            }

        log_id = int(parked[0])
        slot_id = int(parked[1])
        entry_time = parked[2]
        stored_vehicle_type = parked[3] or vehicle_type
        exit_time = datetime.now()
        fee_amount = _calculate_fee(stored_vehicle_type, entry_time, exit_time)

        cursor.execute("""
            UPDATE dbo.parking_logs
            SET exit_time = GETDATE(),
                status = 'COMPLETED',
                exit_image_url = ?,
                fee_amount = ?
            WHERE log_id = ?
        """, image_url, fee_amount, log_id)

        cursor.execute("""
            UPDATE dbo.slots
            SET status = 'AVAILABLE',
                sensor_distance_cm = 140.00,
                last_sensor_time = GETDATE()
            WHERE slot_id = ?
        """, slot_id)

        _insert_camera_event(
            cursor, "EXIT_CAM", "EXIT", license_plate, stored_vehicle_type,
            image_url, ai_confidence, "OPEN", "MATCH"
        )

    return {
        "decision": "OPEN",
        "message": "Exit accepted",
        "license_plate": license_plate,
        "vehicle_type": stored_vehicle_type,
        "slot_id": slot_id,
        "fee_amount": fee_amount,
        "match_status": "MATCH",
    }
