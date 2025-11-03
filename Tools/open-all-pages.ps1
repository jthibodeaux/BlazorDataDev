# Open all application pages in separate browser tabs

Write-Host "?? Opening all Blazor DB Editor pages..." -ForegroundColor Cyan

$urls = @(
    "http://localhost:5000",
    "http://localhost:5000/offline-editor",
    "http://localhost:5000/data-editor",
    "http://localhost:5000/migration-manager",
    "http://localhost:5000/sql-query",
    "http://localhost:5000/swagger"
)

foreach ($url in $urls) {
    Write-Host "  Opening: $url" -ForegroundColor Green
    Start-Process $url
    Start-Sleep -Milliseconds 500
}

Write-Host ""
Write-Host "? All pages opened!" -ForegroundColor Green
Write-Host "   Check your browser tabs" -ForegroundColor DarkGray
