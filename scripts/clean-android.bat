@echo off
set "SCRIPT_DIR=%~dp0"
for %%I in ("%SCRIPT_DIR%..\scratch\jdk-17.0.12+7") do set "JAVA_HOME=%%~fI"
set "ANDROID_HOME=C:\Users\Tushal\AppData\Local\Android\Sdk"
set "PATH=%JAVA_HOME%\bin;%ANDROID_HOME%\platform-tools;%PATH%"

echo ===================================================
echo Cleaning Flutter Build Cache (flutter clean)
echo ===================================================

cd /d "%SCRIPT_DIR%.."
call flutter clean
call flutter pub get

if %ERRORLEVEL% equ 0 (
    echo.
    echo [SUCCESS] Flutter clean completed successfully!
) else (
    echo.
    echo [ERROR] Clean failed with code %ERRORLEVEL%
)
