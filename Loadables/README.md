# Loadables Folder - Startup Automation

## ?? Folder Structure

```
Loadables/
??? README.md          ? This file
??? schema.sql         ? Your PostgreSQL DDL file (REQUIRED) - OR use ddls/ folder
??? ddls/              ? Alternative: Put DDL files here
?   ??? schema.sql
??? csv/      ? Put your CSV files here (filename = table name)
?   ??? tc_compressordata.csv
?   ??? tc_compressorplan.csv
?   ??? tc_dailymeterreadings.csv
?   ??? tc_pipemeasurements.csv
??? output/          ? Auto-generated files
    ??? generated_inserts_*.sql
    ??? auto_workspace_*.json
```

**Flexible Organization:**
- DDL files can be in root (`Loadables/`) or `ddls/` subfolder
- CSV files can be in root (`Loadables/`) or `csv/` subfolder
- System searches all locations automatically!

---

## ?? How It Works

### **Automated Startup Workflow:**

1. **Navigate to:** http://localhost:5000/startup
2. **Click:** "Start Auto-Load"
3. **System automatically:**
   - ? Searches for `.sql` files in:
     - `Loadables/`
     - `Loadables/ddls/`
     - `Loadables/ddl/`
   - ? Parses all table schemas
   - ? Searches for `.csv` files in:
     - `Loadables/`
     - `Loadables/csv/`
   - `Loadables/csvs/`
   - ? Loads ALL CSV files (filename must match table name)
- ? Generates SQL INSERT statements
   - ? Syncs data to API endpoints
   - ? Saves workspace for quick reload
   - ? Saves SQL script to `output/` folder

### **Quick Reload:**

1. **Navigate to:** http://localhost:5000/startup
2. **Click:** "Load Workspace"
3. **System loads:** Previously saved workspace instantly

## ?? Requirements

### **1. DDL File (Required)**
- **Filename:** Any `.sql` file (e.g., `schema.sql`, `my-database.sql`)
- **Format:** PostgreSQL CREATE TABLE statements
- **Example:**
  ```sql
  CREATE TABLE dbo.tc_compressordata (
      ap_compressor varchar(50) NOT NULL,
      timestamp timestamp NOT NULL,
    bhp float8 NULL
  );
  ```

### **2. CSV Files (Optional)**
- **Filename:** Must match table name exactly
  - `tc_compressordata.csv` ? loads into `tc_compressordata` table
  - `tc_dailymeterreadings.csv` ? loads into `tc_dailymeterreadings` table
- **Format:** Standard CSV with header row
- **Example:**
  ```csv
  ap_compressor,timestamp,bhp
  GrundyCenter_Unit01,2025-10-18 01:00:00,14
  LaMaile_Unit01,2025-10-18 00:00:00,17
  ```

## ?? CSV Naming Convention

**IMPORTANT:** CSV filename must match table name!

| CSV Filename | Target Table |
|-------------|-------------|
| `tc_compressordata.csv` | ? `tc_compressordata` |
| `my_table.csv` | ? `my_table` |
| `MyTable.csv` | ? `MyTable` |
| `data.csv` | ? **SKIPPED** (no matching table) |

## ?? Output Files

### **Generated SQL Script**
- **Location:** `Loadables/output/generated_inserts_YYYYMMDD_HHMMSS.sql`
- **Contains:** All INSERT statements for imported data
- **Use:** Execute on your real PostgreSQL database

### **Workspace File**
- **Location:** `Loadables/output/auto_workspace_YYYYMMDD_HHMMSS.json`
- **Contains:** Table schemas and DDL (no data)
- **Use:** Quick reload without re-importing CSVs

## ?? Workflow Steps

### **First Time Setup:**

1. **Create Loadables folder** (if it doesn't exist)
2. **Add your DDL file:** `schema.sql`
3. **Add CSV files:** Named exactly like table names
4. **Start app:** `dotnet run`
5. **Navigate to:** http://localhost:5000/startup
6. **Click:** "Start Auto-Load"
7. **Wait:** System loads everything automatically
8. **Done!** All data loaded and ready

### **Subsequent Starts:**

**Option A: Load Workspace (Fast)**
1. Navigate to: http://localhost:5000/startup
2. Click: "Load Workspace"
3. Select saved workspace
4. Done! (No CSV re-import needed)

**Option B: Re-run Full Workflow**
1. Update CSV files if needed
2. Navigate to: http://localhost:5000/startup
3. Click: "Start Auto-Load"
4. Fresh import of all data

## ?? Example Scenario

### **Your Files:**
```
Loadables/
??? pipeline_schema.sql
??? tc_compressordata.csv   (258 rows)
??? tc_compressorplan.csv     (325 rows)
??? tc_dailymeterreadings.csv (102 rows)
??? tc_pipemeasurements.csv   (156 rows)
```

### **After Auto-Load:**

**Console Output:**
```
? Loaded DDL: 15 tables found
? Synced 15 table schemas to API
? Loaded tc_compressordata.csv: 258 rows ? tc_compressordata
? Loaded tc_compressorplan.csv: 325 rows ? tc_compressorplan
? Loaded tc_dailymeterreadings.csv: 102 rows ? tc_dailymeterreadings
? Loaded tc_pipemeasurements.csv: 156 rows ? tc_pipemeasurements
? Total: 841 rows loaded from 4 CSV files
? Generated SQL saved: generated_inserts_20241101_095030.sql
? Workspace saved: auto_workspace_20241101_095030.json
?? Startup workflow completed successfully!
```

**Generated Files:**
```
Loadables/output/
??? generated_inserts_20241101_095030.sql  (841 INSERT statements)
??? auto_workspace_20241101_095030.json    (Schemas for quick reload)
```

**What You Get:**
- ? All 15 tables available in Data Editor
- ? 841 rows accessible via REST API
- ? All data queryable in SQL Query Tool
- ? Swagger UI ready with all endpoints
- ? SQL script ready to run on real database

## ?? Advanced Options

### **DDL Cleanup (if needed):**

If your DDL has Redshift syntax or errors:

```powershell
# Run the cleanup script
.\Clean-DDL.ps1 -InputFile "Loadables\original_schema.sql" -OutputFile "Loadables\schema.sql"
```

### **Manual Mode:**

If you prefer manual control:
1. Navigate to: http://localhost:5000/offline-editor
2. Load DDL manually
3. Import CSVs one by one
4. Generate SQL as needed

## ? Troubleshooting

### **"No DDL file found"**
- Ensure you have at least one `.sql` file in `Loadables/` folder
- File must have `.sql` extension

### **"Table not found in DDL, skipping CSV"**
- CSV filename must match table name exactly
- Check table name in DDL: `CREATE TABLE dbo.YOUR_TABLE_NAME`
- Rename CSV to match: `YOUR_TABLE_NAME.csv`

### **"CSV must have header and at least one data row"**
- Ensure CSV has header row
- Ensure at least one data row exists

### **"Skipped XYZ.csv - table not in DDL"**
- Table doesn't exist in loaded DDL
- Either add table to DDL or remove CSV file

## ?? What Gets Loaded Where

| Component | DDL Schemas | CSV Data | SQL Script | Workspace |
|-----------|------------|----------|------------|-----------|
| **In-Memory Data Store** | ? | ? | ? | ? |
| **SQLite Query Engine** | ? | ? | ? | ? |
| **REST API Endpoints** | ? | ? | ? | ? |
| **Data Editor UI** | ? | ? | ? | ? |
| **Generated SQL File** | ? | ? | ? | ? |
| **Workspace JSON** | ? | ? | ? | ? |

## ?? Summary

**Automated workflow saves you from:**
- ? Manually loading DDL every time
- ? Importing CSV files one by one
- ? Clicking through multiple UI steps
- ? Regenerating SQL scripts manually
- ? Losing your progress when app restarts

**Instead, you get:**
- ? One-click startup
- ? Automatic data loading
- ? SQL scripts for database deployment
- ? Saved workspaces for quick reload
- ? Fully populated API ready to test

---

**Happy automating! ??**
