"""
Smart Parking YOLO Server - clean rebuild.

Current supported communication path:
ESP32-CAM -> HTTP POST /detect -> YOLO Server -> plain text OPEN/CLOSE.
The YOLO server does not directly control the Arduino servo gate. The ESP32-CAM
forwards the compact result to the Slave Arduino, then the Master Arduino polls
the Slave and controls the physical gate.

Design goals:
- Keep /detect simple and stable for ESP32-CAM.
- Fail safe: invalid image, no valid vehicle, model error, or server error => CLOSE.
- Save raw image, annotated image, and JSON metadata for dashboard/debugging.
- Optionally log detection events to SQL Server tables from smart_parking_refine.sql.
"""

import json
import logging
import os
import shutil
import time
from datetime import datetime
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple

import cv2
import numpy as np
from fastapi import FastAPI, Request
from fastapi.responses import FileResponse, JSONResponse, PlainTextResponse
from ultralytics import YOLO

from database import DB_ENABLED
from parking_repository import (
    get_dashboard_data,
    get_recent_detection_events,
    log_detection_event,
    log_server_heartbeat,
)

# ============================================================
# Configuration helpers
# ============================================================


def env_bool(name: str, default: str = "0") -> bool:
    return os.getenv(name, default).strip().lower() in {"1", "true", "yes", "y", "on"}


def env_float(name: str, default: str) -> float:
    try:
        return float(os.getenv(name, default))
    except ValueError:
        return float(default)


def env_int(name: str, default: str) -> int:
    try:
        return int(os.getenv(name, default))
    except ValueError:
        return int(default)


MODEL_PATH = os.getenv("MODEL_PATH", "yolo26l.pt")
CONF_THRESHOLD = env_float("CONF_THRESHOLD", "0.45")
IMG_SIZE = env_int("IMG_SIZE", "640")
ALLOWED_CLASSES = {
    x.strip().lower()
    for x in os.getenv("ALLOWED_CLASSES", "car,motorcycle,bus,truck").split(",")
    if x.strip()
}

SAVE_RAW_IMAGE = env_bool("SAVE_RAW_IMAGE", "1")
SAVE_RESULT_IMAGE = env_bool("SAVE_RESULT_IMAGE", "1")
RESULT_DIR = Path(os.getenv("RESULT_DIR", "results"))
RAW_DIR = RESULT_DIR / "raw"
ANNOTATED_DIR = RESULT_DIR / "annotated"
JSON_DIR = RESULT_DIR / "json"
LATEST_JSON_PATH = RESULT_DIR / "latest_detection.json"
LATEST_ANNOTATED_PATH = RESULT_DIR / "latest_annotated.jpg"

# If SQL logging fails, the Arduino protocol can still continue by default.
# Set DB_FAIL_SAFE_CLOSE=1 to force CLOSE when database logging fails.
DB_FAIL_SAFE_CLOSE = env_bool("DB_FAIL_SAFE_CLOSE", "0")

for directory in (RESULT_DIR, RAW_DIR, ANNOTATED_DIR, JSON_DIR):
    directory.mkdir(parents=True, exist_ok=True)

# ============================================================
# Logging
# ============================================================

logging.basicConfig(level=logging.INFO, format="%(asctime)s | %(levelname)s | %(message)s")
logger = logging.getLogger("smartparking-yolo-rebuild")

# ============================================================
# FastAPI + YOLO model
# ============================================================

app = FastAPI(
    title="Smart Parking YOLO Server Rebuild",
    version="3.0.0",
    description="Clean FastAPI + YOLO server for ESP32-CAM JPEG detection. /detect returns plain OPEN/CLOSE.",
)

logger.info("Loading YOLO model: %s", MODEL_PATH)
model = YOLO(MODEL_PATH)
logger.info("YOLO model loaded. Class names: %s", model.names)
logger.info("Allowed classes for OPEN: %s", sorted(ALLOWED_CLASSES))
logger.info("Database logging enabled: %s", DB_ENABLED)

# ============================================================
# Parsing helpers
# ============================================================


def now_id() -> str:
    return datetime.now().strftime("%Y%m%d_%H%M%S_%f")


def parse_int(value: Optional[str]) -> Optional[int]:
    if value is None or value == "":
        return None
    try:
        return int(value)
    except ValueError:
        return None


def parse_float(value: Optional[str]) -> Optional[float]:
    if value is None or value == "":
        return None
    try:
        return float(value)
    except ValueError:
        return None


def parse_bool(value: Optional[str]) -> Optional[bool]:
    if value is None or value == "":
        return None
    return value.strip().lower() in {"1", "true", "yes", "y", "detected", "object", "on"}


def get_direction(request: Request) -> str:
    raw = (
        request.query_params.get("direction")
        or request.query_params.get("module")
        or request.headers.get("X-Gate-Direction")
        or request.headers.get("X-Module-ID")
        or "ENTRY"
    )
    raw = raw.strip().upper()
    return "EXIT" if "EXIT" in raw else "ENTRY"


def get_request_context(request: Request) -> Dict[str, Any]:
    return {
        "direction": get_direction(request),
        "sequence_id": parse_int(request.query_params.get("sequence_id") or request.headers.get("X-Sequence-ID")),
        "distance_cm": parse_float(request.query_params.get("distance_cm") or request.headers.get("X-Distance-CM")),
        "object_detected": parse_bool(request.query_params.get("object_detected") or request.headers.get("X-Object-Detected")),
    }


def decode_jpeg(image_bytes: bytes) -> Optional[np.ndarray]:
    if not image_bytes:
        return None
    array = np.frombuffer(image_bytes, np.uint8)
    return cv2.imdecode(array, cv2.IMREAD_COLOR)

# ============================================================
# Detection logic
# ============================================================


def run_yolo(image: np.ndarray) -> Dict[str, Any]:
    started = time.time()
    results = model.predict(source=image, imgsz=IMG_SIZE, conf=CONF_THRESHOLD, verbose=False)
    result = results[0]
    names = result.names

    detections: List[Dict[str, Any]] = []
    best_any: Optional[Dict[str, Any]] = None
    best_allowed: Optional[Dict[str, Any]] = None

    if result.boxes is not None:
        for box in result.boxes:
            class_id = int(box.cls[0].item())
            confidence = float(box.conf[0].item())
            class_name = str(names[class_id]).lower()
            x1, y1, x2, y2 = [float(x) for x in box.xyxy[0].tolist()]
            allowed = class_name in ALLOWED_CLASSES and confidence >= CONF_THRESHOLD

            item = {
                "class_id": class_id,
                "class": class_name,
                "confidence": round(confidence, 4),
                "confidence_percent": round(confidence * 100, 2),
                "bbox": [round(x1, 2), round(y1, 2), round(x2, 2), round(y2, 2)],
                "allowed": allowed,
            }
            detections.append(item)

            if best_any is None or item["confidence"] > best_any["confidence"]:
                best_any = item
            if allowed and (best_allowed is None or item["confidence"] > best_allowed["confidence"]):
                best_allowed = item

    decision = "OPEN" if best_allowed is not None else "CLOSE"
    event_status = "OK" if best_allowed is not None else "NO_DETECTION"

    return {
        "decision": decision,
        "event_status": event_status,
        "detections": detections,
        "best_detection": best_allowed or best_any,
        "best_allowed_detection": best_allowed,
        "inference_ms": round((time.time() - started) * 1000, 2),
        "allowed_classes": sorted(ALLOWED_CLASSES),
        "confidence_threshold": CONF_THRESHOLD,
        "img_size": IMG_SIZE,
        "_yolo_result": result,
    }


def save_result_files(
    request_id: str,
    image: np.ndarray,
    detection: Dict[str, Any],
    context: Dict[str, Any],
) -> Dict[str, Any]:
    direction = context["direction"]
    prefix = direction.upper()
    raw_path: Optional[Path] = None
    annotated_path: Optional[Path] = None

    if SAVE_RAW_IMAGE:
        raw_path = RAW_DIR / f"{prefix}_{request_id}.jpg"
        cv2.imwrite(str(raw_path), image)

    yolo_result = detection.get("_yolo_result")
    if SAVE_RESULT_IMAGE and yolo_result is not None:
        annotated_image = yolo_result.plot()
        annotated_path = ANNOTATED_DIR / f"{prefix}_{request_id}.jpg"
        cv2.imwrite(str(annotated_path), annotated_image)
        cv2.imwrite(str(LATEST_ANNOTATED_PATH), annotated_image)

    serializable = {key: value for key, value in detection.items() if key != "_yolo_result"}
    serializable.update(
        {
            "request_id": request_id,
            "timestamp": datetime.now().isoformat(timespec="seconds"),
            "direction": direction,
            "sequence_id": context.get("sequence_id"),
            "distance_cm": context.get("distance_cm"),
            "object_detected": context.get("object_detected"),
            "model_path": MODEL_PATH,
            "raw_image_path": str(raw_path).replace("\\", "/") if raw_path else None,
            "annotated_image_path": str(annotated_path).replace("\\", "/") if annotated_path else None,
        }
    )

    json_path = JSON_DIR / f"{prefix}_{request_id}.json"
    json_path.write_text(json.dumps(serializable, indent=2), encoding="utf-8")
    LATEST_JSON_PATH.write_text(json.dumps(serializable, indent=2), encoding="utf-8")
    return serializable


async def process_detection_request(request: Request) -> Dict[str, Any]:
    request_id = now_id()
    context = get_request_context(request)

    image_bytes = await request.body()
    image = decode_jpeg(image_bytes)
    if image is None:
        result = {
            "request_id": request_id,
            "timestamp": datetime.now().isoformat(timespec="seconds"),
            **context,
            "decision": "CLOSE",
            "event_status": "ERROR",
            "error_message": "Empty body or invalid JPEG image.",
            "detections": [],
            "best_detection": None,
        }
        LATEST_JSON_PATH.write_text(json.dumps(result, indent=2), encoding="utf-8")
        return result

    detection = run_yolo(image)
    saved = save_result_files(request_id, image, detection, context)

    best = saved.get("best_detection") or {}
    detected_class = best.get("class")
    confidence_percent = best.get("confidence_percent")

    try:
        db_result = log_detection_event(
            direction=context["direction"],
            sequence_id=context.get("sequence_id"),
            distance_cm=context.get("distance_cm"),
            object_detected=context.get("object_detected"),
            raw_image_path=saved.get("raw_image_path"),
            annotated_image_path=saved.get("annotated_image_path"),
            detected_class=detected_class,
            confidence_percent=confidence_percent,
            decision=saved["decision"],
            event_status=saved["event_status"],
            error_message=None,
        )
    except Exception as exc:
        logger.exception("SQL logging failed: %s", exc)
        db_result = {
            "database_enabled": DB_ENABLED,
            "detection_id": None,
            "final_decision": "CLOSE" if DB_FAIL_SAFE_CLOSE else saved["decision"],
            "count_before": None,
            "count_after": None,
            "error_message": f"SQL logging failed: {exc}",
        }

    saved["decision_before_database_rule"] = saved["decision"]
    saved["database"] = db_result
    saved["decision"] = db_result.get("final_decision") or saved["decision"]
    LATEST_JSON_PATH.write_text(json.dumps(saved, indent=2), encoding="utf-8")

    logger.info(
        "request_id=%s direction=%s seq=%s decision=%s best=%s db_enabled=%s inference_ms=%s",
        request_id,
        context["direction"],
        context.get("sequence_id"),
        saved["decision"],
        best,
        DB_ENABLED,
        saved.get("inference_ms"),
    )
    return saved


def local_recent_events(limit: int = 20) -> List[Dict[str, Any]]:
    if not JSON_DIR.exists():
        return []
    files = sorted(JSON_DIR.glob("*.json"), key=lambda p: p.stat().st_mtime, reverse=True)
    events: List[Dict[str, Any]] = []
    for file in files[: max(1, min(limit, 100))]:
        try:
            events.append(json.loads(file.read_text(encoding="utf-8")))
        except Exception:
            continue
    return events

# ============================================================
# Routes
# ============================================================


@app.get("/")
def root() -> Dict[str, Any]:
    return {
        "service": "Smart Parking YOLO Server Rebuild",
        "status": "running",
        "main_endpoint": "POST /detect",
        "main_response": "plain text OPEN or CLOSE",
        "debug_endpoint": "POST /detect-debug",
        "database_enabled": DB_ENABLED,
    }


@app.get("/health")
def health_check() -> Dict[str, Any]:
    db_status = "disabled"
    if DB_ENABLED:
        try:
            log_server_heartbeat("Health check")
            db_status = "ok"
        except Exception as exc:
            db_status = f"error: {exc}"
    return {
        "status": "ok",
        "model": MODEL_PATH,
        "confidence_threshold": CONF_THRESHOLD,
        "img_size": IMG_SIZE,
        "allowed_classes": sorted(ALLOWED_CLASSES),
        "save_raw_image": SAVE_RAW_IMAGE,
        "save_result_image": SAVE_RESULT_IMAGE,
        "database_enabled": DB_ENABLED,
        "database_status": db_status,
    }


@app.get("/api/health")
def api_health_check() -> Dict[str, Any]:
    return health_check()


@app.post("/detect", response_class=PlainTextResponse)
async def detect_vehicle(request: Request) -> str:
    """Main ESP32-CAM endpoint. Input is raw JPEG bytes. Output is plain OPEN or CLOSE."""
    try:
        result = await process_detection_request(request)
        return "OPEN" if result.get("decision") == "OPEN" else "CLOSE"
    except Exception as exc:
        logger.exception("Unhandled /detect error: %s", exc)
        return "CLOSE"


@app.post("/detect-debug", response_model=None)
async def detect_vehicle_debug(request: Request):
    """PC testing endpoint. It returns JSON metadata, not Arduino-compatible plain text."""
    try:
        result = await process_detection_request(request)
        return JSONResponse(status_code=200, content=result)
    except Exception as exc:
        logger.exception("Unhandled /detect-debug error: %s", exc)
        return JSONResponse(status_code=200, content={"decision": "CLOSE", "error_message": str(exc)})


@app.get("/latest", response_model=None)
def latest_detection():
    if not LATEST_JSON_PATH.exists():
        return JSONResponse(status_code=404, content={"error": "No detection has been saved yet."})
    return JSONResponse(status_code=200, content=json.loads(LATEST_JSON_PATH.read_text(encoding="utf-8")))


@app.get("/latest-image", response_model=None)
def latest_image():
    if not LATEST_ANNOTATED_PATH.exists():
        return JSONResponse(status_code=404, content={"error": "No annotated image has been saved yet."})
    return FileResponse(path=str(LATEST_ANNOTATED_PATH), media_type="image/jpeg")


@app.get("/api/dashboard")
def api_dashboard() -> Dict[str, Any]:
    if DB_ENABLED:
        return get_dashboard_data()
    return {
        "database_enabled": False,
        "latest": json.loads(LATEST_JSON_PATH.read_text(encoding="utf-8")) if LATEST_JSON_PATH.exists() else None,
        "recent_events": local_recent_events(limit=20),
    }


@app.get("/api/detections")
def api_detections(limit: int = 50) -> Dict[str, Any]:
    if DB_ENABLED:
        return {"database_enabled": True, "events": get_recent_detection_events(limit=limit)}
    return {"database_enabled": False, "events": local_recent_events(limit=limit)}


@app.post("/api/admin/reset-results")
def reset_results() -> Dict[str, Any]:
    if RESULT_DIR.exists():
        shutil.rmtree(RESULT_DIR)
    for directory in (RESULT_DIR, RAW_DIR, ANNOTATED_DIR, JSON_DIR):
        directory.mkdir(parents=True, exist_ok=True)
    return {"status": "ok", "message": "Local result files cleared. SQL rows were not deleted."}
