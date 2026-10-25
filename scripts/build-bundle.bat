@echo off
set "SCRIPT_DIR=%~dp0"
for %%I in ("%SCRIPT_DIR%..\scratch\jdk-17.0.12+7") do set "JAVA_HOME=%%~fI"
set "ANDROID_HOME=C:\Users\Tushal\AppData\Local\Android\Sdk"
set "PATH=%JAVA_HOME%\bin;%ANDROID_HOME%\platform-tools;%PATH%"

echo ===================================================
echo Building Dateora Flutter Android App Bundle (.aab) for Google Play
echo JAVA_HOME: %JAVA_HOME%
echo ANDROID_HOME: %ANDROID_HOME%
echo ===================================================

cd /d "%SCRIPT_DIR%.."
if "%API_BASE_URL%"=="" (
    call flutter build appbundle --release --dart-define=API_BASE_URL="https://dateora.onrender.com/api"
) else (
    call flutter build appbundle --release --dart-define=API_BASE_URL="%API_BASE_URL%"
)

if %ERRORLEVEL% equ 0 (
    copy /y "%SCRIPT_DIR%..\build\app\outputs\bundle\release\app-release.aab" "%SCRIPT_DIR%..\Dateora.aab" >nul
    echo.
    echo ===================================================
    echo SUCCESS! Dateora AAB Generated Successfully!
    echo Upload this file to Google Play Console:
    echo Root:    %SCRIPT_DIR%..\Dateora.aab
    echo Flutter: %SCRIPT_DIR%..\build\app\outputs\bundle\release\app-release.aab
    echo ===================================================
) else (
    echo.
    echo [ERROR] Flutter App Bundle build failed with code %ERRORLEVEL%
)
