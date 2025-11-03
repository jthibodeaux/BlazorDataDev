# Check CSV filenames against DDL table names
param(
    [Parameter(Mandatory=$false)]
    [string]$CsvPath = "Loadables\csv",
    
    [Parameter(Mandatory=$false)]
    [string]$DdlPath = "Loadables\ddls"
)

Write-Host "?? CSV Filename Checker" -ForegroundColor Cyan
Write-Host ""

# Get DDL files
$ddlFiles = Get-ChildItem -Path $DdlPath -Filter "*.sql" -Recurse | Select-Object -First 1
if (-not $ddlFiles) {
    Write-Host "? No DDL files found in $DdlPath" -ForegroundColor Red
  exit
}

Write-Host "?? Reading DDL: $($ddlFiles.Name)" -ForegroundColor White

# Extract table names from DDL
$ddlContent = Get-Content $ddlFiles.FullName -Raw
$tablePattern = 'CREATE TABLE (?:dbo\.)?(\w+)'
$tables = [regex]::Matches($ddlContent, $tablePattern) | ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique

Write-Host "? Found $($tables.Count) tables in DDL" -ForegroundColor Green
Write-Host ""

# Get CSV files
$csvFiles = Get-ChildItem -Path $CsvPath -Filter "*.csv" -Recurse

Write-Host "?? Checking CSV files in: $CsvPath" -ForegroundColor White
Write-Host "? Found $($csvFiles.Count) CSV files" -ForegroundColor Green
Write-Host ""

# Check each CSV
$matching = @()
$notMatching = @()

foreach ($csv in $csvFiles) {
    $csvName = $csv.BaseName
    
    if ($tables -contains $csvName) {
        $matching += $csv
  Write-Host "  ? $($csv.Name) ? matches table '$csvName'" -ForegroundColor Green
    }
    else {
        $notMatching += $csv
        Write-Host "  ? $($csv.Name) ? NO MATCH" -ForegroundColor Red
        
        # Try to find similar table names
        $similar = $tables | Where-Object { $_ -like "*$csvName*" -or $csvName -like "*$_*" }
        if ($similar) {
     Write-Host "     ?? Similar tables found:" -ForegroundColor Yellow
            foreach ($s in $similar) {
      Write-Host "        - $s" -ForegroundColor Yellow
    }
        }
    }
}

Write-Host ""
Write-Host "???????????????????????????????????????" -ForegroundColor Cyan
Write-Host "?? Summary:" -ForegroundColor Cyan
Write-Host "  ? Matching: $($matching.Count)" -ForegroundColor Green
Write-Host "  ? Not Matching: $($notMatching.Count)" -ForegroundColor Red
Write-Host "???????????????????????????????????????" -ForegroundColor Cyan

if ($notMatching.Count -gt 0) {
    Write-Host ""
    Write-Host "?? Suggested Renames:" -ForegroundColor Yellow
    Write-Host ""
    
    foreach ($csv in $notMatching) {
        $csvName = $csv.BaseName
        
        # Try to find best match
        $bestMatch = $tables | Where-Object { 
          $_ -like "*$csvName*" -or 
 $csvName -like "*$_*" -or
      ($_ -replace '_', '-') -eq ($csvName -replace '_', '-')
  } | Select-Object -First 1
        
        if ($bestMatch) {
     Write-Host "  Rename-Item `"$($csv.Name)`" `"$bestMatch.csv`"" -ForegroundColor Cyan
 }
        else {
            Write-Host "  # $($csv.Name) - no similar table found, review manually" -ForegroundColor Gray
        }
    }
    
    Write-Host ""
    Write-Host "?? Copy the commands above and run them in your CSV folder!" -ForegroundColor Yellow
}
else {
    Write-Host ""
    Write-Host "?? All CSV files match table names!" -ForegroundColor Green
}
