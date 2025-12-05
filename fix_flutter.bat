@echo off
REM This script fixes the Flutter Dart SDK permission issue

echo Killing running Flutter/Dart processes...
taskkill /F /IM dart.exe >nul 2>&1
taskkill /F /IM java.exe >nul 2>&1

echo.
echo Clearing Flutter cache...
rmdir /s /q "D:\flutter\bin\cache" >nul 2>&1
mkdir "D:\flutter\bin\cache"

echo.
echo Setting proper permissions...
icacls "D:\flutter\bin\cache" /grant:r "%USERNAME%":F /T /C >nul 2>&1

echo.
echo Done! Now try: flutter run
echo.
pause
