# ?? Database Tables Used Across NBPL & GTN Projects

## ?? Purpose
This document lists all database tables referenced in the SQL Query Manager, organized by source database. Use this to gather DDL scripts for migration or offline development.

---

## ?? Summary

| Database Connection | Schemas | Approx. Tables | Pipeline |
|---------------------|---------|----------------|----------|
| **TCExternalConnection** | `ap`, `ui`, `general`, `ce`, `pi` | 25+ | NBPL (Primary) |
| **DefaultConnection** | `dbo` | 15+ | Local PostgreSQL |
| **RedshiftConnection** | `external_ebb`, `navigates`, `marketprices`, `gas_storage` | 20+ | NBPL/GTN (Shared) |
| **GTNRedshiftConnection** | `int_sol`, `pi` | 10+ | GTN (Primary) |

---

## ??? TCExternalConnection (NBPL External DB)

### Schema: `ap` (Analytics Platform)
```
ap.linepack_by_segment
ap.contract
ap.contract_entity_daily_imbalance
ap.contract_cumulative_imbalance
ap.sap_outages
ap.cs_units
ap.station_pressure
ap.meter_readings
```

### Schema: `ui` (User Interface)
```
ui.linepack_netpack_thresholds
ui.ml_station_pressure_reccos
ui.operational_plan
```

### Schema: `general`
```
general.meter
general.compressor_station
```

### Schema: `ce` (Contract Entity)
```
ce.navigates_operational_available_capacity
```

### Schema: `pi` (Process Historian)
```
pi.meter_flow
```

**Export Command (PostgreSQL/Redshift):**
```sql
-- Generate DDL for all ap schema tables
SELECT 
    'CREATE TABLE ' || schemaname || '.' || tablename || ' (' ||
    string_agg(
        column_name || ' ' || data_type ||
        CASE WHEN is_nullable = 'NO' THEN ' NOT NULL' ELSE '' END,
        ', '
    ) || ');' AS ddl
FROM information_schema.columns
WHERE table_schema = 'ap'
GROUP BY schemaname, tablename;
```

---

## ??? DefaultConnection (Local PostgreSQL)

### Schema: `dbo`
```sql
dbo.tc_capacity_decisions
dbo.tc_capacity_configurations
dbo.pipeline_configurations
dbo.tc_recommendations
dbo.tchistoricaloutages
dbo.tc_compressorplan
dbo.tc_dailymeterreadings
dbo.tc_pipemeasurements
dbo.historicalpalrecommendations
dbo.uc3_historical_recommendations
dbo.uc3_spatial_restrictions
dbo.uc4_scenario_analyses
dbo.extracted_sql_queries
dbo.parquet_market_data  -- ICE market data
```

**These are already in your local DB!** Just export DDL:

```sql
-- PostgreSQL DDL export
pg_dump -h localhost -U postgres -d your_database \
    --schema=dbo \
    --schema-only \
    --no-owner \
    --no-privileges \
    > Loadables/ddls/local-dbo-schema.sql
```

Or use your existing `plato-subset-gtb-cleaned.sql` - it already has most of these!

---

## ??? RedshiftConnection (Shared NBPL/GTN)

### Schema: `external_ebb`
```
external_ebb.tariffs
```

### Schema: `navigates` (Contract/Scheduling System)
```
navigates.navigates_contract_transaction
navigates.navigates_contract_base
navigates.navigates_inputs_flat
navigates.navigates_transaction_balance_state
navigates.navigates_contract_prices
navigates.navigates_points
navigates.navigates_noms_by_day
navigates.navigates_noms_by_cycle
navigates.navigates_unsubscribedcapacity
```

### Schema: `marketprices`
```
marketprices.settlements
marketprices.platts_forward_curves
marketprices.exchange_rates
marketprices.exchange_rates_monthly_fwd_cme
marketprices.spread_same_day_location_to_location
```

### Schema: `gas_storage`
```
gas_storage.storage_capacity
```

**Export from Redshift:**
```sql
-- Show table DDL
SHOW TABLE external_ebb.tariffs;

-- Or query system tables
SELECT 
    schemaname,
    tablename,
    'CREATE TABLE ' || schemaname || '.' || tablename AS ddl_start
FROM pg_tables
WHERE schemaname IN ('external_ebb', 'navigates', 'marketprices', 'gas_storage');
```

---

## ??? GTNRedshiftConnection (GTN Pipeline)

### Schema: `int_sol` (Integration/Solution)
```
int_sol.apv2_operational_available_capacity
int_sol.apv2_gtn_unit_masterlist
int_sol.apv2_gtn_meter_masterlist
int_sol.apv2_gtn_station_masterlist
int_sol.apv2_gtn_segment_masterlist
int_sol.v_ap_linepack  -- View
int_sol.ap_netpack_threshold_input
int_sol.v_ap_outages_combined  -- View
int_sol.ap_outages_sap
int_sol.ap_compressor_flocs
int_sol.ap_sap_flocs
int_sol.ap_customer_daily_imbalances
int_sol.ap_ce_pal_daily_balance
int_sol.ap_linepack_netpack_historical
int_sol.ap_contracts
int_sol.ap_meter_profile
```

### Schema: `pi` (Process Historian)
```
pi.apv2_gtn_meter
pi.apv2_gtn_cs_unit  -- Compressor station units
pi.apv2_gtn_cs -- Compressor stations
```

**Export from GTN Redshift:**
```sql
-- List all int_sol tables
SELECT tablename 
FROM pg_tables 
WHERE schemaname = 'int_sol'
ORDER BY tablename;

-- Generate CREATE TABLE statements
-- (Redshift doesn't have built-in DDL export, use SHOW TABLE or pg_dump)
```

---

## ??? How to Gather DDL for Each Database

### **Option 1: PostgreSQL/Redshift - pg_dump**
```bash
# Local PostgreSQL
pg_dump -h localhost -U postgres -d nbpl_local \
    --schema=dbo \
    --schema-only \
 > Loadables/ddls/local-tables.sql

# AWS Redshift (requires psql client)
pg_dump -h your-cluster.redshift.amazonaws.com \
    -U your_user -d your_db \
  --schema=navigates --schema=marketprices \
    --schema-only \
    > Loadables/ddls/redshift-shared-tables.sql
```

### **Option 2: Query Information Schema**
```sql
-- Works on PostgreSQL & Redshift
SELECT 
  'CREATE TABLE ' || table_schema || '.' || table_name || ' (' || CHR(10) ||
    string_agg(
        '    ' || column_name || ' ' || 
        CASE 
   WHEN data_type = 'character varying' THEN 'VARCHAR(' || character_maximum_length || ')'
            WHEN data_type = 'numeric' THEN 'NUMERIC(' || numeric_precision || ',' || numeric_scale || ')'
   ELSE UPPER(data_type)
        END ||
      CASE WHEN is_nullable = 'NO' THEN ' NOT NULL' ELSE '' END,
        ',' || CHR(10)
    ) || CHR(10) || ');' AS ddl
FROM information_schema.columns
WHERE table_schema IN ('ap', 'ui', 'general', 'ce', 'pi')
GROUP BY table_schema, table_name
ORDER BY table_schema, table_name;
```

### **Option 3: Redshift SHOW TABLE**
```sql
-- Redshift-specific (shows full DDL with DIST/SORT keys)
SHOW TABLE ap.linepack_by_segment;
SHOW TABLE marketprices.settlements;
SHOW TABLE navigates.navigates_contract_transaction;
```

### **Option 4: Use Your Existing DDL!**
```powershell
# Your cleaned DDL already has many tables:
Get-Content Loadables\ddls\plato-subset-gtb-cleaned.sql | 
    Select-String "CREATE TABLE" | 
    ForEach-Object { $_ -replace '.*CREATE TABLE\s+', '' -replace '\s*\(.*', '' }
```

---

## ?? Recommended Approach

### **Step 1: Inventory What You Have**
```powershell
# Run the table extractor
.\Extract-Tables-Quick.ps1 -JsonPath "your-queries.json"

# Check your existing DDL
.\Check-CsvNames.ps1
```

### **Step 2: Export Missing Tables**

**For TCExternalConnection (NBPL Redshift/PostgreSQL):**
```sql
-- Export ap schema
pg_dump -h your-nbpl-db.aws.com -U user -d nbpl \
    --schema=ap --schema=ui --schema=ce \
    --schema-only \
    > Loadables/ddls/nbpl-external-tables.sql
```

**For RedshiftConnection (Shared):**
```sql
-- Export navigates, marketprices, external_ebb
pg_dump -h your-shared-redshift.aws.com -U user -d shared_db \
    --schema=navigates --schema=marketprices --schema=external_ebb \
    --schema-only \
    > Loadables/ddls/shared-redshift-tables.sql
```

**For GTNRedshiftConnection:**
```sql
-- Export int_sol and pi schemas
pg_dump -h your-gtn-redshift.aws.com -U user -d gtn_db \
    --schema=int_sol --schema=pi \
    --schema-only \
    > Loadables/ddls/gtn-tables.sql
```

### **Step 3: Clean & Consolidate**
```powershell
# Clean each DDL file
.\Clean-DDL.ps1 -InputFile "Loadables\ddls\nbpl-external-tables.sql" -OutputFile "Loadables\ddls\nbpl-external-tables-cleaned.sql"
.\Clean-DDL.ps1 -InputFile "Loadables\ddls\shared-redshift-tables.sql" -OutputFile "Loadables\ddls\shared-redshift-tables-cleaned.sql"
.\Clean-DDL.ps1 -InputFile "Loadables\ddls\gtn-tables.sql" -OutputFile "Loadables\ddls\gtn-tables-cleaned.sql"
```

### **Step 4: Load in Startup Wizard**
```
1. Update startup-config.json with new DDL files
2. Run: dotnet run
3. Navigate to: http://localhost:5000/startup
4. Click: "Start Auto-Load"
```

---

## ?? Quick Win: Use Existing Data

**You already have cleaned GTN DDL!**
```
? File: Loadables/ddls/plato-subset-gtb-cleaned.sql
? Tables: 28+ tables (dbo schema)
? Status: Ready to load!
```

Just need to add:
- External NBPL tables (ap, ui, ce schemas)
- Shared Redshift tables (navigates, marketprices)

---

## ?? Complete Table List (Excel/CSV Format)

Run this to get a CSV:
```powershell
.\Extract-Tables-Quick.ps1 -JsonPath "your-queries.json"
# Creates: tables-list.csv
```

Open in Excel for easy reference while gathering DDL!

---

## ?? Next Steps

1. **Run table extractor** to get full list
2. **Export DDL from each source database**
3. **Clean DDL files** with Clean-DDL.ps1
4. **Load in Startup Wizard**
5. **Import CSV data** (if available)
6. **Test queries** in SQL Query Tool

---

**Questions?**
- Which database do you have access to?
- Do you need help exporting from Redshift?
- Want a script to automate DDL generation?

Let me know and I can create targeted export scripts!
