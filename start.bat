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

rem Add Android SDK platform-tools to PATH if present
if exist "%LOCALAPPDATA%\Android\sdk\platform-tools" (
    set "PATH=%LOCALAPPDATA%\Android\sdk\platform-tools;!PATH!"
)

echo [1/3] Checking Backend Virtual Environment...
if not exist "backend\venv" (
    echo     Virtual environment not found. Creating backend\venv...
    python -m venv backend\venv
    if errorlevel 1 (
        echo     [ERROR] Failed to create Python virtual environment! Please ensure Python 3.10+ is installed.
        pause
        exit /b 1
    )
)
echo     Verifying backend Python packages...
call backend\venv\Scripts\activate.bat
pip install -q -r backend\requirements.txt
echo     Backend dependencies verified.

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
start "GeoEvidence FastAPI Backend (Port 8000)" cmd /k "cd /d "%~dp0backend" && call venv\Scripts\activate.bat && python -m uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload"

echo     Backend server launching on http://127.0.0.1:8000 (0.0.0.0:8000) ...
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
echo Select target option:
echo.
echo   [1] Fast Launch App on Phone (Instant ^<1s - Recommended for testing)
echo   [2] Run Flutter Android (Development / Hot-Reload Mode)
echo   [3] Run Flutter Web (Chrome)
echo   [4] Run Flutter Desktop (Windows)
echo   [5] Backend Only (Keep Backend Running)
echo   [6] Enable Windows Developer Mode (Required for Desktop Symlinks)
echo   [7] Exit
echo.
set /p choice="Enter option [1-7]: "

if "%choice%"=="1" goto fast_launch_android
if "%choice%"=="2" goto run_android
if "%choice%"=="3" goto run_chrome
if "%choice%"=="4" goto run_windows
if "%choice%"=="5" goto run_backend
if "%choice%"=="6" goto enable_devmode
if "%choice%"=="7" goto finish

echo Invalid choice. Please select 1-7.
echo.
goto menu

:fast_launch_android
echo.
echo [Instant Launch] Connecting to Android device...
where adb >nul 2>nul
if %errorlevel% equ 0 (
    adb reverse tcp:8000 tcp:8000 >nul 2>nul
    echo     Port 8000 reverse proxy configured.
    echo     Opening GeoEvidence app...
    adb shell monkey -p com.geotag.evidence.geo_evidence -c android.intent.category.LAUNCHER 1 >nul 2>nul
    echo.
    echo =======================================================================
    echo [SUCCESS] GeoEvidence is now open on your phone!
    echo Backend is connected at http://127.0.0.1:8000
    echo =======================================================================
) else (
    echo [ERROR] ADB not found in PATH or Android SDK.
)
echo.
pause
goto menu

:run_android
echo.
echo Setting up ADB reverse proxy for backend communication (port 8000)...
where adb >nul 2>nul
if %errorlevel% equ 0 (
    adb reverse tcp:8000 tcp:8000 >nul 2>nul
    echo     Port 8000 reversed successfully for USB-connected Android device.
)
echo.
echo Starting GeoEvidence on Android (Debug Mode with Hot Reload)...
call flutter run
goto finish

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
echo Please enable "Developer Mode" toggle in Windows Settings, then retry Option 4.
echo.
pause
goto menu

:finish
echo.
echo GeoEvidence launcher finished.
pause
