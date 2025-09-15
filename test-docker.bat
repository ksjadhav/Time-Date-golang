@echo off
REM Test the Docker application locally on Windows

echo [INFO] Testing Docker application locally...
echo.

echo [INFO] Building Docker image...
docker build -t date-time-go:local .

if errorlevel 1 (
    echo [ERROR] Docker build failed
    exit /b 1
)

echo [INFO] Starting Docker container...
echo [INFO] Open http://localhost:8080 in your browser
echo [INFO] Press Ctrl+C to stop the container
echo.

docker run -p 8080:8080 date-time-go:local
