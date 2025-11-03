# AWS GTN Data Sync Script
# Downloads GTN-specific CSV files from S3/Redshift to match your DDL schema

param(
    [Parameter(Mandatory=$false)]
    [string]$S3Bucket = "your-bucket-name",
    
    [Parameter(Mandatory=$false)]
    [string]$S3Prefix = "gtn-exports/",
    
    [Parameter(Mandatory=$false)]
    [string]$LocalCsvPath = "./Loadables/csv",
    
    [Parameter(Mandatory=$false)]
    [switch]$DryRun,
    
    [Parameter(Mandatory=$false)]
    [switch]$UseRedshift,
    
    [Parameter(Mandatory=$false)]
    [string]$RedshiftCluster = "your-cluster-name",
    
    [Parameter(Mandatory=$false)]
    [string]$RedshiftDatabase = "your-database",
  
    [Parameter(Mandatory=$false)]
    [string]$RedshiftUser = "your-user"
)

Write-Host "???????????????????????????????????????????????????" -ForegroundColor Cyan
Write-Host "  AWS GTN Data Sync - Exact DDL Match" -ForegroundColor Cyan
Write-Host "???????????????????????????????????????????????????" -ForegroundColor Cyan
Write-Host ""

# GTN tables from your cleaned DDL
$gtnTables = @(
    "apv2_operational_available_capacity",
    "apv2_gtn_unit_masterlist",
    "apv2_gtn_meter",
    "apv2_gtn_cs_unit",
 "apv2_gtn_station_masterlist",
    "apv2_gtn_segment_masterlist"
)

# TC tables from your cleaned DDL
$tcTables = @(
    "tc_compressordata",
    "tc_compressorplan",
    "tc_dailymeterreadings",
    "tc_pipemeasurements",
    "tc_capacity_configurations",
    "extracted_sql_queries"
)

Write-Host "?? Tables to sync:" -ForegroundColor Cyan
Write-Host "  GTN Tables: $($gtnTables.Count)" -ForegroundColor White
Write-Host "  TC Tables:  $($tcTables.Count)" -ForegroundColor White
Write-Host ""

if (-not (Test-Path $LocalCsvPath)) {
    Write-Host "?? Creating CSV folder..." -ForegroundColor Yellow
 New-Item -ItemType Directory -Path $LocalCsvPath -Force | Out-Null
}

# Function to download from S3
function Download-FromS3 {
  param($tableName)
    
    $s3Path = "s3://$S3Bucket/$S3Prefix${tableName}.csv"
    $localPath = "$LocalCsvPath\${tableName}.csv"
  
    try {
    if ($DryRun) {
 Write-Host "  [DRY RUN] Would download: $s3Path" -ForegroundColor DarkGray
       return $true
  }
        
        aws s3 cp $s3Path $localPath --quiet 2>&1 | Out-Null
     
        if ($LASTEXITCODE -eq 0) {
            $sizeMB = [math]::Round((Get-Item $localPath).Length / 1MB, 2)
            Write-Host "  ? $tableName.csv ($sizeMB MB)" -ForegroundColor Green
            return $true
        }
        else {
  Write-Host "  ? $tableName.csv (not found in S3)" -ForegroundColor Yellow
     return $false
        }
    }
    catch {
        Write-Host "  ? $tableName.csv (error: $_)" -ForegroundColor Red
        return $false
    }
}

# Function to export from Redshift
function Export-FromRedshift {
    param($tableName, $schema = "dbo")
    
    $localPath = "$LocalCsvPath\${tableName}.csv"
    
    if ($DryRun) {
        Write-Host "  [DRY RUN] Would export: $schema.$tableName from Redshift" -ForegroundColor DarkGray
        return $true
    }
    
    # Build psql/Redshift query
    $query = "COPY (SELECT * FROM $schema.$tableName) TO STDOUT WITH CSV HEADER"
    
    try {
        # Use AWS Redshift Data API or psql
     $cmd = "psql -h $RedshiftCluster.redshift.amazonaws.com -U $RedshiftUser -d $RedshiftDatabase -c ""$query"" > `"$localPath`""
        
     Write-Host "  ?? Exporting $tableName from Redshift..." -ForegroundColor Yellow
        Invoke-Expression $cmd
        
        if ($LASTEXITCODE -eq 0) {
         $sizeMB = [math]::Round((Get-Item $localPath).Length / 1MB, 2)
            Write-Host "  ? $tableName.csv ($sizeMB MB)" -ForegroundColor Green
            return $true
        }
        else {
      Write-Host "  ? $tableName.csv (export failed)" -ForegroundColor Red
        return $false
        }
    }
    catch {
        Write-Host "  ? $tableName.csv (error: $_)" -ForegroundColor Red
        return $false
    }
}

# Download/Export GTN tables
Write-Host "?? Syncing GTN tables..." -ForegroundColor Cyan
$gtnSuccess = 0
$gtnFailed = 0

foreach ($table in $gtnTables) {
    if ($UseRedshift) {
        # Try int_sol schema first, then pi schema
        $success = Export-FromRedshift -tableName $table -schema "int_sol"
   if (-not $success) {
            $success = Export-FromRedshift -tableName $table -schema "pi"
     }
 }
    else {
      $success = Download-FromS3 -tableName $table
    }
    
    if ($success) { $gtnSuccess++ } else { $gtnFailed++ }
}

Write-Host ""

# Download/Export TC tables
Write-Host "?? Syncing TC tables..." -ForegroundColor Cyan
$tcSuccess = 0
$tcFailed = 0

foreach ($table in $tcTables) {
    if ($UseRedshift) {
        $success = Export-FromRedshift -tableName $table -schema "dbo"
    }
    else {
        $success = Download-FromS3 -tableName $table
    }
    
    if ($success) { $tcSuccess++ } else { $tcFailed++ }
}

Write-Host ""
Write-Host "???????????????????????????????????????????????????" -ForegroundColor Cyan
Write-Host "?? Summary:" -ForegroundColor Cyan
Write-Host "  GTN Tables: $gtnSuccess/$($gtnTables.Count) downloaded" -ForegroundColor $(if($gtnSuccess -eq $gtnTables.Count){"Green"}else{"Yellow"})
Write-Host "  TC Tables:  $tcSuccess/$($tcTables.Count) downloaded" -ForegroundColor $(if($tcSuccess -eq $tcTables.Count){"Green"}else{"Yellow"})
Write-Host "  Failed:     $($gtnFailed + $tcFailed)" -ForegroundColor $(if(($gtnFailed + $tcFailed) -eq 0){"Green"}else{"Red"})
Write-Host ""

if (-not $DryRun) {
    # List downloaded files
    $csvFiles = Get-ChildItem "$LocalCsvPath\*.csv" -ErrorAction SilentlyContinue
    $totalSizeMB = [math]::Round(($csvFiles | Measure-Object -Property Length -Sum).Sum / 1MB, 2)
    
    Write-Host "?? Downloaded files: $($csvFiles.Count) CSV files ($totalSizeMB MB)" -ForegroundColor Cyan
    Write-Host ""
    
    # Next steps
    Write-Host "?? Next Steps:" -ForegroundColor Cyan
    Write-Host "  1. Verify CSV column names match DDL:" -ForegroundColor White
    Write-Host "     .\Check-CsvNames.ps1" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  2. Load in Startup Wizard:" -ForegroundColor White
    Write-Host "     dotnet run" -ForegroundColor DarkGray
    Write-Host "     http://localhost:5000/startup" -ForegroundColor DarkGray
    Write-Host ""
}

Write-Host "???????????????????????????????????????????????????" -ForegroundColor Cyan

# Exit code
if ($DryRun) {
    exit 0
}
elseif (($gtnSuccess + $tcSuccess) -eq 0) {
    Write-Host "??  No files downloaded. Check your configuration." -ForegroundColor Yellow
    exit 1
}
else {
    exit 0
}
