# Rename CSV files to match DDL table names
# Run this in your CSV folder: cd Loadables\csv

Write-Host "?? Renaming CSV files to match table names..." -ForegroundColor Cyan
Write-Host ""

$renames = @(
    @{ Old = "apv2_gtn_unit_masterlist..csv"; New = "apv2_gtn_unit_masterlist.csv" }
  @{ Old = "compressor-data.csv"; New = "tc_compressordata.csv" }
    @{ Old = "compressor-plan.csv"; New = "tc_compressorplan.csv" }
    @{ Old = "dailyneterreadings.csv"; New = "tc_dailymeterreadings.csv" }
    @{ Old = "extracted_sql_queries_202509102208.csv"; New = "extracted_sql_queries.csv" }
    @{ Old = "gtn-cs_unit.csv"; New = "apv2_gtn_cs_unit.csv" }
    @{ Old = "gtn-int_sol.operational_capacity.csv"; New = "apv2_operational_available_capacity.csv" }
    @{ Old = "gtn-segments.csv"; New = "apv2_gtn_segment_masterlist.csv" }
    @{ Old = "gtn-stations.csv"; New = "apv2_gtn_station_masterlist.csv" }
    @{ Old = "tc_pipe-measurements.csv"; New = "tc_pipemeasurements.csv" }
)

$csvPath = "Loadables\csv"
$successCount = 0
$skipCount = 0

foreach ($rename in $renames) {
    $oldPath = Join-Path $csvPath $rename.Old
    $newPath = Join-Path $csvPath $rename.New
    
    if (Test-Path $oldPath) {
        if (Test-Path $newPath) {
Write-Host "  ??  Skipping: $($rename.New) already exists" -ForegroundColor Yellow
            $skipCount++
 }
        else {
          Rename-Item -Path $oldPath -NewName $rename.New
   Write-Host "  ? $($rename.Old) ? $($rename.New)" -ForegroundColor Green
     $successCount++
        }
    }
    else {
        Write-Host "  ? Not found: $($rename.Old)" -ForegroundColor Gray
    }
}

Write-Host ""
Write-Host "???????????????????????????????????????" -ForegroundColor Cyan
Write-Host "?? Results:" -ForegroundColor Cyan
Write-Host "  ? Renamed: $successCount" -ForegroundColor Green
Write-Host "  ??  Skipped: $skipCount" -ForegroundColor Yellow
Write-Host "???????????????????????????????????????" -ForegroundColor Cyan
Write-Host ""
Write-Host "?? Done! Now reload in Startup Wizard." -ForegroundColor Green
