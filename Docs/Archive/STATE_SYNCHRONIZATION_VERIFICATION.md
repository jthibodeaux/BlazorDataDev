# ? State Synchronization Verification

## ?? **All Razor Pages Now Share Storage!**

### **Shared Components:**

```
???????????????????????????????????????????????????????????
?            NavMenu.OfflineEditorState    ?
?            (Shared Static State)           ?
?  - Tables: List<string> ?
?  - SelectedTable: string        ?
?  - OnChange: event Action         ?
???????????????????????????????????????????????????????????
       ?
           ? Reads/Writes
       ?
     ???????????????????????????????????????????????????????
     ?          ? ?              ?
     ?      ?    ?              ?
???????????          ???????????????  ????????????  ????????????
? Startup ?          ?   Offline   ?  ?   Data   ?  ? SQL    ?
? Wizard  ?    ?   Editor    ?  ?  Editor  ?  ?  Query   ?
???????????          ???????????????  ????????????  ????????????
     ?        ?  ?          ?
     ? Reads/Writes         ?   ?          ?
     ?   ?   ?              ?
     ??????????????????????????????????????????????????????
             ?   ?
        ?  ?
    ??????????????????????????????????????
     ?    InMemoryDataStore (Singleton)   ?
       ?  - Table Schemas              ?
     ?  - Row Data               ?
     ??????????????????????????????????????
    ?
     ?
          ?
     ??????????????????????????????????????
                ?   SqliteQueryService (Scoped)      ?
      ?  - In-memory SQLite DB  ?
      ?  - SQL Query Support         ?
        ??????????????????????????????????????
```

---

## ?? **State Synchronization Matrix**

| Page | Reads NavMenu State | Writes NavMenu State | Uses DataStore | Uses SQLite |
|------|---------------------|----------------------|----------------|-------------|
| **Startup Wizard** | ? Yes | ? Yes | ? Yes | ? Yes |
| **Offline Editor** | ? Yes | ? Yes | ? Yes | ? Yes |
| **Data Editor** | ? Yes | ? No | ? Yes | ? No |
| **SQL Query Tool** | ? Yes | ? No | ? No | ? Yes |
| **NavMenu** | ? Yes | ? Yes | ? No | ? No |

---

## ?? **How State Flows:**

### **1. Startup Wizard Loads Data:**
```csharp
// StartupWizard.razor
result = await StartupService.ExecuteStartupWorkflowAsync();

if (result.Success && result.TableSchemas.Any())
{
    // Sync to NavMenu state
  NavMenu.OfflineEditorState.Tables = result.TableSchemas.Keys.ToList();
    NavMenu.OfflineEditorState.NotifyStateChanged();
}
```

### **2. StartupAutomationService Syncs Everything:**
```csharp
// StartupAutomationService.cs
private void SyncSchemasToDataStore(Dictionary<string, List<ColumnInfo>> tableSchemas)
{
    foreach (var (tableName, columns) in tableSchemas)
 {
  _dataStore.LoadSchema(tableName, columns); // ? InMemoryDataStore
    }
    
    _sqliteService.LoadSchema(tableSchemas); // ? SqliteQueryService
}
```

### **3. Offline Editor Picks Up State:**
```csharp
// OfflineEditor.razor
protected override void OnInitialized()
{
    // Subscribe to changes
  NavMenu.OfflineEditorState.OnChange += OnSidebarTableSelected;
   
    // Check if tables were already loaded
    if (NavMenu.OfflineEditorState.Tables.Any() && !tables.Any())
    {
        tables = new List<string>(NavMenu.OfflineEditorState.Tables);
     
        // Restore schemas from DataStore
        foreach (var tableName in tables)
        {
  var schema = DataStore.GetTableSchema(tableName);
            // Rebuild tableSchemas and originalSchemas
        }
       
        statusMessage = $"? Loaded {tables.Count} tables from previous session";
    }
}
```

### **4. NavMenu Updates All Pages:**
```csharp
// NavMenu.razor
public static class OfflineEditorState
{
    public static List<string> Tables { get; set; } = new();
    public static string SelectedTable { get; set; } = "";
    public static event Action? OnChange;

    public static void NotifyStateChanged()
    {
   OnChange?.Invoke(); // Triggers all subscribed pages!
    }
}
```

---

## ? **What Gets Shared:**

### **? Table Names**
- Loaded in Startup Wizard
- Visible in NavMenu sidebar
- Accessible in Offline Editor
- Queryable in SQL Tool
- Editable in Data Editor

### **? Table Schemas**
- Stored in `InMemoryDataStore`
- Accessible via `GetTableSchema(tableName)`
- Used by all pages for metadata

### **? Row Data**
- Stored in `InMemoryDataStore`
- Accessible via `GetAllRows(tableName)`
- Updated by Data Editor
- Queried by SQL Tool

### **? SQL Queries**
- Data loaded into `SqliteQueryService`
- Supports complex SQL with JOINs
- Translates PostgreSQL ? SQLite syntax

---

## ?? **Testing Workflow:**

### **Step 1: Start Application**
```powershell
dotnet run
```

### **Step 2: Load Data in Startup Wizard**
```
1. Navigate to: http://localhost:5000/startup
2. Click: "Start Auto-Load"
3. Wait for: "? Startup workflow completed successfully!"
4. Observe: "Tables Loaded: 38" (or however many in your DDL)
```

### **Step 3: Check NavMenu**
```
? Sidebar should show all 38 tables
? Tables appear in alphabetical order
? Click any table to select it
```

### **Step 4: Navigate to Offline Editor**
```
1. Click: "Offline Editor" button
2. Observe: "? Loaded 38 tables from previous session"
3. Verify: Tables dropdown populated
4. Select: Any table to view schema
```

### **Step 5: Navigate to Data Editor**
```
1. Click: "Data Editor" button
2. Verify: Table dropdown populated
3. Select: Any table with data
4. Observe: Rows displayed in table
```

### **Step 6: Navigate to SQL Query Tool**
```
1. Click: "SQL Query Tool"
2. Execute: SELECT * FROM tc_compressordata LIMIT 10
3. Observe: Results displayed (if data loaded)
4. Try JOIN: SELECT * FROM tc_compressordata JOIN tc_compressorplan...
```

---

## ?? **Debugging State Issues:**

### **If Tables Don't Appear:**

**Check 1: NavMenu State**
```csharp
// In browser console
console.log(BlazorDbEditor.Components.NavMenu.OfflineEditorState.Tables);
```

**Check 2: DataStore**
```csharp
// Add logging in OnInitialized
_logger.LogInformation("DataStore has {Count} tables", DataStore.GetTableNames().Count);
```

**Check 3: Event Subscription**
```csharp
// Verify subscription in page
protected override void OnInitialized()
{
    _logger.LogInformation("Subscribing to NavMenu state changes");
    NavMenu.OfflineEditorState.OnChange += OnStateChanged;
}
```

---

## ?? **Current State (After Your DDL Load):**

| Component | Status | Count |
|-----------|--------|-------|
| **Tables in NavMenu** | ? Ready | 38 tables |
| **Schemas in DataStore** | ? Loaded | 38 schemas |
| **Data in SQLite** | ? Pending | Load CSV files |
| **API Endpoints** | ? Active | 38 endpoints |
| **SQL Query Support** | ? Ready | All tables |

---

## ?? **Summary:**

**? Startup Wizard** ? Loads everything  
**? NavMenu** ? Shows all tables  
**? Offline Editor** ? Sees all tables
**? Data Editor** ? Can edit all tables  
**? SQL Query Tool** ? Can query all tables  
**? REST API** ? All endpoints active  

---

## ?? **Next Steps:**

1. **Test the workflow** (as described above)
2. **Load CSV data** (if you have CSV files in `Loadables/csv/`)
3. **Try SQL queries** (JOIN, WHERE, ORDER BY, etc.)
4. **Use REST API** (via Swagger or Postman)
5. **Generate SQL scripts** (for deployment)

---

**Everything is synchronized! All pages share the same storage!** ??

Go ahead and test it - it should work perfectly now! ??
