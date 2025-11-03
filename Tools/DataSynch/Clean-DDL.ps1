# Clean-DDL.ps1
# Automatically cleans PostgreSQL DDL files for compatibility
# Removes Redshift-specific syntax, fixes common errors

param(
    [Parameter(Mandatory=$false)]
    [string]$InputFile = "original-ddl.sql",
    
    [Parameter(Mandatory=$false)]
    [string]$OutputFile = "cleaned-ddl.sql"
)

Write-Host "?? Cleaning DDL File..." -ForegroundColor Cyan
Write-Host "Input:  $InputFile" -ForegroundColor Gray
Write-Host "Output: $OutputFile" -ForegroundColor Gray
Write-Host ""

if (-not (Test-Path $InputFile)) {
    Write-Host "? Error: Input file not found: $InputFile" -ForegroundColor Red
    exit 1
}

# Read the DDL file
$content = Get-Content $InputFile -Raw

Write-Host "?? Original file size: $($content.Length) characters" -ForegroundColor Gray

# Track changes
$changeCount = 0

# 1. Remove ENCODE clauses (Redshift-specific)
Write-Host "?? Removing ENCODE clauses..." -ForegroundColor Yellow
$before = $content
$content = $content -replace '\s+ENCODE\s+[a-zA-Z0-9_]+', ''
if ($content -ne $before) { 
    $changeCount++
    Write-Host "   ? Removed ENCODE clauses" -ForegroundColor Green
}

# 2. Remove DEFAULT clauses with ENCODE
$before = $content
$content = $content -replace 'DEFAULT\s+[^,\)]+\s+ENCODE\s+[a-zA-Z0-9_]+', ''
if ($content -ne $before) { 
    $changeCount++
    Write-Host "   ? Removed DEFAULT...ENCODE patterns" -ForegroundColor Green
}

# 3. Fix trailing commas before closing parenthesis
Write-Host "?? Fixing trailing commas..." -ForegroundColor Yellow
$before = $content
$content = $content -replace ',(\s*\n\s*\))', '$1'
if ($content -ne $before) { 
    $changeCount++
    Write-Host "   ? Fixed trailing commas" -ForegroundColor Green
}

# 4. Remove duplicate empty lines
Write-Host "?? Cleaning whitespace..." -ForegroundColor Yellow
$before = $content
$content = $content -replace '\n\n\n+', "`n`n"
if ($content -ne $before) { 
    $changeCount++
    Write-Host "   ? Cleaned whitespace" -ForegroundColor Green
}

# 5. Normalize CREATE TABLE IF NOT EXISTS to just CREATE TABLE
Write-Host "?? Normalizing CREATE TABLE syntax..." -ForegroundColor Yellow
$before = $content
$content = $content -replace 'CREATE TABLE IF NOT EXISTS', 'CREATE TABLE'
if ($content -ne $before) { 
    $changeCount++
    Write-Host "   ? Normalized CREATE TABLE" -ForegroundColor Green
}

# 6. Remove table triggers (often cause issues without functions)
Write-Host "?? Removing table triggers..." -ForegroundColor Yellow
$before = $content
$content = $content -replace '-- Table Triggers[\s\S]*?;', ''
$content = $content -replace 'create trigger[\s\S]*?;', ''
if ($content -ne $before) { 
  $changeCount++
    Write-Host "   ? Removed table triggers" -ForegroundColor Green
}

# 7. Report on commented-out constraints
$commentedPKs = ([regex]::Matches($content, '--\s*CONSTRAINT.*PRIMARY KEY')).Count
if ($commentedPKs -gt 0) {
    Write-Host "??  Warning: Found $commentedPKs commented PRIMARY KEYs" -ForegroundColor Yellow
}

# 8. Detect duplicate table definitions
$tableNames = [regex]::Matches($content, 'CREATE TABLE\s+(?:IF NOT EXISTS\s+)?([a-zA-Z0-9_.]+)') | 
    ForEach-Object { $_.Groups[1].Value }
$duplicates = $tableNames | Group-Object | Where-Object { $_.Count -gt 1 }

if ($duplicates) {
    Write-Host "   ??  Warning: Found duplicate table definitions:" -ForegroundColor Yellow
    foreach ($dup in $duplicates) {
        Write-Host "      - $($dup.Name) ($($dup.Count) times)" -ForegroundColor Red
    }
}

# Save cleaned file
$content | Out-File $OutputFile -Encoding UTF8 -NoNewline

Write-Host ""
Write-Host "? Cleaning complete!" -ForegroundColor Green
Write-Host "?? Final file size: $($content.Length) characters" -ForegroundColor Gray
Write-Host "?? Changes made: $changeCount categories" -ForegroundColor Cyan
Write-Host ""
Write-Host "?? Cleaned DDL saved to: $OutputFile" -ForegroundColor Green
Write-Host ""

# Summary
Write-Host "?????????????????????????????????????" -ForegroundColor DarkGray
Write-Host "Summary:" -ForegroundColor Cyan
Write-Host "  ? Removed Redshift ENCODE clauses" -ForegroundColor Green
Write-Host "  ? Fixed trailing commas" -ForegroundColor Green
Write-Host "  ? Cleaned whitespace" -ForegroundColor Green
Write-Host "  ? Normalized CREATE TABLE syntax" -ForegroundColor Green
Write-Host "  ? Removed problematic triggers" -ForegroundColor Green

if ($duplicates) {
    Write-Host "  ??  Manual review needed for duplicates" -ForegroundColor Yellow
}
if ($commentedPKs -gt 0) {
  Write-Host "  ??  Manual review needed for commented PKs" -ForegroundColor Yellow
}

Write-Host "?????????????????????????????????????" -ForegroundColor DarkGray
Write-Host ""
Write-Host "?? Next steps:" -ForegroundColor Cyan
Write-Host "   1. Review $OutputFile for any warnings above" -ForegroundColor White
Write-Host "   2. Load $OutputFile in Blazor DB Editor" -ForegroundColor White
Write-Host "   3. Import your CSV data" -ForegroundColor White

# Additional automatic fixes
Write-Host "?? Applying additional automated fixes..." -ForegroundColor Yellow

    # Remove Redshift-specific ENCODE clauses
    Write-Host "  Removing Redshift ENCODE clauses..." -ForegroundColor Yellow
  $content = $content -replace '\s+ENCODE\s+\w+', ''
    
    # Convert CREATE TABLE IF NOT EXISTS to standard CREATE TABLE
    Write-Host "  Converting 'CREATE TABLE IF NOT EXISTS' to standard syntax..." -ForegroundColor Yellow
    $content = $content -replace 'CREATE\s+TABLE\s+IF\s+NOT\s+EXISTS\s+', 'CREATE TABLE '
    
    # Fix schema-qualified table names (int_sol.table, pi.table -> dbo.table) - BEFORE adding dbo prefix
    Write-Host "  Converting int_sol and pi schemas to dbo..." -ForegroundColor Yellow
    $content = $content -replace 'CREATE\s+TABLE\s+int_sol\.', 'CREATE TABLE dbo.'
    $content = $content -replace 'CREATE\s+TABLE\s+pi\.', 'CREATE TABLE dbo.'

    # Add dbo schema to tables missing it
    Write-Host "  Adding dbo. schema prefix where missing..." -ForegroundColor Yellow
    $content = $content -replace 'CREATE\s+TABLE\s+(?!dbo\.)(\w+)', 'CREATE TABLE dbo.$1'
  
    # Clean up any double schema prefixes (dbo.pi.table -> dbo.table, dbo.int_sol.table -> dbo.table)
    Write-Host "  Cleaning up double schema prefixes..." -ForegroundColor Yellow
    $content = $content -replace 'dbo\.pi\.', 'dbo.'
    $content = $content -replace 'dbo\.int_sol\.', 'dbo.'

# Save final output after additional fixes
$content | Out-File $OutputFile -Encoding UTF8 -NoNewline

Write-Host "? Additional fixes applied and saved to $OutputFile" -ForegroundColor Green
