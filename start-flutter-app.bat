@echo off
setlocal
title RESET Store - Flutter Client + Unified Website Project Launcher
echo ============================================================
echo        RESET STORE - FLUTTER CLIENT LAUNCHER
echo ============================================================
echo.

if not exist "%~dp0..\Website Project\artisan" (
    echo [ERROR] Could not find unified Laravel backend at:
    echo         %~dp0..\Website Project\artisan
    pause
    exit /b 1
)

echo [1/3] Starting Firebase Gateway API from ..\API on http://127.0.0.1:4000 ...
if exist "%~dp0..\API\package.json" (
    for /f "tokens=5" %%a in ('netstat -aon ^| findstr :4000 ^| findstr LISTENING') do taskkill /f /pid %%a > nul 2>&1
    pushd "%~dp0..\API"
    if not exist "dist\src\server.js" call npm run build
    start "RESET Firebase API (Port 4000)" /min cmd /c "npm run start"
    popd
)

echo [2/3] Starting unified Laravel API ^& Filament Admin from ..\Website Project on http://127.0.0.1:8000 ...
for /f "tokens=5" %%a in ('netstat -aon ^| findstr :8000 ^| findstr LISTENING') do taskkill /f /pid %%a > nul 2>&1
pushd "%~dp0..\Website Project"
start "RESET Unified Backend (Port 8000)" /min cmd /c "php artisan serve --host=127.0.0.1 --port=8000"
popd
timeout /t 2 /nobreak > nul

echo.
echo  Firebase API Docs: http://127.0.0.1:4000/docs
echo  Backend API:       http://127.0.0.1:8000/api/v1/bootstrap
echo  Swagger API Docs:  http://127.0.0.1:8000/api/docs
echo  Web Admin Panel:   http://127.0.0.1:8000/admin
echo.
echo [3/3] Launching RESET Flutter App in Chrome (press q in terminal to quit)...
echo  (For Android Emulator: flutter run -d android)
echo  (For iOS Simulator:    flutter run -d ios)
echo.
cd /d "%~dp0"
flutter run -d chrome --dart-define=API_BASE_URL=http://127.0.0.1:8000 --dart-define=FIREBASE_API_URL=http://127.0.0.1:4000
