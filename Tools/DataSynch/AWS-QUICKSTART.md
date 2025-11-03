# ?? AWS to Blazor DB Editor - Quick Reference

## ? Your Complete Workflow

```
AWS (RDS/Redshift/S3)
      ?
Export to S3 (DDL + CSVs)
          ?
   Download to Loadables/
        ?
   Start Blazor DB Editor
 ?
   Auto-Load Everything
          ?
   Test with Real Data!
```

---

## ?? Quick Commands

### **1. Sync Data from AWS**
```powershell
# Dry run first (see what would download)
.\aws-sync.ps1 -S3Bucket "your-bucket" -S3Prefix "nbpl-exports/" -DryRun

# Actually download
.\aws-sync.ps1 -S3Bucket "your-bucket" -S3Prefix "nbpl-exports/"

# Schema only
.\aws-sync.ps1 -S3Bucket "your-bucket" -SchemaOnly

# Data only (if schema already exists)
.\aws-sync.ps1 -S3Bucket "your-bucket" -DataOnly
```

### **2. Clean DDL (If from Redshift)**
```powershell
.\Clean-DDL.ps1 -InputFile "Loadables\nbpl_schema.sql" -OutputFile "Loadables\schema.sql"
```

### **3. Start Application**
```powershell
dotnet run
```

### **4. Navigate & Load**
```
http://localhost:5000/startup
Click: "Start Auto-Load"
```

---

## ?? File Structure

```
BlazorDbEditor/
??? Loadables/
?   ??? schema.sql           ? From AWS (cleaned if needed)
?   ??? tc_compressordata.csv
?   ??? tc_compressorplan.csv
?   ??? tc_dailymeterreadings.csv
?   ??? tc_pipemeasurements.csv
?   ??? ... (all your NBPL tables)
?   ??? output/    ? Auto-generated
?  ??? generated_inserts_*.sql
?       ??? auto_workspace_*.json
??? aws-sync.ps1   ? Download from S3
```

---

## ? Typical AWS Workflow

### **Monday: Fresh Data**
```powershell
# 1. Sync latest data from AWS
.\aws-sync.ps1 -S3Bucket "nbpl-data" -S3Prefix "latest/"

# 2. Check files
ls Loadables\*.csv | measure

# 3. Start app
dotnet run

# 4. Auto-load
# Navigate to /startup ? Click "Start Auto-Load"

# 5. Test!
# Data Editor, SQL Query, Swagger API all ready
```

### **Tuesday-Friday: Quick Restart**
```powershell
# 1. Start app
dotnet run

# 2. Load workspace (2 seconds!)
# Navigate to /startup ? Click "Load Workspace"

# 3. Done!
```

---

## ?? Data Size Guidelines

| Scenario | Tables | Rows | Load Time | Memory |
|----------|--------|------|-----------|--------|
| **Development** | 5-10 | 10K | ~5s | 50 MB |
| **Testing** | 10-20 | 100K | ~30s | 500 MB |
| **Full Dataset** | 20-30 | 500K | ~2min | 2 GB |

**Tip:** Start small, scale up gradually!

---

## ?? AWS Export Examples

### **From RDS PostgreSQL:**
```bash
# Export schema
pg_dump -h your-rds.amazonaws.com \
    -U username \
   -d nbpl_database \
        --schema=dbo \
        --schema-only \
        > schema.sql

# Export data tables
psql -h your-rds.amazonaws.com -U username -d nbpl_database \
     -c "\COPY dbo.tc_compressordata TO 'tc_compressordata.csv' CSV HEADER"
```

### **From Redshift:**
```sql
-- Export to S3
UNLOAD ('SELECT * FROM dbo.tc_compressordata')
TO 's3://your-bucket/exports/tc_compressordata_'
IAM_ROLE 'arn:aws:iam::123:role/RedshiftRole'
CSV HEADER
PARALLEL OFF;
```

### **Using AWS CLI:**
```bash
# Upload to S3
aws s3 cp schema.sql s3://your-bucket/nbpl-exports/
aws s3 sync ./csv-exports/ s3://your-bucket/nbpl-exports/ --exclude "*" --include "*.csv"
```

---

## ?? Complete Example

```powershell
# ==================================================
# Complete workflow from AWS to working application
# ==================================================

# Step 1: Download from AWS S3
Write-Host "Downloading from AWS..." -ForegroundColor Cyan
.\aws-sync.ps1 -S3Bucket "nbpl-production" -S3Prefix "exports/2024-11/"

# Step 2: Clean DDL (if from Redshift)
Write-Host "Cleaning DDL..." -ForegroundColor Cyan
.\Clean-DDL.ps1 -InputFile "Loadables\nbpl_schema.sql" -OutputFile "Loadables\schema.sql"

# Step 3: Verify files
Write-Host "Files downloaded:" -ForegroundColor Cyan
$csvCount = (Get-ChildItem Loadables\*.csv).Count
$totalRows = 0
Get-ChildItem Loadables\*.csv | ForEach-Object {
    $lines = (Get-Content $_.FullName | Measure-Object -Line).Lines - 1
    $totalRows += $lines
    Write-Host "  $($_.Name): $lines rows"
}
Write-Host "Total: $csvCount files, $totalRows rows" -ForegroundColor Green

# Step 4: Start application
Write-Host ""
Write-Host "Starting application..." -ForegroundColor Cyan
Start-Process "dotnet" -ArgumentList "run" -NoNewWindow

# Wait for startup
Start-Sleep -Seconds 3

# Step 5: Open browser
Write-Host "Opening startup wizard..." -ForegroundColor Cyan
Start-Process "http://localhost:5000/startup"

Write-Host ""
Write-Host "? Ready! Click 'Start Auto-Load' in the browser" -ForegroundColor Green
```

---

## ?? Troubleshooting

### **"No files downloaded"**
```powershell
# Check S3 bucket access
aws s3 ls s3://your-bucket/your-prefix/

# Verify AWS credentials
aws sts get-caller-identity
```

### **"Table not found in DDL"**
- CSV filename must match table name exactly
- Check DDL for table names
- Redshift: lowercase after cleaning

### **"Out of memory"**
- Sample data: Export last 30 days only
- Increase app memory limits
- Split large CSV files

### **"DDL parse errors"**
- Run Clean-DDL.ps1 for Redshift exports
- Check for ENCODE clauses
- Remove proprietary syntax

---

## ?? Performance Tips

### **Fast Loading:**
1. ? Use workspace for daily restarts
2. ? Only reload when data changes
3. ? Sample data for development

### **Memory Optimization:**
1. ? Don't load all tables at once
2. ? Use date filters in exports
3. ? Partition large tables

### **Query Performance:**
1. ? Limit result rows (already at 10K)
2. ? Use WHERE clauses
3. ? Index on primary keys (auto-detected)

---

## ?? Summary

**Your system is AWS-ready!**

### **What You Have:**
- ? AWS sync script (`aws-sync.ps1`)
- ? DDL cleaner (`Clean-DDL.ps1`)
- ? Auto-load system (startup wizard)
- ? REST API for all data
- ? SQL query tool with JOINs
- ? Workspace for quick reload

### **What You Do:**
1. **Export** data from AWS ? S3
2. **Download** with `aws-sync.ps1`
3. **Clean** DDL if needed
4. **Run** `dotnet run`
5. **Click** "Start Auto-Load"
6. **Test** with real production data!

### **Time Required:**
- First time: ~5-10 minutes (depending on data size)
- Subsequent: ~2 seconds (load workspace)

---

**Ready to scale up with AWS data!** ??

Your startup automation handles everything - just sync your data and click one button!
