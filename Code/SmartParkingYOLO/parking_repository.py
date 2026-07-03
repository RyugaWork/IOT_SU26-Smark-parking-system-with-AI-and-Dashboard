"""Repository layer for the current-design Smart Parking SQL schema.

Tables used:
- dbo.parking_occupancy
- dbo.gates
- dbo.device_modules
- dbo.detection_events
- dbo.device_heartbeats

If DB_ENABLED=0, functions return safe no-op values so /detect still works.
"""

from datetime import datetime
from typing import Any, Dict, List, Optional

from database import DB_ENABLED, get_connection


GATE_BY_DIRECTION = {
    "ENTRY": "ENTRY_GATE",
    "EXIT": "EXIT_GATE",
}

CAMERA_DEVICE_BY_DIRECTION = {
    "ENTRY": "CAM_ENTRY_01",
    "EXIT": "CAM_EXIT_01",
}


def _row_to_dict(cursor, row) -> Dict[str, Any]:
    columns = [column[0] for column in cursor.description]
    result: Dict[str, Any] = {}
    for key, value in zip(columns, row):
        if isinstance(value, datetime):
            result[key] = value.isoformat(timespec="seconds")
        else:
            result[key] = value
    return result


def _fetch_all_dicts(cursor) -> List[Dict[str, Any]]:
    rows = cursor.fetchall()
    return [_row_to_dict(cursor, row) for row in rows]


def log_detection_event(
    *,
    direction: str,
    sequence_id: Optional[int],
    distance_cm: Optional[float],
    object_detected: Optional[bool],
    raw_image_path: Optional[str],
    annotated_image_path: Optional[str],
    detected_class: Optional[str],
    confidence_percent: Optional[float],
    decision: str,
    event_status: str,
    error_message: Optional[str],
) -> Dict[str, Any]:
    if not DB_ENABLED:
        return {
            "database_enabled": False,
            "detection_id": None,
            "final_decision": decision,
            "count_before": None,
            "count_after": None,
            "error_message": None,
        }

    direction = direction.upper()
    gate_id = GATE_BY_DIRECTION.get(direction, "ENTRY_GATE")
    camera_device = CAMERA_DEVICE_BY_DIRECTION.get(direction, "CAM_ENTRY_01")
    final_decision = decision
    final_status = event_status
    count_before: Optional[int] = None
    count_after: Optional[int] = None
    detection_id: Optional[int] = None

    conn = get_connection()
    try:
        cursor = conn.cursor()

        cursor.execute("SELECT capacity, vehicles_inside FROM dbo.parking_occupancy WITH (UPDLOCK) WHERE occupancy_id = 1")
        row = cursor.fetchone()
        if row:
            capacity = int(row[0])
            vehicles_inside = int(row[1])
        else:
            capacity = 20
            vehicles_inside = 0

        count_before = vehicles_inside
        count_after = vehicles_inside

        if decision == "OPEN":
            if direction == "ENTRY":
                if vehicles_inside >= capacity:
                    final_decision = "CLOSE"
                    final_status = "ERROR"
                    error_message = error_message or "Parking capacity is full. Entry decision changed to CLOSE."
                else:
                    count_after = vehicles_inside + 1
            elif direction == "EXIT":
                count_after = max(0, vehicles_inside - 1)

        cursor.execute(
            """
            INSERT INTO dbo.detection_events
            (gate_id, direction, sequence_id, distance_cm, object_detected,
             raw_image_path, annotated_image_path, detected_class, confidence,
             decision, event_status, count_before, count_after, error_message)
            OUTPUT INSERTED.detection_id
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """,
            gate_id,
            direction,
            sequence_id,
            distance_cm,
            None if object_detected is None else int(bool(object_detected)),
            raw_image_path,
            annotated_image_path,
            detected_class,
            confidence_percent,
            final_decision,
            final_status,
            count_before,
            count_after,
            error_message,
        )
        inserted = cursor.fetchone()
        detection_id = int(inserted[0]) if inserted else None

        cursor.execute(
            """
            UPDATE dbo.parking_occupancy
            SET vehicles_inside = ?, updated_at = SYSDATETIME()
            WHERE occupancy_id = 1
            """,
            count_after,
        )

        cursor.execute(
            """
            UPDATE dbo.gates
            SET last_decision = ?, last_updated = SYSDATETIME()
            WHERE gate_id = ?
            """,
            final_decision,
            gate_id,
        )

        cursor.execute(
            """
            UPDATE dbo.device_modules
            SET status = 'ONLINE', last_heartbeat = SYSDATETIME()
            WHERE device_id IN (?, 'YOLO_SERVER_01')
            """,
            camera_device,
        )

        conn.commit()
        return {
            "database_enabled": True,
            "detection_id": detection_id,
            "final_decision": final_decision,
            "count_before": count_before,
            "count_after": count_after,
            "error_message": error_message,
        }
    except Exception:
        conn.rollback()
        raise
    finally:
        conn.close()


def log_server_heartbeat(message: str = "YOLO server heartbeat") -> None:
    if not DB_ENABLED:
        return
    conn = get_connection()
    try:
        cursor = conn.cursor()
        cursor.execute(
            """
            UPDATE dbo.device_modules
            SET status = 'ONLINE', last_heartbeat = SYSDATETIME()
            WHERE device_id = 'YOLO_SERVER_01'
            """
        )
        cursor.execute(
            """
            INSERT INTO dbo.device_heartbeats (device_id, status, message)
            VALUES ('YOLO_SERVER_01', 'ONLINE', ?)
            """,
            message,
        )
        conn.commit()
    except Exception:
        conn.rollback()
        raise
    finally:
        conn.close()


def get_recent_detection_events(limit: int = 50) -> List[Dict[str, Any]]:
    if not DB_ENABLED:
        return []
    limit = max(1, min(int(limit), 200))
    conn = get_connection()
    try:
        cursor = conn.cursor()
        cursor.execute(
            f"""
            SELECT TOP {limit}
                detection_id, gate_id, direction, sequence_id, detected_class,
                confidence, decision, event_status, count_before, count_after,
                raw_image_path, annotated_image_path, created_at
            FROM dbo.detection_events
            ORDER BY created_at DESC
            """
        )
        return _fetch_all_dicts(cursor)
    finally:
        conn.close()


def get_dashboard_data() -> Dict[str, Any]:
    if not DB_ENABLED:
        return {"database_enabled": False}

    conn = get_connection()
    try:
        cursor = conn.cursor()
        data: Dict[str, Any] = {"database_enabled": True}

        cursor.execute("SELECT * FROM dbo.v_dashboard_overview")
        row = cursor.fetchone()
        data["overview"] = _row_to_dict(cursor, row) if row else None

        cursor.execute("SELECT * FROM dbo.gates ORDER BY direction")
        data["gates"] = _fetch_all_dicts(cursor)

        cursor.execute("SELECT * FROM dbo.device_modules ORDER BY device_type, device_id")
        data["devices"] = _fetch_all_dicts(cursor)

        cursor.execute("SELECT TOP 20 * FROM dbo.v_recent_detection_events ORDER BY created_at DESC")
        data["recent_events"] = _fetch_all_dicts(cursor)

        return data
    finally:
        conn.close()
