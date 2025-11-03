# ?? Quick Start - Monitoring Edition

## Start Application
```powershell
cd C:\Users\JohnThibodeaux\code\BlazorDbEditor
dotnet run
```

## Access URLs
- **Home:** http://localhost:5000
- **Swagger:** http://localhost:5000/swagger
- **Offline Editor:** http://localhost:5000/offline-editor

## Quick Scripts
```powershell
.\start-monitored.ps1    # Start with logging
.\navigate.ps1           # Interactive navigation
.\open-all-pages.ps1     # Open all pages
```

## Monitor in Real-Time
```powershell
# Watch logs
Get-Content logs/app-*.log -Wait -Tail 20

# Check if running
Test-NetConnection localhost -Port 5000
```

## Browser DevTools (F12)
- **Console:** JavaScript errors & logs
- **Network:** API calls & responses
- **Application:** Storage & state

## Common Commands
```powershell
# Stop application
Ctrl+C

# Kill if stuck
Stop-Process -Name dotnet -Force

# Change port
dotnet run --urls "http://localhost:5555"

# Clean rebuild
dotnet clean && dotnet build && dotnet run
```

## Share Logs
```powershell
# Capture to file
dotnet run 2>&1 | Tee-Object -FilePath share-log.txt
```

---
**Ready?** Run `dotnet run` and open http://localhost:5000 ??
