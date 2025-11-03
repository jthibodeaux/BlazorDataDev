# AWS Data Sync Script for NBPL Pipeline Data
# Downloads schema and CSV files from S3 to Loadables folder

param(
    [Parameter(Mandatory=$false)]
    [string]$S3Bucket = "your-bucket-name",
    
    [Parameter(Mandatory=$false)]
    [string]$S3Prefix = "nbpl-exports/",
    
    [Parameter(Mandatory=$false)]
    [string]$LocalPath = "./Loadables",
    
    [Parameter(Mandatory=$false)]
    [switch]$DryRun,
    
    [Parameter(Mandatory=$false)]
    [switch]$SchemaOnly,
    
    [Parameter(Mandatory=$false)]
    [switch]$DataOnly
)

Write-Host "???????????????????????????????????????????????????" -ForegroundColor Cyan
Write-Host "  AWS S3 ? Loadables Sync for NBPL Data" -ForegroundColor Cyan
Write-Host "???????????????????????????????????????????????????" -ForegroundColor Cyan
Write-Host ""

# Check AWS CLI
try {
    $awsVersion = aws --version 2>&1
  Write-Host "? AWS CLI found: $awsVersion" -ForegroundColor Green
}
catch {
    Write-Host "? AWS CLI not found. Please install:" -ForegroundColor Red
    Write-Host "   https://aws.amazon.com/cli/" -ForegroundColor Yellow
    exit 1
}

# Ensure Loadables folder exists
if (-not (Test-Path $LocalPath)) {
    Write-Host "?? Creating Loadables folder..." -ForegroundColor Yellow
    New-Item -ItemType Directory -Path $LocalPath | Out-Null
}

Write-Host "?? Configuration:" -ForegroundColor Cyan
Write-Host "  S3 Bucket:  $S3Bucket" -ForegroundColor White
Write-Host "  S3 Prefix:  $S3Prefix" -ForegroundColor White
Write-Host "  Local Path: $LocalPath" -ForegroundColor White
Write-Host "  Dry Run:    $DryRun" -ForegroundColor White
Write-Host ""

if ($DryRun) {
  Write-Host "?? DRY RUN MODE - No files will be downloaded" -ForegroundColor Yellow
    Write-Host ""
}

# Download Schema
if (-not $DataOnly) {
    Write-Host "?? Downloading DDL schema..." -ForegroundColor Yellow

    $schemaFiles = @("schema.sql", "nbpl_schema.sql", "ddl.sql")
    $foundSchema = $false
 
    foreach ($schemaFile in $schemaFiles) {
        $s3SchemaPath = "s3://$S3Bucket/$S3Prefix$schemaFile"
  $localSchemaPath = "$LocalPath/$schemaFile"
     
 try {
            if ($DryRun) {
   Write-Host "  Would download: $s3SchemaPath ? $localSchemaPath" -ForegroundColor DarkGray
            }
    else {
          aws s3 cp $s3SchemaPath $localSchemaPath --quiet 2>$null
         if ($LASTEXITCODE -eq 0) {
          Write-Host "  ? Downloaded: $schemaFile" -ForegroundColor Green
          $foundSchema = $true
break
     }
            }
     }
        catch {
     # Try next file
  }
    }
    
    if (-not $foundSchema -and -not $DryRun) {
        Write-Host "  ??  No schema file found. Tried: $($schemaFiles -join ', ')" -ForegroundColor Yellow
    }
}

# Download CSV files
if (-not $SchemaOnly) {
    Write-Host "?? Downloading CSV files..." -ForegroundColor Yellow
    
    $s3Path = "s3://$S3Bucket/$S3Prefix"
    
    if ($DryRun) {
        Write-Host "  Would sync: $s3Path ? $LocalPath (*.csv only)" -ForegroundColor DarkGray
  
        # List files that would be downloaded
        $files = aws s3 ls $s3Path --recursive | Where-Object { $_ -match '\.csv$' }
        if ($files) {
            Write-Host "  Files found:" -ForegroundColor DarkGray
       $files | ForEach-Object {
   $fileName = ($_ -split '\s+')[-1]
         Write-Host "    - $fileName" -ForegroundColor DarkGray
     }
        }
    }
    else {
      # Sync only CSV files
 aws s3 sync $s3Path $LocalPath --exclude "*" --include "*.csv" --quiet
        
        if ($LASTEXITCODE -eq 0) {
$csvCount = (Get-ChildItem "$LocalPath\*.csv" -ErrorAction SilentlyContinue).Count
     Write-Host "  ? Downloaded $csvCount CSV files" -ForegroundColor Green
   }
        else {
          Write-Host "  ? Error syncing CSV files" -ForegroundColor Red
     }
    }
}

Write-Host ""
Write-Host "???????????????????????????????????????????????????" -ForegroundColor Cyan

if (-not $DryRun) {
    # Summary
$schemaFiles = Get-ChildItem "$LocalPath\*.sql" -ErrorAction SilentlyContinue
    $csvFiles = Get-ChildItem "$LocalPath\*.csv" -ErrorAction SilentlyContinue
    
    Write-Host "?? Summary:" -ForegroundColor Cyan
    Write-Host "  Schema files: $($schemaFiles.Count)" -ForegroundColor White
    Write-Host "  CSV files:    $($csvFiles.Count)" -ForegroundColor White
    Write-Host ""
    
    if ($schemaFiles.Count -gt 0) {
    Write-Host "DDL Files:" -ForegroundColor Yellow
        $schemaFiles | ForEach-Object {
            $sizeMB = [math]::Round($_.Length / 1MB, 2)
            Write-Host "  ? $($_.Name) ($sizeMB MB)" -ForegroundColor Green
  }
 Write-Host ""
    }
    
    if ($csvFiles.Count -gt 0) {
        Write-Host "CSV Files (top 10):" -ForegroundColor Yellow
$csvFiles | Select-Object -First 10 | ForEach-Object {
        $sizeMB = [math]::Round($_.Length / 1MB, 2)
     Write-Host "  ? $($_.Name) ($sizeMB MB)" -ForegroundColor Green
        }
        
    if ($csvFiles.Count > 10) {
    Write-Host "  ... and $($csvFiles.Count - 10) more files" -ForegroundColor DarkGray
        }
        Write-Host ""
  }
 
    # Calculate total size
    $totalSizeMB = [math]::Round((($schemaFiles + $csvFiles) | Measure-Object -Property Length -Sum).Sum / 1MB, 2)
    Write-Host "  Total size: $totalSizeMB MB" -ForegroundColor Cyan
    Write-Host ""
    
    # Next steps
    Write-Host "?? Next Steps:" -ForegroundColor Cyan
    Write-Host "  1. Check if DDL needs cleaning:" -ForegroundColor White
    Write-Host "     .\Clean-DDL.ps1 -InputFile ""$LocalPath\schema.sql""" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  2. Start the application:" -ForegroundColor White
    Write-Host "     dotnet run" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  3. Navigate to startup wizard:" -ForegroundColor White
    Write-Host "     http://localhost:5000/startup" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  4. Click 'Start Auto-Load'" -ForegroundColor White
    Write-Host ""
}
else {
    Write-Host "? Dry run complete. Re-run without -DryRun to download files." -ForegroundColor Green
    Write-Host ""
}

Write-Host "???????????????????????????????????????????????????" -ForegroundColor Cyan

# Exit codes
if ($DryRun) {
    exit 0
}
elseif ($schemaFiles.Count -eq 0 -and $csvFiles.Count -eq 0) {
    Write-Host "??  Warning: No files downloaded. Check your S3 bucket and prefix." -ForegroundColor Yellow
    exit 1
}
else {
    exit 0
}
