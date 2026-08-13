@echo off
setlocal enabledelayedexpansion

title GeoEvidence Launcher
color 0A

echo =======================================================================
echo                        GEOEVIDENCE LAUNCHER                            
echo            Secure Geo-Tagged Evidence Management System                
echo =======================================================================
echo.

rem Navigate to project root
cd /d "%~dp0"

echo [1/3] Checking Backend Virtual Environment...
if not exist "backend\venv" (
    echo     Virtual environment not found. Creating backend\venv...
    python -m venv backend\venv
    if errorlevel 1 (
        echo     [ERROR] Failed to create Python virtual environment! Please ensure Python 3.10+ is installed.
        pause
        exit /b 1
    )
    echo     Installing backend requirements...
    call backend\venv\Scripts\activate.bat
    pip install -r backend\requirements.txt
) else (
    echo     Virtual environment verified.
)

echo.
echo [2/3] Checking Flutter dependencies...
if not exist "pubspec.lock" (
    echo     Running flutter pub get...
    call flutter pub get
) else (
    echo     Flutter dependencies verified.
)

echo.
echo [3/3] Starting GeoEvidence FastAPI Backend...
start "GeoEvidence FastAPI Backend (Port 8000)" cmd /k "cd /d "%~dp0backend" && call venv\Scripts\activate.bat && python -m uvicorn app.main:app --host 127.0.0.1 --port 8000 --reload"

echo     Backend server launching on http://127.0.0.1:8000 ...
echo.

echo =======================================================================
echo                     DEMO LOGIN CREDENTIALS                             
echo =======================================================================
echo   Field Officer : officer@geotag.com    ^| Password: password123
echo   Supervisor    : supervisor@geotag.com ^| Password: password123
echo   Admin         : admin@geotag.com      ^| Password: password123
echo =======================================================================
echo.

:menu
echo Select target platform for Flutter app:
echo.
echo   [1] Run Flutter Desktop (Windows)
echo   [2] Run Flutter Web (Chrome - Recommended without Developer Mode)
echo   [3] Run Flutter Android (Emulator or Connected Device)
echo   [4] Backend Only (Keep Backend Running)
echo   [5] Enable Windows Developer Mode (Required for Desktop Symlinks)
echo   [6] Exit
echo.
set /p choice="Enter option [1-6]: "

if "%choice%"=="1" goto run_windows
if "%choice%"=="2" goto run_chrome
if "%choice%"=="3" goto run_android
if "%choice%"=="4" goto run_backend
if "%choice%"=="5" goto enable_devmode
if "%choice%"=="6" goto finish

echo Invalid choice. Please select 1-6.
echo.
goto menu

:run_windows
echo.
echo Starting GeoEvidence on Windows Desktop...
echo (Note: Windows Developer Mode must be ON for Flutter desktop symlinks)
call flutter run -d windows
goto finish

:run_chrome
echo.
echo Starting GeoEvidence on Chrome...
call flutter run -d chrome
goto finish

:run_android
echo.
echo Starting GeoEvidence on Android...
call flutter run -d android
goto finish

:run_backend
echo.
echo Backend is running at http://127.0.0.1:8000
echo Interactive Swagger API docs: http://127.0.0.1:8000/docs
pause
goto finish

:enable_devmode
echo.
echo Opening Windows Developer Settings...
start ms-settings:developers
echo Please enable "Developer Mode" toggle in Windows Settings, then retry Option 1.
echo.
pause
goto menu

:finish
echo.
echo GeoEvidence launcher finished.
pause
