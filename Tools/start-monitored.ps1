# Blazor DB Editor - Monitoring & Navigation Script
# This script starts the application with enhanced logging and provides navigation commands

Write-Host "?? Starting Blazor DB Editor with Enhanced Monitoring..." -ForegroundColor Cyan
Write-Host ""

# Set environment for enhanced logging
$env:ASPNETCORE_ENVIRONMENT = "Development"
$env:ASPNETCORE_URLS = "http://localhost:5000;https://localhost:5001"

# Create log directory if it doesn't exist
$logDir = "logs"
if (-not (Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir | Out-Null
}

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$logFile = "$logDir/app-$timestamp.log"

Write-Host "?? Application URLs:" -ForegroundColor Yellow
Write-Host "  Home:   http://localhost:5000" -ForegroundColor White
Write-Host "  Offline Editor:    http://localhost:5000/offline-editor" -ForegroundColor White
Write-Host "  Data Editor:       http://localhost:5000/data-editor" -ForegroundColor White
Write-Host "  Migration Manager: http://localhost:5000/migration-manager" -ForegroundColor White
Write-Host "  SQL Query Tool:    http://localhost:5000/sql-query" -ForegroundColor White
Write-Host "  Swagger API:  http://localhost:5000/swagger" -ForegroundColor Green
Write-Host ""
Write-Host "?? Logging to: $logFile" -ForegroundColor Magenta
Write-Host ""
Write-Host "??  Starting application... (Press Ctrl+C to stop)" -ForegroundColor Cyan
Write-Host "??????????????????????????????????????????????????????" -ForegroundColor DarkGray
Write-Host ""

# Start the application with logging
try {
    # Start dotnet run and capture output
    $process = Start-Process -FilePath "dotnet" -ArgumentList "run" -NoNewWindow -PassThru -RedirectStandardOutput $logFile -RedirectStandardError "$logFile.err"
    
    # Wait a moment for startup
    Start-Sleep -Seconds 3
    
    # Check if process is running
    if ($process.HasExited) {
  Write-Host "? Application failed to start. Check error log: $logFile.err" -ForegroundColor Red
        if (Test-Path "$logFile.err") {
         Get-Content "$logFile.err"
     }
        exit 1
    }
    
    Write-Host "? Application started successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "?? Opening browser..." -ForegroundColor Cyan
    Start-Sleep -Seconds 2
    Start-Process "http://localhost:5000"
    
    Write-Host ""
    Write-Host "?? Monitoring logs (Ctrl+C to stop)..." -ForegroundColor Yellow
    Write-Host "??????????????????????????????????????????????????????" -ForegroundColor DarkGray
  Write-Host ""
    
 # Tail the log file
    Get-Content $logFile -Wait
}
catch {
    Write-Host "? Error: $_" -ForegroundColor Red
}
finally {
    if ($process -and -not $process.HasExited) {
  Write-Host ""
  Write-Host "?? Stopping application..." -ForegroundColor Yellow
        Stop-Process -Id $process.Id -Force
     Write-Host "? Application stopped" -ForegroundColor Green
    }
}
