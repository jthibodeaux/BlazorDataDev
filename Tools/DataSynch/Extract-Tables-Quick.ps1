# Quick Table Extractor - Paste your JSON directly into this script
# Or provide path as parameter: .\Extract-Tables-Quick.ps1 -JsonPath "your-file.json"

param([string]$JsonPath)

# If no path provided, paste JSON here:
$jsonContent = @'
{
"extracted_sql_queries": [
    # PASTE YOUR JSON HERE
]
}
'@

if ($JsonPath -and (Test-Path $JsonPath)) {
    $jsonContent = Get-Content $JsonPath -Raw
}

Write-Host "Parsing SQL queries..." -ForegroundColor Cyan

$json = $jsonContent | ConvertFrom-Json
$tables = @{}

# Extract tables from SQL
foreach ($q in $json.extracted_sql_queries) {
    $sql = $q.sql_text
    $db = $q.dbname
  
    # Match FROM/JOIN patterns
    $pattern = '(?:FROM|JOIN)\s+(?:(\w+)\.)?(\w+)'
    [regex]::Matches($sql, $pattern, 'IgnoreCase') | ForEach-Object {
      $schema = if ($_.Groups[1].Value) { $_.Groups[1].Value } else { 'dbo' }
        $table = $_.Groups[2].Value
        
    # Skip CTEs
if ($table -notmatch '^(cte|base|ranked|latest|temp)') {
      $key = "$db.$schema.$table"
   if (-not $tables.ContainsKey($key)) {
   $tables[$key] = @{
       DB = $db
              Schema = $schema
Table = $table
           }
   }
        }
 }
}

# Display results
Write-Host "`n?? Found $($tables.Count) unique tables:`n" -ForegroundColor Green

$tables.Values | 
    Sort-Object DB, Schema, Table | 
    Group-Object DB | 
 ForEach-Object {
      Write-Host "???  $($_.Name)" -ForegroundColor Cyan
        $_.Group | Group-Object Schema | ForEach-Object {
     Write-Host "   ?? $($_.Name) ($($_.Count) tables)" -ForegroundColor Yellow
            $_.Group | ForEach-Object {
   Write-Host "    - $($_.Table)" -ForegroundColor White
   }
        }
        Write-Host ""
    }

# Export to CSV
$tables.Values | 
Sort-Object DB, Schema, Table | 
    Export-Csv "tables-list.csv" -NoTypeInformation

Write-Host "? Exported to tables-list.csv" -ForegroundColor Green
