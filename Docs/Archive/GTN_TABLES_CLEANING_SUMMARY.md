# ? GTN Tables - DDL Cleaning Summary

## ?? **Problem Identified:**

The GTN section of your DDL file had **Redshift-specific syntax** that wasn't parsing correctly in the Blazor DB Editor:

1. ? `CREATE TABLE IF NOT EXISTS` (Redshift syntax)
2. ? `ENCODE az64`, `ENCODE lzo`, `ENCODE RAW` clauses (Redshift compression)
3. ? Schema prefixes: `int_sol.` and `pi.` instead of `dbo.`
4. ? Duplicate table definitions (same table defined twice)

---

## ? **Solution Applied:**

Updated `Clean-DDL.ps1` with additional fixes:

```powershell
# Remove Redshift ENCODE clauses
$content = $content -replace '\s+ENCODE\s+\w+', ''

# Convert CREATE TABLE IF NOT EXISTS ? CREATE TABLE
$content = $content -replace 'CREATE\s+TABLE\s+IF\s+NOT\s+EXISTS\s+', 'CREATE TABLE '

# Fix schemas: int_sol.table ? dbo.table, pi.table ? dbo.table
$content = $content -replace 'CREATE\s+TABLE\s+int_sol\.', 'CREATE TABLE dbo.'
$content = $content -replace 'CREATE\s+TABLE\s+pi\.', 'CREATE TABLE dbo.'

# Add dbo. prefix where missing
$content = $content -replace 'CREATE\s+TABLE\s+(?!dbo\.)(\w+)', 'CREATE TABLE dbo.$1'

# Clean up double prefixes (dbo.pi.table ? dbo.table)
$content = $content -replace 'dbo\.pi\.', 'dbo.'
$content = $content -replace 'dbo\.int_sol\.', 'dbo.'
```

---

## ?? **Result:**

### **Before (Original):**
```sql
CREATE TABLE IF NOT EXISTS int_sol.apv2_operational_available_capacity
(
	assetnbr INTEGER   ENCODE az64
	,assetabrv VARCHAR(50)   ENCODE lzo
	,flowdate DATE   ENCODE az64
	...
)

CREATE TABLE IF NOT EXISTS pi.apv2_gtn_meter
(
	"timestamp" TIMESTAMP WITHOUT TIME ZONE   ENCODE RAW
	,ap_meter INTEGER   ENCODE RAW
	...
)
```

### **After (Cleaned):**
```sql
CREATE TABLE dbo.apv2_operational_available_capacity
(
	assetnbr INTEGER
	,assetabrv VARCHAR(50)
	,flowdate DATE
	...
)

CREATE TABLE dbo.apv2_gtn_meter
(
	"timestamp" TIMESTAMP WITHOUT TIME ZONE
	,ap_meter INTEGER
	...
)
```

---

## ?? **GTN Tables Now Properly Formatted:**

1. ? `dbo.apv2_operational_available_capacity`
2. ? `dbo.apv2_gtn_unit_masterlist`
3. ? `dbo.apv2_gtn_meter` (was `pi.apv2_gtn_meter`)
4. ? `dbo.apv2_gtn_cs_unit` (was `pi.apv2_gtn_cs_unit`)
5. ? `dbo.apv2_gtn_station_masterlist`
6. ? `dbo.apv2_gtn_segment_masterlist`

**All now have:**
- ? Standard PostgreSQL `CREATE TABLE` syntax
- ? Proper `dbo.` schema prefix
- ? No Redshift ENCODE clauses
- ? Compatible with Blazor DB Editor parser

---

## ?? **Remaining Issues:**

### **Duplicate Table Definitions:**
The following tables are defined twice in the DDL:
- `dbo.tc_pipemeasurements` (2 times)
- `dbo.apv2_operational_available_capacity` (2 times)
- `dbo.apv2_gtn_unit_masterlist` (2 times)
- `dbo.apv2_gtn_meter` (2 times)
- `dbo.apv2_gtn_cs_unit` (2 times)
- `dbo.apv2_gtn_station_masterlist` (2 times)
- `dbo.apv2_gtn_segment_masterlist` (2 times)

**Recommendation:**
- Use the **first occurrence** of each table
- Manually remove duplicate sections
- Or use a deduplication script

---

## ?? **Next Steps:**

### **1. Replace Original DDL:**
```powershell
# Backup original
Copy-Item "Loadables\ddls\plato-subset-gtb.ddl.sql" "Loadables\ddls\plato-subset-gtb.ddl.sql.bak"

# Use cleaned version
Copy-Item "Loadables\ddls\plato-subset-gtb-cleaned.sql" "Loadables\ddls\plato-subset-gtb.ddl.sql"
```

### **2. Reload in Startup Wizard:**
```
1. Restart app: dotnet run
2. Navigate to: http://localhost:5000/startup
3. Click: "Start Auto-Load"
4. Verify: All 38 tables load (including GTN tables)
```

### **3. Verify GTN Tables:**
Check that the following tables appear in the sidebar:
- ? `apv2_operational_available_capacity`
- ? `apv2_gtn_unit_masterlist`
- ? `apv2_gtn_meter`
- ? `apv2_gtn_cs_unit`
- ? `apv2_gtn_station_masterlist`
- ? `apv2_gtn_segment_masterlist`

---

## ?? **Files:**

- **Original:** `Loadables/ddls/plato-subset-gtb.ddl.sql`
- **Cleaned:** `Loadables/ddls/plato-subset-gtb-cleaned.sql` ? **Use this one!**
- **Script:** `Clean-DDL.ps1` (updated with Redshift fixes)

---

## ?? **Clean-DDL.ps1 Usage:**

```powershell
# Clean your DDL file
.\Clean-DDL.ps1 -InputFile "Loadables\ddls\your-file.ddl.sql" -OutputFile "Loadables\ddls\your-file-cleaned.sql"

# Handles:
? Redshift ENCODE clauses
? CREATE TABLE IF NOT EXISTS
? Schema prefixes (int_sol, pi ? dbo)
? Trailing commas
? Whitespace normalization
? Table triggers
```

---

## ? **Summary:**

**Before:**
- ? 12+ tables showing as `IF` in sidebar
- ? Redshift-specific syntax
- ? Multiple schema prefixes

**After:**
- ? All tables properly named
- ? Standard PostgreSQL syntax
- ? Unified `dbo.` schema
- ? Ready to load in Blazor DB Editor!

---

**Your GTN tables will now load correctly!** ??

Just use the cleaned DDL file and reload in the Startup Wizard.
