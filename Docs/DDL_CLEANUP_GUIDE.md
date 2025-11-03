# DDL File Issues and Fixes

## ?? **Problems Found in Your DDL:**

### **1. Redshift-Specific Encoding (Not PostgreSQL Compatible)**
```sql
? ENCODE az64
? ENCODE lzo
? ENCODE RAW
```
**Fix:** Remove all `ENCODE` clauses

### **2. Duplicate Table Definition**
- `tc_pipemeasurements` is defined **twice** (around lines 480 and 495)
**Fix:** Keep only one definition

### **3. Missing Closing Parenthesis**
- `pipeline_configurations` table (line ~100) has trailing comma
```sql
? config_hash varchar(64) NULL,
);  // Extra comma before closing paren
```

### **4. Commented Out Primary Key**
- `tc_capacity_configurations` has commented PK:
```sql
--CONSTRAINT tc_capacity_configurations_pkey PRIMARY KEY (id)
```
**Fix:** Uncomment or remove

### **5. Table Triggers Reference Missing Function**
```sql
create trigger trigger_update_tc_pipeline_capacity_config_updated_at before
update on dbo.tc_pipeline_capacity_config 
for each row execute function update_updated_at_column();
```
**Fix:** Either create the function or remove the trigger

---

## ? **Quick Fixes:**

### **Clean DDL Script:**

Save this cleaned version and try loading it:

```sql
-- CLEANED DDL - PostgreSQL Compatible
-- Removed Redshift ENCODE clauses
-- Fixed duplicate tables
-- Fixed syntax errors

-- dbo.extracted_sql_queries definition
CREATE TABLE dbo.extracted_sql_queries (
	id text NOT NULL,
	parameters text NULL,
	updated_by varchar(200) NOT NULL,
	updated_at timestamp NOT NULL,
	log_description text NOT NULL,
	sql_text text NOT NULL,
	dbname text NOT NULL,
	CONSTRAINT extracted_sql_queries_pkey PRIMARY KEY (id)
);

-- dbo.pipeline_configurations definition
CREATE TABLE dbo.pipeline_configurations (
	id uuid DEFAULT gen_random_uuid() NOT NULL,
	row_version int8 DEFAULT 1 NULL,
	created_date timestamptz NULL,
	modified_date timestamptz NULL,
	is_active bool DEFAULT true NOT NULL,
	is_deleted bool DEFAULT false NOT NULL,
	created_by text NULL,
	modified_by text NULL,
	tenant_id uuid NULL,
	configuration_json text NOT NULL,
	change_reason varchar(500) NULL,
	version_number int4 DEFAULT 1 NOT NULL,
	config_hash varchar(64) NULL
);

-- Continue with other tables...
-- Remove ENCODE clauses from GTN tables
-- Remove duplicate tc_pipemeasurements
```

---

## ??? **Automated Cleanup Script:**

I can create a PowerShell script to clean your DDL file automatically:

```powershell
# Clean-DDL.ps1
$inputFile = "your-ddl-file.sql"
$outputFile = "cleaned-ddl.sql"

$content = Get-Content $inputFile -Raw

# Remove ENCODE clauses
$content = $content -replace '\s+ENCODE\s+(az64|lzo|RAW)', ''

# Remove duplicate whitespace
$content = $content -replace '\s+\n', "`n"

# Save cleaned file
$content | Out-File $outputFile -Encoding UTF8

Write-Host "? Cleaned DDL saved to: $outputFile"
```

---

## ?? **Recommended Approach:**

### **Option 1: Use Simplified DDL** (Fastest)
Create a minimal DDL with just the tables you need:

```sql
CREATE TABLE dbo.tc_compressordata (
	ap_compressor varchar(50) NOT NULL,
	timestamp timestamp NOT NULL,
	ap_compressorunit_gtn varchar(50) NOT NULL,
	bhp float8 NULL,
	enginestatus varchar(50) NULL,
	pipeline_id varchar(20) NULL
);

CREATE TABLE dbo.tc_dailymeterreadings (
	timestamp timestamp NOT NULL,
	ap_meter int4 NOT NULL,
	btu float8 NULL,
	flow_rate_mmcfd float8 NULL,
	pressure float8 NULL
);

-- Add other tables as needed
```

### **Option 2: Clean Your Full DDL**
1. Remove all `ENCODE` clauses
2. Remove duplicate `tc_pipemeasurements` definition
3. Fix the trailing comma in `pipeline_configurations`
4. Uncomment or remove commented primary keys
5. Remove trigger definitions (or create the trigger functions first)

### **Option 3: Export Fresh DDL from PostgreSQL**
```sql
pg_dump -h localhost -U postgres -d your_database --schema=dbo --schema-only > clean-ddl.sql
```

---

## ?? **What to Do Next:**

1. **Create a cleaned DDL file** using one of the options above
2. **Test it** by loading in Offline Editor
3. **Import your CSV data** once schema loads successfully

Would you like me to:
- Create a cleaned version of your full DDL?
- Generate a PowerShell script to auto-clean it?
- Help you create a minimal DDL with just the tables you're using?
