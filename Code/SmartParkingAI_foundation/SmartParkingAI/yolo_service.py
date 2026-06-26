"""
yolo_service.py

This file is intentionally a simple stub.
It allows the FastAPI + SQL Server + Dashboard flow to work first.

TODO: Replace detect_vehicle() with real YOLO / license plate OCR later.
Possible future approach:
- Load YOLO model once when app starts.
- Detect vehicle/license plate region.
- Crop plate.
- Run OCR.
- Return plate, vehicle_type, confidence.
"""

import os
import re
from typing import Dict, Optional


def _guess_plate_from_filename(image_path: str) -> Optional[str]:
    """
    Demo helper: if image filename contains a plate-like value,
    extract it. Example: entry_71AA23210.jpg -> 71AA-23210.
    """
    filename = os.path.basename(image_path).upper()

    patterns = [
        r"(\d{2}[A-Z]{1,2})[-_]?(\d{3,5})",
        r"(\d{2}[A-Z]{1,2})[-_]?(\d{3})[-_]?(\d{2})",
    ]

    for pattern in patterns:
        match = re.search(pattern, filename)
        if match:
            parts = match.groups()
            if len(parts) == 2:
                return f"{parts[0]}-{parts[1]}"
            if len(parts) == 3:
                return f"{parts[0]}-{parts[1]}.{parts[2]}"

    return None


def detect_vehicle(
    image_path: str,
    mock_plate: Optional[str] = None,
    mock_vehicle_type: Optional[str] = None
) -> Dict:
    """
    Temporary fake AI result for demo.

    Parameters:
        image_path: saved image path
        mock_plate: manually provided plate while YOLO/OCR is not integrated
        mock_vehicle_type: manually provided vehicle type

    Returns:
        {
            "license_plate": "...",
            "vehicle_type": "...",
            "confidence": 0.95
        }
    """
    guessed_plate = _guess_plate_from_filename(image_path)

    return {
        "license_plate": mock_plate or guessed_plate or "UNKNOWN",
        "vehicle_type": mock_vehicle_type or "Ô tô",
        "confidence": 0.95 if (mock_plate or guessed_plate) else 0.50,
    }
