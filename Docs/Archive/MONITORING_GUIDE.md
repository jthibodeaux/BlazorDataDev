# Monitoring & Navigation Guide

## ?? Quick Start

### **Option 1: Simple Start (Recommended)**
```powershell
# In PowerShell
cd C:\Users\JohnThibodeaux\code\BlazorDbEditor
dotnet run
```

Then open: http://localhost:5000

### **Option 2: Monitored Start with Logging**
```powershell
# Run the monitoring script
.\start-monitored.ps1
```

This will:
- Start the application with enhanced logging
- Create a log file in `logs/` directory
- Automatically open the browser
- Display real-time logs in the console

### **Option 3: Navigate to Pages Interactively**
```powershell
# First, start the app
dotnet run

# Then in another terminal, run navigation script
.\navigate.ps1
```

## ?? Available Pages

| Page | URL | Description |
|------|-----|-------------|
| **Home** | http://localhost:5000 | Landing page with navigation |
| **Offline Editor** | http://localhost:5000/offline-editor | Load DDL, import CSV/JSON |
| **Data Editor** | http://localhost:5000/data-editor | CRUD operations on tables |
| **Migration Manager** | http://localhost:5000/migration-manager | Schema comparison |
| **SQL Query Tool** | http://localhost:5000/sql-query | Execute SQL with JOINs |
| **Swagger API** | http://localhost:5000/swagger | REST API docs & testing |

## ?? Monitoring Options

### **1. Console Logging (Real-time)**
```powershell
# Run with detailed logging
$env:ASPNETCORE_ENVIRONMENT="Development"
$env:Logging__LogLevel__Default="Debug"
dotnet run
```

**What you'll see:**
- Application startup messages
- Request logs (when you navigate)
- Error messages
- SQL queries (if database is connected)

### **2. File Logging**
```powershell
# Capture output to file
dotnet run > app-output.log 2>&1
```

Then monitor in real-time:
```powershell
Get-Content app-output.log -Wait
```

### **3. Visual Studio Output Window**
1. Open project in Visual Studio
2. Press `F5` to start debugging
3. View ? Output (or `Ctrl+Alt+O`)
4. Select "Debug" from dropdown

**Shows:**
- Blazor SignalR messages
- Page navigation events
- Component lifecycle events
- JavaScript interop calls

### **4. Browser Developer Tools**
Press `F12` in browser to open:

**Console Tab:**
- JavaScript errors
- Blazor reconnection messages
- Custom console.log outputs

**Network Tab:**
- HTTP requests to API endpoints
- SignalR WebSocket connection
- Static file loading times

**Application Tab:**
- Local storage data
- Session storage
- Service worker status

## ?? What to Monitor

### **During Startup:**
```
info: Microsoft.Hosting.Lifetime[14]
      Now listening on: http://localhost:5000
info: Microsoft.Hosting.Lifetime[0]
   Application started. Press Ctrl+C to shut down.
```

### **When Navigating to Offline Editor:**
- Watch for DDL parsing logs
- Schema loading messages
- Table count updates

### **When Importing Data:**
- Row count messages
- SQL generation logs
- Data store sync confirmations

### **When Using API:**
- HTTP request logs (GET, POST, PUT, DELETE)
- Status codes (200, 201, 404, etc.)
- Response times

### **When Querying with SQL:**
- Query translation logs (PostgreSQL ? SQLite)
- Execution time
- Result row counts

## ??? Useful PowerShell Commands

### **Check if Application is Running:**
```powershell
# Test if port 5000 is responding
Test-NetConnection -ComputerName localhost -Port 5000

# Or use Invoke-WebRequest
Invoke-WebRequest -Uri http://localhost:5000 -UseBasicParsing
```

### **Find Running .NET Processes:**
```powershell
Get-Process -Name dotnet
```

### **Kill Application if Stuck:**
```powershell
# Find process ID
Get-Process -Name dotnet | Select-Object Id, ProcessName

# Kill it
Stop-Process -Name dotnet -Force
```

### **Clear Port 5000 if Busy:**
```powershell
# Find what's using port 5000
netstat -ano | findstr :5000

# Kill that process (replace PID with actual process ID)
taskkill /PID <PID> /F
```

### **Open All Pages at Once:**
```powershell
.\open-all-pages.ps1
```

## ?? Log Levels

Modify `appsettings.Development.json` to change verbosity:

```json
{
  "Logging": {
    "LogLevel": {
      "Default": "Information",         // General logs
      "Microsoft.AspNetCore": "Warning",// Framework logs
 "BlazorDbEditor": "Debug"       // Your app logs
    }
  }
}
```

**Log Levels (least to most verbose):**
- `None` - No logs
- `Critical` - Only critical errors
- `Error` - Errors and above
- `Warning` - Warnings and above
- `Information` - Informational messages and above ? Recommended
- `Debug` - Detailed debugging information
- `Trace` - Very detailed trace information

## ?? Monitoring Workflow

### **1. Start Application**
```powershell
dotnet run
```

### **2. Open Browser**
Navigate to: http://localhost:5000

### **3. Test Workflow**
1. **Home Page** ? Click "Offline Editor"
2. **Offline Editor** ? Load a DDL file
3. **Watch Console** ? See table parsing logs
4. **Import Data** ? Upload CSV/JSON
5. **Check Data Editor** ? View imported data
6. **Test API** ? Go to Swagger, try endpoints
7. **SQL Query** ? Execute a query with JOIN

### **4. Monitor Each Action**
- **Console:** See request logs
- **Browser DevTools:** See client-side activity
- **Network Tab:** See API calls and responses

## ?? Troubleshooting Monitoring

### **No Logs Appearing:**
```powershell
# Ensure Development environment
$env:ASPNETCORE_ENVIRONMENT="Development"
dotnet run
```

### **Port Already in Use:**
```powershell
# Change port in launchSettings.json or use:
dotnet run --urls "http://localhost:5555"
```

### **Application Won't Start:**
```powershell
# Clean and rebuild
dotnet clean
dotnet build
dotnet run
```

### **Browser Won't Connect:**
- Check Windows Firewall
- Verify port 5000 is not blocked
- Try `http://127.0.0.1:5000` instead

## ?? What I Can See

When you run the application, I can monitor:
- ? Startup messages and port binding
- ? Configuration loading
- ? Error messages and exceptions
- ? Application shutdown signals

When you provide logs/output, I can analyze:
- ? HTTP request patterns
- ? Performance bottlenecks
- ? Error stack traces
- ? Database query issues

## ?? Example Monitoring Session

```powershell
# Terminal 1: Start app with logging
PS> dotnet run
info: Microsoft.Hosting.Lifetime[14]
      Now listening on: http://localhost:5000
info: Microsoft.Hosting.Lifetime[0]
  Application started.

# Terminal 2: Open pages
PS> .\navigate.ps1
  1. Home Page
  2. Offline Editor
  3. Data Editor
  ...
Enter choice: 2

# Browser: Navigate to Offline Editor
# Terminal 1 shows:
info: Microsoft.AspNetCore.Routing.EndpointMiddleware[0]
      Executing endpoint '/_blazor'
info: Microsoft.AspNetCore.SignalR[0]
   Connected to Blazor hub

# Load DDL file
# Terminal 1 shows:
info: BlazorDbEditor.Pages.OfflineEditor[0]
      DDL loaded successfully (15 tables found)
info: BlazorDbEditor.Services.InMemoryDataStore[0]
      Synced 15 table schemas to data store
```

## ?? Sharing Logs with Me

To share logs for analysis:

### **Option 1: Copy Console Output**
```powershell
dotnet run 2>&1 | Tee-Object -FilePath monitoring.log
# Then share the monitoring.log file content
```

### **Option 2: Screenshot**
- Take screenshot of console output
- Take screenshot of browser DevTools console
- Share both images

### **Option 3: Describe What You See**
"When I navigate to /offline-editor, I see..."
"After importing CSV, the console shows..."
"When I click Submit, the network tab displays..."

## ?? Ready to Start!

Run this command to begin:
```powershell
dotnet run
```

Then navigate to: **http://localhost:5000**

Happy monitoring! ??
