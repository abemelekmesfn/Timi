@echo off
echo ==========================================
echo       Starting Timi Backend Services
echo ==========================================
cd c:\Users\hp\Desktop\Timi\backend

:: Start Django in a new window
echo Starting Django Server...
start cmd /k "venv\Scripts\python manage.py runserver 0.0.0.0:8001"

:: Wait a second
timeout /t 2 /nobreak >nul

:: Start Localtunnel in this window
echo.
echo Starting Internet Tunnel so the mobile app can connect...
echo (Make sure to keep both this window and the Django window open!)
echo.
npx localtunnel --port 8001 --subdomain timi-dev-8001
