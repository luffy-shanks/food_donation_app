@echo off
cd /d "%~dp0"
echo Starting the GoodFood browser preview...
start "GoodFood preview server" /B npm.cmd run start
timeout /t 2 /nobreak >nul
start "" "http://localhost:5173/"
echo.
echo Keep this window open while using the preview. Press Ctrl+C here to stop the server.
pause >nul
