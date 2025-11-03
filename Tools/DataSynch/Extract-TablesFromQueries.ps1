# Extract all unique tables from SQL Query Manager JSON
param(
    [Parameter(Mandatory=$false)]
    [string]$JsonPath = "sql-queries.json",
    
    [Parameter(Mandatory=$false)]
    [string]$OutputFile = "extracted-tables-list.md"
)

Write-Host "?? Extracting Tables from SQL Queries..." -ForegroundColor Cyan
Write-Host ""

# Read JSON
if (-not (Test-Path $JsonPath)) {
    Write-Host "? JSON file not found: $JsonPath" -ForegroundColor Red
    exit 1
}

$json = Get-Content $JsonPath -Raw | ConvertFrom-Json
$queries = $json.extracted_sql_queries

Write-Host "? Found $($queries.Count) SQL queries" -ForegroundColor Green
Write-Host ""

# Regex patterns for table extraction
$tablePatterns = @(
    # FROM clause
    'FROM\s+(?:(?<schema>\w+)\.)?(?<table>\w+)',
    # JOIN clause
    'JOIN\s+(?:(?<schema>\w+)\.)?(?<table>\w+)',
    # INNER/LEFT/RIGHT/FULL JOIN
    '(?:INNER|LEFT|RIGHT|FULL)\s+JOIN\s+(?:(?<schema>\w+)\.)?(?<table>\w+)',
    # INSERT INTO
    'INSERT\s+INTO\s+(?:(?<schema>\w+)\.)?(?<table>\w+)',
    # UPDATE
    'UPDATE\s+(?:(?<schema>\w+)\.)?(?<table>\w+)',
    # DELETE FROM
    'DELETE\s+FROM\s+(?:(?<schema>\w+)\.)?(?<table>\w+)',
    # CREATE TABLE
    'CREATE\s+TABLE\s+(?:IF\s+NOT\s+EXISTS\s+)?(?:(?<schema>\w+)\.)?(?<table>\w+)'
)

# Track tables by database
$tablesByDatabase = @{}

foreach ($query in $queries) {
    $sqlText = $query.sql_text
    $dbName = $query.dbname
    
    if (-not $tablesByDatabase.ContainsKey($dbName)) {
        $tablesByDatabase[$dbName] = @{}
    }
    
    foreach ($pattern in $tablePatterns) {
        $matches = [regex]::Matches($sqlText, $pattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
        
        foreach ($match in $matches) {
      $schema = $match.Groups['schema'].Value
  $table = $match.Groups['table'].Value
     
      if ([string]::IsNullOrWhiteSpace($schema)) {
  $schema = "dbo"  # Default schema
            }
  
      # Skip CTE names, subquery aliases, etc.
$skipNames = @('cte', 'ranked', 'base', 'with', 'latest', 'subq', 'temp', 'final', 'row_number', 'partition')
            if ($skipNames -contains $table.ToLower()) {
      continue
    }
            
            # Add to schema dictionary
     if (-not $tablesByDatabase[$dbName].ContainsKey($schema)) {
      $tablesByDatabase[$dbName][$schema] = @()
            }
            
            if ($tablesByDatabase[$dbName][$schema] -notcontains $table) {
     $tablesByDatabase[$dbName][$schema] += $table
  }
        }
 }
}

# Generate markdown report
$markdown = @"
# ?? SQL Query Manager - Database Tables Reference

**Generated:** $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")  
**Total Queries Analyzed:** $($queries.Count)  
**Databases Found:** $($tablesByDatabase.Keys.Count)

---

"@

# Summary section
$markdown += "`n## ?? Summary`n`n"
$markdown += "| Database | Schemas | Total Tables |`n"
$markdown += "|----------|---------|-------------|`n"

foreach ($db in $tablesByDatabase.Keys | Sort-Object) {
    $schemaCount = $tablesByDatabase[$db].Keys.Count
    $tableCount = ($tablesByDatabase[$db].Values | ForEach-Object { $_.Count } | Measure-Object -Sum).Sum
    $markdown += "| **$db** | $schemaCount | $tableCount |`n"
}

# Detailed sections by database
foreach ($db in $tablesByDatabase.Keys | Sort-Object) {
    $markdown += "`n---`n`n"
    $markdown += "## ??? Database: ``$db```n`n"
    
    foreach ($schema in $tablesByDatabase[$db].Keys | Sort-Object) {
 $tables = $tablesByDatabase[$db][$schema] | Sort-Object -Unique
        $markdown += "`n### Schema: ``$schema`` ($($tables.Count) tables)`n`n"
        
        # Group tables by prefix
        $grouped = $tables | Group-Object { 
            if ($_ -match '^(\w+?)_') { $matches[1] } else { 'other' }
   } | Sort-Object Name
    
        foreach ($group in $grouped) {
       if ($group.Name -ne 'other') {
      $markdown += "`n**$($group.Name)_* tables ($($group.Count)):**`n`n"
     } else {
         $markdown += "`n**Other tables ($($group.Count)):**`n`n"
       }

            foreach ($table in $group.Group | Sort-Object) {
                $markdown += "- ``$schema.$table```n"
      }
        }
    }
}

# Add DDL generation section
$markdown += "`n---`n`n"
$markdown += "## ??? DDL Generation`n`n"
$markdown += "### Extract DDL from Source Databases`n`n"
$markdown += "**PostgreSQL:**`n``````sql`n"

foreach ($db in @('TCExternalConnection', 'DefaultConnection', 'RedshiftConnection')) {
    if ($tablesByDatabase.ContainsKey($db)) {
   foreach ($schema in $tablesByDatabase[$db].Keys | Sort-Object) {
  foreach ($table in $tablesByDatabase[$db][$schema] | Sort-Object) {
                $markdown += "-- Extract DDL for $schema.$table`n"
   $markdown += "SELECT 'CREATE TABLE $schema.$table (' ||`n"
                $markdown += "       string_agg(column_name || ' ' || data_type, ', ') ||`n"
    $markdown += "       ')' AS ddl`n"
         $markdown += "FROM information_schema.columns`n"
      $markdown += "WHERE table_schema = '$schema' AND table_name = '$table';`n`n"
            }
   }
    }
}

$markdown += "```````n`n"

# Query usage section
$markdown += "## ?? Query Usage by Database`n`n"

$queryCountByDb = $queries | Group-Object dbname | Sort-Object Count -Descending
foreach ($group in $queryCountByDb) {
    $markdown += "- **$($group.Name):** $($group.Count) queries`n"
}

# Save to file
$markdown | Out-File -FilePath $OutputFile -Encoding UTF8
Write-Host "? Report generated: $OutputFile" -ForegroundColor Green

# Display summary
Write-Host ""
Write-Host "???????????????????????????????????????" -ForegroundColor Cyan
Write-Host "?? Extraction Summary:" -ForegroundColor Cyan
Write-Host "  Databases: $($tablesByDatabase.Keys.Count)" -ForegroundColor White

foreach ($db in $tablesByDatabase.Keys | Sort-Object) {
    $tableCount = ($tablesByDatabase[$db].Values | ForEach-Object { $_.Count } | Measure-Object -Sum).Sum
    Write-Host "    - $db`: $tableCount tables" -ForegroundColor Gray
}

Write-Host "???????????????????????????????????????" -ForegroundColor Cyan
Write-Host ""
Write-Host "?? Output: $OutputFile" -ForegroundColor Cyan
