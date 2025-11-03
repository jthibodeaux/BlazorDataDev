# ?? Flexible Folder Structure Update

## ? **What's Been Fixed:**

The startup automation now **automatically searches subfolders** for DDL and CSV files!

---

## ?? **Old Structure (Still Works):**

```
Loadables/
??? schema.sql
??? table1.csv
??? table2.csv
??? output/
```

---

## ?? **New Flexible Structure (Recommended):**

```
Loadables/
??? ddls/    ? Put DDL files here
?   ??? nbpl_schema.sql
??? csv/ ? Put CSV files here
???? tc_compressordata.csv
?   ??? tc_compressorplan.csv
?   ??? tc_dailymeterreadings.csv
?   ??? tc_pipemeasurements.csv
??? json/     ? JSON files (future support)
?   ??? data.json
??? output/     ? Generated files
    ??? generated_inserts_*.sql
    ??? auto_workspace_*.json
```

---

## ?? **Search Paths:**

### **DDL Files (.sql):**
System searches in this order:
1. `Loadables/` (root)
2. `Loadables/ddls/`
3. `Loadables/ddl/`

**First `.sql` file found will be used.**

### **CSV Files (.csv):**
System searches in ALL locations:
1. `Loadables/` (root)
2. `Loadables/csv/`
3. `Loadables/csvs/`

**ALL `.csv` files found will be loaded** (uses recursive search).

---

## ?? **Examples:**

### **Example 1: Simple Structure (Root)**
```
Loadables/
??? schema.sql
??? table1.csv
??? table2.csv
```
? **Works!** DDL and CSVs found in root.

### **Example 2: Organized Structure (Subfolders)**
```
Loadables/
??? ddls/
?   ??? my_schema.sql
??? csv/
    ??? users.csv
    ??? orders.csv
    ??? products.csv
```
? **Works!** DDL found in `ddls/`, CSVs found in `csv/`.

### **Example 3: Mixed Structure**
```
Loadables/
??? schema.sql        ? DDL in root
??? csv/
    ??? table1.csv    ? CSVs in subfolder
    ??? table2.csv
```
? **Works!** Searches all locations.

### **Example 4: Deep Nesting**
```
Loadables/
??? csv/
    ??? pipeline_a/
    ?   ??? compressors.csv
 ?   ??? meters.csv
    ??? pipeline_b/
        ??? readings.csv
```
? **Works!** Recursive search finds all CSVs.

---

## ?? **Usage:**

1. **Organize your files** however you prefer:
   - Put everything in root
   - Use `ddls/` and `csv/` subfolders
   - Create any subfolder structure

2. **Start the app:**
```powershell
dotnet run
```

3. **Navigate to:**
```
http://localhost:5000/startup
```

4. **Click "Start Auto-Load"**

5. **System finds all files automatically!**

---

## ?? **File Discovery Rules:**

### **DDL Files:**
- ? Any `.sql` file in search paths
- ? First match is used
- ? Recursive search in each path
- ?? Only ONE DDL file should exist

### **CSV Files:**
- ? Any `.csv` file in search paths
- ? **ALL matches are loaded**
- ? Recursive search finds nested files
- ? Filename MUST match table name

---

## ?? **Best Practices:**

### **Recommended Structure:**

```
Loadables/
??? ddls/              ? Database schemas
?   ??? nbpl_schema.sql
?   ??? backup_schema.sql.bak  (won't load - not .sql)
??? csv/      ? CSV data files
?   ??? pipeline1/
?   ?   ??? tc_compressordata.csv
? ?   ??? tc_compressorplan.csv
?   ??? pipeline2/
?       ??? tc_dailymeterreadings.csv
??? json/         ? JSON data (for future)
??? output/   ? Generated (don't edit)
    ??? generated_inserts_20241101_120000.sql
    ??? auto_workspace_20241101_120000.json
```

**Benefits:**
- ? Clean organization
- ? Easy to find files
- ? Separate data by source/pipeline
- ? Clear separation of input/output

---

## ?? **Troubleshooting:**

### **"No DDL file found"**
**Check:**
- Is there a `.sql` file in `Loadables/`, `Loadables/ddls/`, or `Loadables/ddl/`?
- File extension must be `.sql` (case-insensitive)

**Solution:**
```powershell
# Check what the system sees
Get-ChildItem -Path Loadables -Recurse -Filter *.sql
```

### **"Table not found, skipping CSV"**
**Check:**
- CSV filename must match table name exactly
- Example: `tc_compressordata.csv` ? `tc_compressordata` table

**Solution:**
```powershell
# List all CSV files
Get-ChildItem -Path Loadables\csv -Recurse -Filter *.csv
```

### **CSV in subfolder not loading**
**Verify:**
- CSV is in `Loadables/`, `Loadables/csv/`, or `Loadables/csvs/`
- Recursive search is enabled (it should be by default)

---

## ?? **Logging:**

Watch the console for discovery messages:

```
info: BlazorDbEditor.Services.StartupAutomationService[0]
      Found DDL file in: C:\...\Loadables\ddls
info: BlazorDbEditor.Services.StartupAutomationService[0]
      Found 3 CSV files in: C:\...\Loadables\csv
info: BlazorDbEditor.Services.StartupAutomationService[0]
      Total CSV files found: 3
info: BlazorDbEditor.Services.StartupAutomationService[0]
      Loading CSV: C:\...\Loadables\csv\table1.csv ? table1
```

---

## ? **Summary:**

**Before:**
- ? Files had to be in `Loadables/` root
- ? No subfolder organization
- ? Messy with many files

**After:**
- ? Files can be anywhere in `Loadables/`
- ? Supports `ddls/` and `csv/` subfolders
- ? Recursive search finds everything
- ? Clean, organized structure
- ? Backward compatible (root still works!)

---

**Your files will be found automatically, no matter where you put them!** ??

**Recommended setup:**
```
Loadables/
??? ddls/
? ??? your_schema.sql
??? csv/
    ??? your_csvs_here/
```
