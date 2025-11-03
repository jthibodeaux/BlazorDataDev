# Remove duplicate table definitions from DDL file
param(
    [Parameter(Mandatory=$true)]
    [string]$InputFile,
    
    [Parameter(Mandatory=$false)]
    [string]$OutputFile
)

if ([string]::IsNullOrEmpty($OutputFile)) {
    $OutputFile = $InputFile -replace '\.sql$', '-deduped.sql'
}

Write-Host "?? Deduplicating DDL File..." -ForegroundColor Cyan
Write-Host "Input:  $InputFile" -ForegroundColor White
Write-Host "Output: $OutputFile" -ForegroundColor White
Write-Host ""

# Read file
$content = Get-Content $InputFile -Raw

# Split by CREATE TABLE statements
$tablePattern = '(?m)^--\s*dbo\.(\w+)\s+definition.*?(?=^--\s*dbo\.\w+\s+definition|$)'
$matches = [regex]::Matches($content, $tablePattern, [System.Text.RegularExpressions.RegexOptions]::Singleline)

$seenTables = @{}
$keptDefinitions = @()
$removedCount = 0

foreach ($match in $matches) {
    $fullText = $match.Value
    
    # Extract table name
 if ($fullText -match '--\s*dbo\.(\w+)\s+definition') {
      $tableName = $matches[1]
        
   if ($seenTables.ContainsKey($tableName)) {
       Write-Host "  ??  Skipping duplicate: dbo.$tableName" -ForegroundColor Yellow
      $removedCount++
        }
        else {
       $seenTables[$tableName] = $true
       $keptDefinitions += $fullText
Write-Host "  ? Keeping: dbo.$tableName" -ForegroundColor Green
     }
  }
}

# Reconstruct file
$newContent = $keptDefinitions -join "`n`n"

# Save
$newContent | Out-File -FilePath $OutputFile -Encoding UTF8 -NoNewline

Write-Host ""
Write-Host "? Deduplication complete!" -ForegroundColor Green
Write-Host "?? Removed $removedCount duplicate definitions" -ForegroundColor Cyan
Write-Host "?? Saved to: $OutputFile" -ForegroundColor Cyan
