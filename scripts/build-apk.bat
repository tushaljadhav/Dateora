@echo off
set "SCRIPT_DIR=%~dp0"
for %%I in ("%SCRIPT_DIR%..\scratch\jdk-17.0.12+7") do set "JAVA_HOME=%%~fI"
set "ANDROID_HOME=C:\Users\Tushal\AppData\Local\Android\Sdk"
set "PATH=%JAVA_HOME%\bin;%ANDROID_HOME%\platform-tools;C:\Program Files\nodejs;%PATH%"

echo ===================================================
echo Building Dateora Android APK (assembleRelease)
echo JAVA_HOME: %JAVA_HOME%
echo ANDROID_HOME: %ANDROID_HOME%
echo ===================================================

cd /d "%SCRIPT_DIR%..\android"
call gradlew.bat assembleRelease --no-daemon

if %ERRORLEVEL% equ 0 (
    echo.
    echo ===================================================
    echo SUCCESS! APK Generated Successfully!
    echo Location: %SCRIPT_DIR%..\android\app\build\outputs\apk\release\app-release.apk
    echo ===================================================
) else (
    echo.
    echo [ERROR] APK build failed with code %ERRORLEVEL%
)
