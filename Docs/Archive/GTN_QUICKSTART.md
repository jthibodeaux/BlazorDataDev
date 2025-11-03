# ?? Quick Start: Load Cleaned GTN DDL

## ? **Your DDL is now cleaned and ready!**

### **File Location:**
```
Loadables/ddls/plato-subset-gtb-cleaned.sql
```

---

## ?? **Steps to Load:**

### **Option 1: Use Cleaned File (Recommended)**

```powershell
# 1. Backup original (just in case)
Copy-Item "Loadables\ddls\plato-subset-gtb.ddl.sql" "Loadables\ddls\plato-subset-gtb.ddl.sql.bak"

# 2. Replace with cleaned version
Copy-Item "Loadables\ddls\plato-subset-gtb-cleaned.sql" "Loadables\ddls\plato-subset-gtb.ddl.sql" -Force

# 3. Start app
dotnet run

# 4. Navigate to Startup Wizard
# http://localhost:5000/startup

# 5. Click "Start Auto-Load"
```

### **Option 2: Use Cleaned File Directly**

```powershell
# Just point startup automation to the cleaned file
# Edit: startup-config.json

{
  "StartupAutomation": {
    "LoadablesFolder": "Loadables",
    "DdlFileName": "plato-subset-gtb-cleaned.sql",  // Use cleaned file
    ...
  }
}
```

---

## ?? **What You'll See:**

### **Before (With Original DDL):**
```
DDL Tables (sidebar):
  extracted_sql_queries
  pipeline_configurations
  tc_capacity_configurations
  ...
  IF    ? ? These were broken GTN tables
  IF
  IF
  IF
  (32 tables total, 12+ broken)
```

### **After (With Cleaned DDL):**
```
DDL Tables (sidebar):
  apv2_gtn_cs_unit      ? ? Now working!
  apv2_gtn_meter   ? ? Now working!
  apv2_gtn_segment_masterlist    ? ? Now working!
  apv2_gtn_station_masterlist    ? ? Now working!
  apv2_gtn_unit_masterlist? ? Now working!
  apv2_operational_available_capacity ? ? Now working!
  extracted_sql_queries
  pipeline_configurations
  tc_capacity_configurations
  ...
  (38+ tables total, all working!)
```

---

## ? **Verification:**

After loading, check:

1. **NavMenu Sidebar:**
   - Should show ~38 tables
   - All should have proper names (no `IF`)
   - GTN tables should be alphabetically sorted with others

2. **Offline Editor:**
   - Select any GTN table from dropdown
   - Schema should display correctly
   - All columns visible

3. **Data Editor:**
   - GTN tables appear in table dropdown
   - Can add/edit rows (after importing data)

4. **SQL Query Tool:**
   - Can query GTN tables:
     ```sql
     SELECT * FROM apv2_gtn_meter LIMIT 10;
     ```

5. **REST API:**
   - GTN tables available at:
     ```
     GET /api/tables/apv2_gtn_meter
     GET /api/tables/apv2_gtn_cs_unit
     etc.
     ```

---

## ?? **What Was Fixed:**

| Issue | Before | After |
|-------|--------|-------|
| **Syntax** | `CREATE TABLE IF NOT EXISTS` | `CREATE TABLE` |
| **Schema** | `int_sol.table`, `pi.table` | `dbo.table` |
| **Encoding** | `ENCODE az64`, `ENCODE lzo` | (removed) |
| **Parsing** | Shows as `IF` in sidebar | Shows as proper table name |
| **API** | Not accessible | Full CRUD available |
| **Queries** | Can't query | Can SELECT/JOIN |

---

## ?? **GTN Tables List:**

After loading cleaned DDL, you should see:

1. ? `apv2_operational_available_capacity`
2. ? `apv2_gtn_unit_masterlist`
3. ? `apv2_gtn_meter`
4. ? `apv2_gtn_cs_unit`
5. ? `apv2_gtn_station_masterlist`
6. ? `apv2_gtn_segment_masterlist`

Plus all your existing `tc_*` tables (~32 tables).

---

## ?? **Troubleshooting:**

### **Still See `IF` in Sidebar:**
- Make sure you're using the **cleaned** DDL file
- Restart the app
- Clear browser cache (Ctrl+Shift+R)

### **Tables Not Loading:**
- Check console for errors: `dotnet run`
- Verify file path: `Loadables/ddls/plato-subset-gtb-cleaned.sql`
- Check startup-config.json points to correct file

### **Want to Re-Clean:**
```powershell
# Run Clean-DDL.ps1 again
.\Clean-DDL.ps1 -InputFile "Loadables\ddls\plato-subset-gtb.ddl.sql" -OutputFile "Loadables\ddls\plato-subset-gtb-cleaned.sql"
```

---

## ?? **You're All Set!**

Your GTN tables are now:
- ? Properly formatted
- ? Ready to load
- ? Accessible via API
- ? Queryable via SQL

Just load the cleaned DDL and everything should work perfectly! ??

---

**Files:**
- **Use:** `Loadables/ddls/plato-subset-gtb-cleaned.sql` ?
- **Backup:** `Loadables/ddls/plato-subset-gtb.ddl.sql.bak`
- **Docs:** `Docs/GTN_TABLES_CLEANING_SUMMARY.md`
