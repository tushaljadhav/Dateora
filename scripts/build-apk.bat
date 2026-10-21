@echo off
set "SCRIPT_DIR=%~dp0"
for %%I in ("%SCRIPT_DIR%..\scratch\jdk-17.0.12+7") do set "JAVA_HOME=%%~fI"
set "ANDROID_HOME=C:\Users\Tushal\AppData\Local\Android\Sdk"
set "PATH=%JAVA_HOME%\bin;%ANDROID_HOME%\platform-tools;%PATH%"

echo ===================================================
echo Building Dateora Flutter Android APK (Release)
echo JAVA_HOME: %JAVA_HOME%
echo ANDROID_HOME: %ANDROID_HOME%
echo ===================================================

cd /d "%SCRIPT_DIR%.."
if "%GEMINI_API_KEY%"=="" (
    call flutter build apk --release
) else (
    call flutter build apk --release --dart-define=GEMINI_API_KEY="%GEMINI_API_KEY%"
)

if %ERRORLEVEL% equ 0 (
    copy /y "%SCRIPT_DIR%..\build\app\outputs\flutter-apk\app-release.apk" "%SCRIPT_DIR%..\build\app\outputs\flutter-apk\Dateora.apk" >nul
    copy /y "%SCRIPT_DIR%..\build\app\outputs\flutter-apk\app-release.apk" "%SCRIPT_DIR%..\Dateora.apk" >nul
    echo.
    echo ===================================================
    echo SUCCESS! Dateora APK Generated Successfully!
    echo APK File: Dateora.apk
    echo Root:     %SCRIPT_DIR%..\Dateora.apk
    echo Flutter:  %SCRIPT_DIR%..\build\app\outputs\flutter-apk\Dateora.apk
    echo ===================================================
) else (
    echo.
    echo [ERROR] Flutter APK build failed with code %ERRORLEVEL%
)
