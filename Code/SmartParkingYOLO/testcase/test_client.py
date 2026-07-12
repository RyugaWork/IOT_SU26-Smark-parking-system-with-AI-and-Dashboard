"""PC test client for Smart Parking YOLO Server.

This script replaces the ESP32-CAM during testing. It sends a local JPEG image to
POST /detect and prints the server decision.
"""

import argparse
from pathlib import Path
from urllib.parse import urlparse, urlunparse

import requests


def debug_url(url: str) -> str:
    parsed = urlparse(url)
    path = parsed.path
    if path.endswith("/detect"):
        path = path[: -len("/detect")] + "/detect-debug"
    elif not path.endswith("/detect-debug"):
        path = path.rstrip("/") + "/detect-debug"
    return urlunparse(parsed._replace(path=path))


def main() -> int:
    parser = argparse.ArgumentParser(description="Send a local JPEG to the Smart Parking YOLO server.")
    parser.add_argument("image", help="Path to a local .jpg/.jpeg image")
    parser.add_argument("--url", default="http://127.0.0.1:8000/detect", help="Server detect URL")
    parser.add_argument("--module", default="ENTRY", choices=["ENTRY", "EXIT"], help="Gate direction/module")
    parser.add_argument("--sequence-id", type=int, default=None, help="Optional capture sequence id")
    parser.add_argument("--distance-cm", type=float, default=None, help="Optional ultrasonic distance")
    parser.add_argument("--object-detected", action="store_true", help="Send object_detected=true")
    parser.add_argument("--debug", action="store_true", help="Call /detect-debug and print JSON response")
    args = parser.parse_args()

    image_path = Path(args.image)
    if not image_path.exists():
        print(f"Image not found: {image_path}")
        return 1

    url = debug_url(args.url) if args.debug else args.url
    params = {"module": args.module}
    if args.sequence_id is not None:
        params["sequence_id"] = str(args.sequence_id)
    if args.distance_cm is not None:
        params["distance_cm"] = str(args.distance_cm)
    if args.object_detected:
        params["object_detected"] = "1"

    data = image_path.read_bytes()
    headers = {"Content-Type": "image/jpeg"}

    try:
        response = requests.post(url, params=params, headers=headers, data=data, timeout=30)
    except requests.RequestException as exc:
        print(f"Request failed: {exc}")
        return 1

    print(f"URL: {response.url}")
    print(f"HTTP status: {response.status_code}")
    print("Response:")
    content_type = response.headers.get("content-type", "")
    if "application/json" in content_type:
        print(response.text)
    else:
        print(response.text.strip())

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
