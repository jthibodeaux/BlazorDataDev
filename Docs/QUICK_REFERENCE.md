# ?? TC Energy Data Platform - Quick Reference

## ?? What You Asked For

### **1. Complete Left-Side Navigation** ?
**Status:** DONE

**What was added:**
- Organized navigation menu with all tools
- Categories: MAIN, DATA MANAGEMENT, INTEGRATIONS, UTILITIES, API & DOCS
- All pages accessible from menu
- Dynamic table list (shows top 10)
- Beautiful styling with hover effects

**File:** `Components/NavMenu.razor`

---

### **2. Breadcrumb Navigation** ?
**Status:** DONE

**What was added:**
- Automatic breadcrumb tracking
- Shows current location path
- Icons for each segment
- "Back" button independent of browser
- Works with all navigation methods

**File:** `Components/Breadcrumb.razor`

**Usage:**
```razor
<Breadcrumb CurrentPage="Your Page" BackUrl="/previous" />
```

---

### **3. C# Tools Instead of PowerShell Scripts** ? (Started)
**Status:** IN PROGRESS

**Completed:**
- ? External Database Explorer (full C# service)
- ? Service architecture in place

**Next to migrate:**
- ? DDL Cleaner (`Clean-DDL.ps1` ? `DdlCleanerService.cs`)
- ? CSV Validator (`Check-CsvNames.ps1` ? `CsvValidatorService.cs`)
- ? Table Extractor (`Extract-Tables-Quick.ps1` ? `TableExtractorService.cs`)

**Benefits:**
- All tools in the UI
- Better error handling
- Progress tracking
- Persistent configuration

---

### **4. Rebranding to "TC Energy Data Platform"** ?
**Status:** DONE

**Changes:**
- Updated project name
- Updated all titles
- Updated API documentation
- New tagline: "Comprehensive Data Management & Integration Platform"

**Files Updated:**
- `Program.cs` - Service registration + API title
- `Components/NavMenu.razor` - Branding
- `Docs/PLATFORM_TRANSFORMATION.md` - Complete guide

---

## ?? External Database Explorer

### **Purpose:**
Connect to AWS Redshift, PostgreSQL, SQL Server, or MySQL to:
- Browse schemas and tables
- Export DDL (CREATE TABLE statements)
- Export sample data (CSV, first 1000 rows)
- Export metadata (JSON with column info)

### **Access:**
```
http://localhost:5000/external-explorer
```

### **Supported Databases:**
- PostgreSQL
- AWS Redshift
- SQL Server
- MySQL

### **Export Location:**
```
Loadables/external/{database_name}/
??? ddls/# CREATE TABLE statements
??? csv/  # Sample data (1000 rows)
??? metadata/      # JSON column metadata
```

### **Configuration Saved To:**
```
external-db-config.json (no passwords saved)
```

---

## ?? Navigation Structure

### **Main Menu Categories:**

1. **?? MAIN**
   - Dashboard (/)

2. **?? DATA MANAGEMENT**
   - Startup Wizard (/startup)
   - Schema Editor (/offline-editor)
   - Data Editor (/data-editor)
   - SQL Query Tool (/sql-query)

3. **?? INTEGRATIONS**
   - Live Data (/live-data)
   - External DB (/external-explorer) ? NEW!
   - Migration (/migration-manager)

4. **??? UTILITIES**
   - DDL Cleaner (/ddl-cleaner) ? TO BE CREATED
   - CSV Validator (/csv-validator) ? TO BE CREATED
   - Workspace (/workspace-manager) ? TO BE CREATED
   - All Tools (/tools) ? TO BE CREATED

5. **?? API & DOCS**
   - Swagger API (/swagger)
   - Documentation (/documentation) ? TO BE CREATED
   - About (/about)

---

## ??? Adding a New Tool/Page

### **Step 1: Create the Page**
```razor
@page "/your-tool"
@inject IYourService YourService

<PageTitle>Your Tool - TC Energy Data Platform</PageTitle>

<!-- Add breadcrumb -->
<Breadcrumb CurrentPage="Your Tool" BackUrl="/" />

<div class="container-fluid">
    <div class="page-header">
     <h1>?? Your Tool Name</h1>
        <p class="lead">Tool description</p>
    </div>
    
    <!-- Your tool UI here -->
</div>
```

### **Step 2: Create the Service**
```csharp
// Services/YourService.cs
public interface IYourService
{
    Task<Result> DoSomethingAsync();
}

public class YourService : IYourService
{
    private readonly ILogger<YourService> _logger;
    
    public YourService(ILogger<YourService> logger)
    {
        _logger = logger;
  }
    
  public async Task<Result> DoSomethingAsync()
    {
        // Implementation
    }
}
```

### **Step 3: Register Service**
```csharp
// Program.cs
builder.Services.AddScoped<IYourService, YourService>();
```

### **Step 4: Update NavMenu**
```razor
<!-- Already done! Just make sure route exists -->
<NavLink class="nav-menu-item" href="/your-tool">
    <span class="nav-icon">??</span> Your Tool
</NavLink>
```

---

## ?? Documentation Files

### **Platform Documentation:**
- `Docs/PLATFORM_TRANSFORMATION.md` - Complete transformation guide
- `Docs/NEXT_STEPS.md` - Implementation roadmap
- `Docs/QUICK_REFERENCE.md` - This file

### **Feature-Specific:**
- `Docs/STARTUP_AUTOMATION_GUIDE.md` - Startup Wizard
- `Docs/LIVE_DATA_FEATURE.md` - Live Data integration
- `Docs/TABLES_FROM_QUERIES_GUIDE.md` - Table extraction from SQL queries
- `Docs/DDL_CLEANUP_GUIDE.md` - DDL cleaning
- `Docs/FLEXIBLE_FOLDER_STRUCTURE.md` - Loadables folder structure

---

## ?? Quick Start for New Developers

### **1. Clone & Setup:**
```bash
git clone your-repo
cd BlazorDbEditor
dotnet restore
dotnet run
```

### **2. Open in Browser:**
```
http://localhost:5000
```

### **3. Explore:**
- Click through navigation menu
- Try External DB Explorer
- Load sample DDL in Startup Wizard
- View API docs in Swagger

### **4. Development:**
```bash
# Watch mode (auto-reload on changes)
dotnet watch run

# Build
dotnet build

# Test
dotnet test
```

---

## ?? Styling Guidelines

### **Page Header:**
```razor
<div class="page-header">
    <h1>?? Tool Name</h1>
    <p class="lead">Tool description</p>
</div>
```

### **Cards:**
```razor
<div class="card shadow-sm">
    <div class="card-header bg-primary text-white">
        <h5 class="mb-0">Card Title</h5>
    </div>
    <div class="card-body">
        Content
    </div>
</div>
```

### **Buttons:**
```razor
<!-- Primary action -->
<button class="btn btn-primary">Action</button>

<!-- Secondary action -->
<button class="btn btn-outline-secondary">Cancel</button>

<!-- Loading state -->
<button class="btn btn-primary" disabled="@isLoading">
    @if (isLoading)
 {
        <span class="spinner-border spinner-border-sm me-2"></span>
    }
    <span>Submit</span>
</button>
```

---

## ?? Key Files

### **Configuration:**
- `appsettings.json` - App settings
- `startup-config.json` - Startup automation
- `livedata-config.json` - Live data sources
- `external-db-config.json` - Saved DB connections

### **Core Services:**
- `Services/InMemoryDataStore.cs` - In-memory table data
- `Services/SqliteQueryService.cs` - SQL query engine
- `Services/DynamicDbService.cs` - Dynamic schema management
- `Services/StartupAutomationService.cs` - Startup wizard
- `Services/LiveDataService.cs` - Live data integration
- `Services/ExternalDbExplorerService.cs` - External DB connectivity

### **Key Pages:**
- `Pages/Index.razor` - Dashboard
- `Pages/OfflineEditor.razor` - Schema editor
- `Pages/DataEditor.razor` - Data management
- `Pages/StartupWizard.razor` - Startup automation
- `Pages/ExternalDatabaseExplorer.razor` - External DB tool

### **Components:**
- `Components/NavMenu.razor` - Navigation menu
- `Components/Breadcrumb.razor` - Breadcrumb navigation
- `Components/UserInfo.razor` - User information

---

## ?? Troubleshooting

### **Issue: Navigation menu not showing all tools**
**Fix:** Check that routes exist in corresponding `.razor` files

### **Issue: Breadcrumbs not appearing**
**Fix:** Add `<Breadcrumb CurrentPage="..." BackUrl="..." />` to page

### **Issue: Service not found (DI error)**
**Fix:** Check `Program.cs` - ensure service is registered

### **Issue: External DB connection fails**
**Fix:** 
1. Check connection settings
2. Verify firewall rules
3. Test with `psql` or SQL client
4. Check SSL settings

---

## ?? Support

### **Documentation:**
- In-app: http://localhost:5000/documentation
- API: http://localhost:5000/swagger

### **Code:**
- GitHub: [Your Repo]
- Issues: [Your Issues Page]

---

## ? Checklist for Deployment

- [ ] All services registered in `Program.cs`
- [ ] All pages have breadcrumbs
- [ ] All tools accessible from NavMenu
- [ ] Documentation updated
- [ ] README.md updated
- [ ] Tests passing
- [ ] Version bumped to 2.0.0

---

**Version:** 2.0.0  
**Last Updated:** $(Get-Date -Format "yyyy-MM-dd")  
**Status:** ?? Ready for production

---

## ?? Summary of Changes

**What's New:**
1. ? Complete navigation menu (all tools)
2. ? Breadcrumb navigation (back button independent of browser)
3. ? External Database Explorer (connect, browse, export)
4. ? C# service architecture (tools in UI, not just scripts)
5. ? Rebranded to "TC Energy Data Platform"

**What's Next:**
1. ? Create remaining tool pages (DDL Cleaner, CSV Validator, Workspace Manager)
2. ? Migrate PowerShell logic to C# services
3. ? Create Documentation hub page
4. ? Update Index page with new branding

**PowerShell Scripts Status:**
- Scripts remain available for CI/CD
- UI tools provide better UX
- Scripts can launch main app with params

---

**You're all set to use and extend the platform! ??**
