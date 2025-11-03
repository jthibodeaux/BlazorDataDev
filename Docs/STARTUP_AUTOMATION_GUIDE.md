# ?? Startup Automation - Quick Start Guide

## ? What You Get

**Automated startup workflow** that:
- ? Loads your DDL file automatically
- ? Imports all CSV files (filename = table name)
- ? Generates SQL INSERT script
- ? Saves workspace for quick reload
- ? **NO MORE MANUAL STEPS!**

---

## ?? Setup (One-Time)

### **1. Create Loadables Folder Structure**

```
BlazorDbEditor/
??? Loadables/
    ??? your_schema.sql   ? Your DDL file
    ??? tc_compressordata.csv    ? CSV files (name = table name)
 ??? tc_compressorplan.csv
    ??? tc_dailymeterreadings.csv
  ??? tc_pipemeasurements.csv
```

### **2. Prepare Your Files**

**DDL File:**
- Any `.sql` file with CREATE TABLE statements
- PostgreSQL format
- Can have multiple tables

**CSV Files:**
- **IMPORTANT:** Filename MUST match table name!
- `tc_compressordata.csv` ? loads into `tc_compressordata` table
- First row = headers
- Standard CSV format

---

## ?? Two Startup Modes

### **Mode 1: Auto-Load (First Time or Fresh Data)** ?

**When to use:**
- First time setup
- You have new/updated CSV files
- You want fresh data

**Steps:**
1. Start app: `dotnet run`
2. Navigate to: http://localhost:5000/startup
3. Click: **"Start Auto-Load"**
4. Wait ~5-10 seconds
5. **Done!** All data loaded

**What happens:**
```
? Loads DDL (15 tables)
? Loads tc_compressordata.csv (258 rows)
? Loads tc_compressorplan.csv (325 rows)
? Loads tc_dailymeterreadings.csv (102 rows)
? Loads tc_pipemeasurements.csv (156 rows)
? Generates SQL script ? Loadables/output/generated_inserts_*.sql
? Saves workspace ? Loadables/output/auto_workspace_*.json
```

### **Mode 2: Load Workspace (Quick Restart)** ?

**When to use:**
- Subsequent startups
- You don't need to re-import CSVs
- Super fast (1-2 seconds)

**Steps:**
1. Start app: `dotnet run`
2. Navigate to: http://localhost:5000/startup
3. Click: **"Load Workspace"**
4. **Done!** Schemas loaded instantly

**What happens:**
```
? Loads saved workspace
? Restores all table schemas
? Ready to import new data if needed
```

---

## ?? Complete Workflow Example

### **First Time:**

```powershell
# 1. Create folder
mkdir Loadables
cd Loadables

# 2. Copy your files
copy C:\path\to\your\schema.sql .
copy C:\path\to\csvs\*.csv .

# 3. Start app
cd ..
dotnet run

# 4. Open browser
start http://localhost:5000/startup

# 5. Click "Start Auto-Load"
# Wait ~5-10 seconds

# 6. All done! Navigate to:
# - Data Editor to view data
# - Swagger API to test endpoints
# - SQL Query to run queries
```

### **Next Time (Quick):**

```powershell
# 1. Start app
dotnet run

# 2. Open browser
start http://localhost:5000/startup

# 3. Click "Load Workspace"
# Done in 1-2 seconds!
```

---

## ?? What Gets Loaded

| Component | Auto-Load | Load Workspace |
|-----------|-----------|----------------|
| DDL Schemas | ? | ? |
| CSV Data | ? | ? (import separately) |
| SQL Script Generated | ? | ? |
| API Endpoints | ? | ? |
| Data Editor | ? | ? (until data imported) |
| SQL Query Tool | ? | ? (until data imported) |

---

## ?? After Auto-Load, You Can:

### **1. View Data in Data Editor**
- Navigate to: http://localhost:5000/data-editor
- Browse all tables
- Add/edit/delete rows

### **2. Test API in Swagger**
- Navigate to: http://localhost:5000/swagger
- Test GET, POST, PUT, DELETE endpoints
- All tables automatically available

### **3. Run SQL Queries**
- Navigate to: http://localhost:5000/sql-query
- Execute SELECT queries with JOINs
- Data already loaded in SQLite

### **4. Use Generated SQL Script**
- File: `Loadables/output/generated_inserts_*.sql`
- Contains all INSERT statements
- Run on your real PostgreSQL database

### **5. Save for Later**
- File: `Loadables/output/auto_workspace_*.json`
- Quick reload next time
- No need to re-import CSVs

---

## ?? Configuration (Optional)

Edit `startup-config.json` in project root:

```json
{
  "startupMode": "automated",
  "dataPaths": {
    "ddlDirectory": "Loadables",
    "csvDirectory": "Loadables",
    "outputDirectory": "Loadables/output"
  },
  "options": {
    "autoSaveOnComplete": true,
    "generateSQLOnLoad": true,
    "dateShiftToToday": false,
    "verboseLogging": true
  }
}
```

---

## ?? Troubleshooting

### **"No DDL file found"**
? Add a `.sql` file to `Loadables/` folder

### **"Table not found, skipping CSV"**
? Rename CSV to match table name exactly

### **"Loadables folder not found"**
? Folder created automatically on first run
? Add your files and try again

### **Want manual control?**
? Skip startup wizard
? Navigate to: http://localhost:5000/offline-editor
? Load files manually as before

---

## ?? Summary

### **Before (Manual):**
1. Start app
2. Navigate to Offline Editor
3. Click "Load DDL"
4. Select file
5. Wait for parse
6. Click "Select Table"
7. Click "Import CSV"
8. Select file
9. Click "Import"
10. Repeat steps 6-9 for each table
11. Click "Generate SQL"
12. Click "Download"
13. Click "Save Workspace"

**Total: ~15 clicks, ~5 minutes**

### **After (Automated):**
1. Start app
2. Navigate to Startup
3. Click "Start Auto-Load"

**Total: 3 clicks, ~10 seconds** ??

---

## ?? Get Started Now!

```powershell
# 1. Create Loadables folder
mkdir Loadables

# 2. Add your DDL and CSV files
# (filename of CSV must match table name!)

# 3. Start the app
dotnet run

# 4. Open browser
start http://localhost:5000/startup

# 5. Click "Start Auto-Load"
```

**That's it!** ?

---

**Questions?** Check `Loadables/README.md` for detailed documentation.
