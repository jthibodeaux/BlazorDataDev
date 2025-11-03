# ?? AWS Data Loading Guide for NBPL Tables

## ?? Scaling Up for Production Data

This guide helps you load large datasets from AWS into your Blazor DB Editor for testing.

---

## ?? Current System Capabilities

Your system is already optimized for:
- ? **Bulk CSV loading** - Automated import of multiple files
- ? **Large datasets** - Handles thousands of rows efficiently
- ? **In-memory storage** - Fast access via singleton data store
- ? **SQLite queries** - Complex SQL with JOINs
- ? **REST API** - All data accessible via endpoints

---

## ?? Preparing AWS Data

### **Step 1: Export Data from AWS**

#### **Option A: RDS/PostgreSQL Export**
```sql
-- Export each table to CSV
\COPY dbo.tc_compressordata TO '/tmp/tc_compressordata.csv' CSV HEADER;
\COPY dbo.tc_compressorplan TO '/tmp/tc_compressorplan.csv' CSV HEADER;
\COPY dbo.tc_dailymeterreadings TO '/tmp/tc_dailymeterreadings.csv' CSV HEADER;
-- ... more tables
```

#### **Option B: Redshift UNLOAD**
```sql
UNLOAD ('SELECT * FROM dbo.tc_compressordata')
TO 's3://your-bucket/exports/tc_compressordata_'
IAM_ROLE 'arn:aws:iam::123456789:role/YourRole'
CSV HEADER
PARALLEL OFF;
```

#### **Option C: AWS CLI (S3)**
```bash
# Download from S3
aws s3 cp s3://your-bucket/data/tc_compressordata.csv ./Loadables/
aws s3 sync s3://your-bucket/data/ ./Loadables/ --exclude "*" --include "*.csv"
```

### **Step 2: Download DDL Schema**

```sql
-- Export DDL from PostgreSQL
pg_dump -h your-rds-endpoint.amazonaws.com \
        -U username \
    -d database_name \
        --schema=dbo \
   --schema-only \
        --no-owner \
        --no-privileges \
        > Loadables/nbpl_schema.sql
```

---

## ?? Recommended AWS Setup

### **For Testing Large Datasets:**

```
AWS RDS/Redshift
      ?
   Export to S3
    ?
   Download to Local
      ?
Loadables/
??? nbpl_schema.sql          ? Full schema from AWS
??? tc_compressordata.csv    ? Table data
??? tc_compressorplan.csv
??? tc_dailymeterreadings.csv
??? tc_pipemeasurements.csv
??? tc_pipeline_definitions.csv
??? tc_pipeline_stations.csv
??? tc_pipeline_segments.csv
??? tc_capacity_decisions.csv
??? ... more tables
```

---

## ? Performance Optimization

### **Current Limits:**
- **Max rows per table:** ~1 million (in-memory)
- **Max tables:** Unlimited
- **Query timeout:** 30 seconds
- **Result limit:** 10,000 rows per query

### **For Large Datasets (100K+ rows):**

#### **1. Sample Data for Testing**
```sql
-- Export only recent data
\COPY (SELECT * FROM dbo.tc_compressordata 
       WHERE timestamp >= CURRENT_DATE - INTERVAL '30 days'
       ORDER BY timestamp DESC
       LIMIT 10000) 
TO '/tmp/tc_compressordata_sample.csv' CSV HEADER;
```

#### **2. Partition Large Tables**
```bash
# Split large CSV into smaller chunks
split -l 50000 tc_compressordata.csv tc_compressordata_part_

# Or use PowerShell
$csv = Import-Csv tc_compressordata.csv
$size = 50000
for ($i = 0; $i -lt $csv.Count; $i += $size) {
    $csv[$i..($i+$size-1)] | Export-Csv "tc_compressordata_part$($i/$size).csv" -NoTypeInformation
}
```

#### **3. Increase Memory Limits (if needed)**

Edit `Services/InMemoryDataStore.cs`:
```csharp
// No hard limits, but monitor memory usage
// For very large datasets, consider pagination
```

Edit `Services/SqliteQueryService.cs`:
```csharp
private const int MaxResultRows = 50000; // Increase if needed
private const int QueryTimeoutSeconds = 60; // Increase for complex queries
```

---

## ?? Automated AWS ? Loadables Pipeline

### **PowerShell Script for AWS Sync:**

```powershell
# aws-sync.ps1
param(
    [string]$S3Bucket = "your-bucket-name",
    [string]$S3Prefix = "nbpl-exports/",
    [string]$LocalPath = "./Loadables"
)

Write-Host "?? Syncing NBPL data from AWS S3..." -ForegroundColor Cyan

# Ensure Loadables folder exists
if (-not (Test-Path $LocalPath)) {
    New-Item -ItemType Directory -Path $LocalPath | Out-Null
}

# Download schema
Write-Host "?? Downloading schema..." -ForegroundColor Yellow
aws s3 cp "s3://$S3Bucket/$S3Prefix/schema.sql" "$LocalPath/nbpl_schema.sql"

# Download all CSV files
Write-Host "?? Downloading CSV files..." -ForegroundColor Yellow
aws s3 sync "s3://$S3Bucket/$S3Prefix" $LocalPath --exclude "*" --include "*.csv"

# Count files
$csvCount = (Get-ChildItem "$LocalPath\*.csv").Count
Write-Host "? Downloaded $csvCount CSV files" -ForegroundColor Green

Write-Host ""
Write-Host "?? Files ready in: $LocalPath" -ForegroundColor Cyan
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. dotnet run" -ForegroundColor White
Write-Host "  2. Navigate to http://localhost:5000/startup" -ForegroundColor White
Write-Host "  3. Click 'Start Auto-Load'" -ForegroundColor White
```

**Usage:**
```powershell
.\aws-sync.ps1 -S3Bucket "my-nbpl-bucket" -S3Prefix "data/exports/"
```

---

## ?? Scaling Scenarios

### **Scenario 1: Development Testing (Small Dataset)**
```
Tables: 10-15
Rows per table: 1K-10K
Total rows: ~50K
Load time: ~5-10 seconds
Memory: ~50-100 MB
```

### **Scenario 2: Staging Testing (Medium Dataset)**
```
Tables: 20-30
Rows per table: 10K-50K
Total rows: ~500K
Load time: ~30-60 seconds
Memory: ~500 MB - 1 GB
```

### **Scenario 3: Production Simulation (Large Dataset)**
```
Tables: 30+
Rows per table: 50K-100K
Total rows: ~2M
Load time: ~2-5 minutes
Memory: ~2-4 GB
```

**Recommendation:** Use sampled data for development, full data for final testing.

---

## ?? Workflow for AWS Data

### **One-Time Setup:**

1. **Export schema from AWS:**
```bash
pg_dump -h your-rds.amazonaws.com -U user -d nbpl --schema-only > Loadables/nbpl_schema.sql
```

2. **Export data (monthly/weekly):**
```bash
./aws-sync.ps1  # Download latest exports
```

3. **Clean DDL if needed:**
```powershell
.\Clean-DDL.ps1 -InputFile "Loadables\nbpl_schema.sql" -OutputFile "Loadables\schema.sql"
```

### **Daily Development:**

1. **Start app:**
```powershell
dotnet run
```

2. **Use saved workspace (fast):**
   - Navigate to /startup
   - Click "Load Workspace"
   - Done in 2 seconds!

3. **Or reload fresh data:**
   - Navigate to /startup
   - Click "Start Auto-Load"
   - Done in ~10-60 seconds depending on size

---

## ?? Memory Management

### **Monitor Memory Usage:**

```csharp
// Add to StartupAutomationService.cs
private void LogMemoryUsage()
{
    var memoryMB = GC.GetTotalMemory(false) / 1024 / 1024;
    _logger.LogInformation("Memory usage: {MemoryMB} MB", memoryMB);
}
```

### **If Running Out of Memory:**

**Option 1: Increase App Memory**
```json
// launchSettings.json
{
  "profiles": {
    "BlazorDbEditor": {
      "environmentVariables": {
        "DOTNET_GCHeapCount": "0x4",
        "DOTNET_GCHeapAffinitizeMask": "0xf"
      }
    }
  }
}
```

**Option 2: Use Data Sampling**
- Only load recent data (last 30/60/90 days)
- Use WHERE clauses in exports
- Partition large tables

**Option 3: Paginated Loading**
- Load tables on-demand
- Don't load all at startup
- Fetch data via API as needed

---

## ?? AWS Redshift Considerations

If your data is in Redshift, watch out for:

### **1. ENCODE Clauses (Not Standard SQL)**
```sql
-- ? Redshift-specific
CREATE TABLE foo (
    id INTEGER ENCODE az64
);

-- ? Standard PostgreSQL
CREATE TABLE foo (
    id INTEGER
);
```

**Solution:** Use `Clean-DDL.ps1` script to remove ENCODE clauses.

### **2. DISTSTYLE/DISTKEY/SORTKEY**
```sql
-- ? Redshift distribution
CREATE TABLE foo (id INT)
DISTSTYLE KEY
DISTKEY (id)
SORTKEY (timestamp);

-- ? Remove for local testing
CREATE TABLE foo (id INT);
```

### **3. Data Types**
- `SUPER` ? Convert to JSON/TEXT
- `GEOGRAPHY` ? Convert to TEXT
- `GEOMETRY` ? Convert to TEXT

---

## ?? Testing AWS Data Locally

### **Validate Data Quality:**

```sql
-- After loading, run these checks in SQL Query Tool

-- 1. Check row counts
SELECT 'tc_compressordata' as table_name, COUNT(*) as row_count 
FROM tc_compressordata
UNION ALL
SELECT 'tc_compressorplan', COUNT(*) FROM tc_compressorplan
UNION ALL
SELECT 'tc_dailymeterreadings', COUNT(*) FROM tc_dailymeterreadings;

-- 2. Check date ranges
SELECT 
    MIN(timestamp) as oldest_date,
    MAX(timestamp) as newest_date,
    COUNT(*) as total_rows
FROM tc_compressordata;

-- 3. Check for nulls
SELECT 
    COUNT(*) as total_rows,
    COUNT(ap_compressor) as non_null_compressor,
    COUNT(bhp) as non_null_bhp
FROM tc_compressordata;

-- 4. Test JOINs
SELECT 
    cd.ap_compressor,
    cd.timestamp,
    cp.totalhorsepower
FROM tc_compressordata cd
LEFT JOIN tc_compressorplan cp 
    ON cd.ap_compressor = cp.ap_compressor 
    AND cd.timestamp = cp.timestamp
LIMIT 100;
```

---

## ?? Summary

### **Current Setup (Works Great!):**
- ? Auto-loads DDL and CSV files
- ? Handles thousands of rows easily
- ? Saves workspace for quick reload
- ? Generates SQL for deployment

### **For AWS Data:**
1. **Export** schema and data from AWS
2. **Download** to `Loadables/` folder
3. **Clean** DDL if from Redshift
4. **Run** startup automation
5. **Test** with real data locally!

### **Scale Up Gradually:**
- Start with 1-2 tables
- Verify it works
- Add more tables
- Monitor memory usage
- Sample data if needed

---

**Ready for AWS data!** ??

Your startup automation system is designed to handle this workflow perfectly. Just sync your AWS data to the `Loadables` folder and click "Start Auto-Load"!
