@echo off
title Smart Parking YOLO Server
cd /d "%~dp0"

echo ==========================================
echo   Smart Parking YOLO Server Setup
echo ==========================================
echo.

if not exist "YoloSERVER.py" (
    echo [ERROR] YoloSERVER.py was not found in:
    echo %CD%
    echo.
    echo Place this BAT file in the same folder as YoloSERVER.py.
    pause
    exit /b 1
)

if not exist ".venv\Scripts\python.exe" (
    echo [1/4] Creating Python virtual environment...
    py -m venv .venv
    if errorlevel 1 (
        echo [ERROR] Failed to create the virtual environment.
        pause
        exit /b 1
    )
) else (
    echo [1/4] Virtual environment already exists.
)

echo [2/4] Activating virtual environment...
call ".venv\Scripts\activate.bat"
if errorlevel 1 (
    echo [ERROR] Failed to activate the virtual environment.
    pause
    exit /b 1
)

echo [3/4] Installing or updating required packages...
python -m pip install --upgrade pip
if errorlevel 1 (
    echo [ERROR] Failed to upgrade pip.
    pause
    exit /b 1
)

pip install fastapi uvicorn ultralytics numpy opencv-python
if errorlevel 1 (
    echo [ERROR] Failed to install required packages.
    pause
    exit /b 1
)

echo.
echo [4/4] Starting YOLO server...
echo Health check: http://127.0.0.1:8000/health
echo API docs:    http://127.0.0.1:8000/docs
echo Press Ctrl+C to stop the server.
echo.

set DB_ENABLED=0
python -m uvicorn YoloSERVER:app --host 0.0.0.0 --port 8000

echo.
echo YOLO server stopped.
pause
