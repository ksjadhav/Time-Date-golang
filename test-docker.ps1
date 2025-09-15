# Test the Docker application locally on Windows PowerShell

Write-Host "[INFO] Testing Docker application locally..." -ForegroundColor Green
Write-Host ""

Write-Host "[INFO] Building Docker image..." -ForegroundColor Green
docker build -t date-time-go:local .

if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] Docker build failed" -ForegroundColor Red
    exit 1
}

Write-Host "[INFO] Starting Docker container..." -ForegroundColor Green
Write-Host "[INFO] Open http://localhost:8080 in your browser" -ForegroundColor Yellow
Write-Host "[INFO] Press Ctrl+C to stop the container" -ForegroundColor Yellow
Write-Host ""

docker run -p 8080:8080 date-time-go:local
