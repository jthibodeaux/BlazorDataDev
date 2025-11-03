# Quick Navigation Commands for Blazor DB Editor
# Copy and paste these commands in your browser or terminal

Write-Host "?? Blazor DB Editor - Quick Navigation" -ForegroundColor Cyan
Write-Host "?????????????????????????????????????????" -ForegroundColor DarkGray
Write-Host ""

$urls = @(
    @{Name="Home Page"; Url="http://localhost:5000"; Description="Landing page with navigation cards"},
    @{Name="Offline Editor"; Url="http://localhost:5000/offline-editor"; Description="Load DDL, import data, generate SQL"},
    @{Name="Data Editor"; Url="http://localhost:5000/data-editor"; Description="CRUD interface for table data"},
    @{Name="Migration Manager"; Url="http://localhost:5000/migration-manager"; Description="Schema comparison and migration"},
    @{Name="SQL Query Tool"; Url="http://localhost:5000/sql-query"; Description="Execute SQL queries with JOINs"},
    @{Name="Swagger API"; Url="http://localhost:5000/swagger"; Description="REST API documentation and testing"}
)

Write-Host "Available Pages:" -ForegroundColor Yellow
Write-Host ""

foreach ($item in $urls) {
    Write-Host "  ?? " -NoNewline -ForegroundColor Blue
    Write-Host $item.Name -NoNewline -ForegroundColor White
    Write-Host ""
    Write-Host "     URL: " -NoNewline -ForegroundColor DarkGray
    Write-Host $item.Url -ForegroundColor Green
    Write-Host "     " -NoNewline
    Write-Host $item.Description -ForegroundColor DarkGray
    Write-Host ""
}

Write-Host "?????????????????????????????????????????" -ForegroundColor DarkGray
Write-Host ""
Write-Host "?? Commands:" -ForegroundColor Yellow
Write-Host "  Open all pages:  " -NoNewline -ForegroundColor DarkGray
Write-Host ".\open-all-pages.ps1" -ForegroundColor Cyan
Write-Host "  Open specific:   " -NoNewline -ForegroundColor DarkGray
Write-Host 'Start-Process "http://localhost:5000/offline-editor"' -ForegroundColor Cyan
Write-Host "  Check status:    " -NoNewline -ForegroundColor DarkGray
Write-Host 'Invoke-WebRequest http://localhost:5000 -UseBasicParsing' -ForegroundColor Cyan
Write-Host ""

# Ask user which page to open
Write-Host "Which page would you like to open? (1-6, or 'all' for all pages, 'q' to quit):" -ForegroundColor Yellow
$choice = Read-Host "Enter choice"

switch ($choice) {
"1" { Start-Process $urls[0].Url }
    "2" { Start-Process $urls[1].Url }
 "3" { Start-Process $urls[2].Url }
    "4" { Start-Process $urls[3].Url }
    "5" { Start-Process $urls[4].Url }
    "6" { Start-Process $urls[5].Url }
    "all" {
        Write-Host "Opening all pages..." -ForegroundColor Cyan
     foreach ($item in $urls) {
            Start-Process $item.Url
            Start-Sleep -Milliseconds 500
        }
    }
    "q" { 
        Write-Host "Goodbye!" -ForegroundColor Green
  exit 
    }
    default {
        Write-Host "Invalid choice. Opening home page..." -ForegroundColor Yellow
        Start-Process $urls[0].Url
  }
}

Write-Host ""
Write-Host "? Page(s) opened!" -ForegroundColor Green
