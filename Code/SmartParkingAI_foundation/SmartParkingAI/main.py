"""
main.py

Run:
    uvicorn main:app --reload

Open dashboard:
    http://127.0.0.1:8000
"""

from datetime import datetime
from pathlib import Path
from typing import Optional
from uuid import uuid4

import aiofiles
from fastapi import FastAPI, File, Form, HTTPException, Request, UploadFile
from fastapi.responses import JSONResponse
from fastapi.staticfiles import StaticFiles
from fastapi.templating import Jinja2Templates

from parking_service import (
    get_dashboard_data,
    get_parking_logs,
    get_slots,
    register_entry,
    register_exit,
)
from yolo_service import detect_vehicle


BASE_DIR = Path(__file__).resolve().parent
STATIC_DIR = BASE_DIR / "static"
UPLOAD_ENTRY_DIR = STATIC_DIR / "uploads" / "entry"
UPLOAD_EXIT_DIR = STATIC_DIR / "uploads" / "exit"

UPLOAD_ENTRY_DIR.mkdir(parents=True, exist_ok=True)
UPLOAD_EXIT_DIR.mkdir(parents=True, exist_ok=True)

app = FastAPI(
    title="Smart Parking AI Backend",
    description="FastAPI backend for IoT102 Smart Parking System",
    version="1.0.0",
)

app.mount("/static", StaticFiles(directory=str(STATIC_DIR)), name="static")
templates = Jinja2Templates(directory=str(BASE_DIR / "templates"))


@app.get("/")
def dashboard_page(request: Request):
    return templates.TemplateResponse("dashboard.html", {"request": request})


@app.get("/api/health")
def health_check():
    return {
        "status": "OK",
        "message": "Smart Parking AI backend is running",
        "time": datetime.now().isoformat(),
    }


@app.get("/api/dashboard")
def api_dashboard():
    try:
        return get_dashboard_data()
    except Exception as ex:
        raise HTTPException(status_code=500, detail=str(ex))


@app.get("/api/slots")
def api_slots():
    try:
        return {"slots": get_slots()}
    except Exception as ex:
        raise HTTPException(status_code=500, detail=str(ex))


@app.get("/api/logs")
def api_logs(limit: int = 50):
    try:
        return {"logs": get_parking_logs(limit=limit)}
    except Exception as ex:
        raise HTTPException(status_code=500, detail=str(ex))


async def _save_upload(file: UploadFile, folder: Path, prefix: str) -> str:
    """
    Save uploaded image to static/uploads/{entry|exit}.
    Return database-relative path, e.g. uploads/entry/entry_xxx.jpg.
    """
    original_name = file.filename or "capture.jpg"
    ext = Path(original_name).suffix.lower()

    if ext not in [".jpg", ".jpeg", ".png", ".webp"]:
        ext = ".jpg"

    filename = f"{prefix}_{datetime.now().strftime('%Y%m%d_%H%M%S')}_{uuid4().hex[:8]}{ext}"
    save_path = folder / filename

    async with aiofiles.open(save_path, "wb") as out_file:
        content = await file.read()
        await out_file.write(content)

    if prefix == "entry":
        return f"uploads/entry/{filename}"

    return f"uploads/exit/{filename}"


@app.post("/api/detect/entry")
async def detect_entry(
    file: UploadFile = File(...),
    mock_plate: Optional[str] = Form(None),
    mock_vehicle_type: Optional[str] = Form("Ô tô"),
    rfid_card_id: Optional[str] = Form(None),
    slot_id: Optional[int] = Form(None),
):
    """
    Receive entry camera image.

    Current demo:
    - Save image.
    - Use yolo_service.detect_vehicle() mock result.
    - Insert parking log with status PARKED.
    - Update slot as OCCUPIED.
    - Return OPEN/CLOSE decision.

    TODO: Replace mock_plate with real YOLO/OCR result.
    """
    try:
        image_url = await _save_upload(file, UPLOAD_ENTRY_DIR, "entry")
        image_path = str(STATIC_DIR / image_url)

        ai_result = detect_vehicle(
            image_path=image_path,
            mock_plate=mock_plate,
            mock_vehicle_type=mock_vehicle_type,
        )

        result = register_entry(
            license_plate=ai_result["license_plate"],
            vehicle_type=ai_result["vehicle_type"],
            image_url=image_url,
            ai_confidence=ai_result["confidence"],
            slot_id=slot_id,
            rfid_card_id=rfid_card_id,
        )

        result["ai_result"] = ai_result
        result["image_url"] = f"/static/{image_url}"
        return result

    except Exception as ex:
        raise HTTPException(status_code=500, detail=str(ex))


@app.post("/api/detect/exit")
async def detect_exit(
    file: UploadFile = File(...),
    mock_plate: Optional[str] = Form(None),
    mock_vehicle_type: Optional[str] = Form("Ô tô"),
):
    """
    Receive exit camera image.

    Current demo:
    - Save image.
    - Use yolo_service.detect_vehicle() mock result.
    - Match plate with PARKED record.
    - Update parking log to COMPLETED if matched.
    - Return OPEN/CLOSE decision.

    TODO: Replace mock_plate with real YOLO/OCR result.
    """
    try:
        image_url = await _save_upload(file, UPLOAD_EXIT_DIR, "exit")
        image_path = str(STATIC_DIR / image_url)

        ai_result = detect_vehicle(
            image_path=image_path,
            mock_plate=mock_plate,
            mock_vehicle_type=mock_vehicle_type,
        )

        result = register_exit(
            license_plate=ai_result["license_plate"],
            vehicle_type=ai_result["vehicle_type"],
            image_url=image_url,
            ai_confidence=ai_result["confidence"],
        )

        result["ai_result"] = ai_result
        result["image_url"] = f"/static/{image_url}"
        return result

    except Exception as ex:
        raise HTTPException(status_code=500, detail=str(ex))


@app.post("/api/gate/open")
def open_gate():
    """
    Demo endpoint for dashboard button.

    TODO: Send real command to Arduino/ESP32 later.
    """
    return JSONResponse({
        "gateStatus": "OPEN",
        "message": "Gate open command accepted. TODO: integrate Arduino command."
    })


@app.post("/api/gate/close")
def close_gate():
    """
    Demo endpoint for dashboard button.

    TODO: Send real command to Arduino/ESP32 later.
    """
    return JSONResponse({
        "gateStatus": "CLOSED",
        "message": "Gate close command accepted. TODO: integrate Arduino command."
    })


@app.post("/api/alarm")
def trigger_alarm():
    """
    Demo endpoint for alarm button.

    TODO: Send alarm signal to hardware later.
    """
    return JSONResponse({
        "alarm": "ON",
        "message": "Alarm triggered. TODO: integrate buzzer/LED."
    })
