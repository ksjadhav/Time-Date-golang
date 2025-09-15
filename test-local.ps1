# Test the Go application locally on Windows PowerShell

Write-Host "[INFO] Testing Go application locally..." -ForegroundColor Green
Write-Host ""

Write-Host "[INFO] Starting Go application..." -ForegroundColor Green
Write-Host "[INFO] Open http://localhost:8080 in your browser" -ForegroundColor Yellow
Write-Host "[INFO] Press Ctrl+C to stop the application" -ForegroundColor Yellow
Write-Host ""

go run main.go
