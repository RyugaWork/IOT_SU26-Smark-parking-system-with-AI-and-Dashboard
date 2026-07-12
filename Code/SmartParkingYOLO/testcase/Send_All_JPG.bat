@echo off
setlocal EnableExtensions EnableDelayedExpansion
title Send All JPG Images to YOLO Server
cd /d "%~dp0"

set "CLIENT=test_client.py"
set "SERVER_URL=http://127.0.0.1:8000/detect"
set "MODULE=ENTRY"

echo ==========================================
echo   Send all JPG images to YOLO Server
echo ==========================================
echo Folder: %CD%
echo Server: %SERVER_URL%
echo Module: %MODULE%
echo.

if not exist "%CLIENT%" (
    echo [ERROR] %CLIENT% was not found in:
    echo %CD%
    echo.
    echo Place this BAT file in the same folder as test_client.py.
    pause
    exit /b 1
)

set /a TOTAL=0
set /a SUCCESS=0
set /a FAILED=0

for %%F in (*.jpg *.jpeg) do (
    if exist "%%F" (
        set /a TOTAL+=1
        echo.
        echo ------------------------------------------
        echo [!TOTAL!] Sending: %%F
        echo ------------------------------------------

        python "%CLIENT%" "%%F" --url "%SERVER_URL%" --module "%MODULE%"

        if errorlevel 1 (
            echo [FAILED] %%F
            set /a FAILED+=1
        ) else (
            echo [DONE] %%F
            set /a SUCCESS+=1
        )
    )
)

echo.
echo ==========================================
echo Finished
echo Total:   %TOTAL%
echo Success: %SUCCESS%
echo Failed:  %FAILED%
echo ==========================================

if %TOTAL%==0 (
    echo No .jpg or .jpeg files were found in this folder.
)

pause
endlocal
