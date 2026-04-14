# Convert ABS xlsx files to CSV for R2019a compatibility
# Uses Excel COM automation (runs faster than MATLAB's xlsread because it's a one-shot process)

$datadir = Split-Path -Parent $MyInvocation.MyCommand.Path

$files = @(
    @{ xlsx = "abs_5206_vol.xlsx"; csv = "abs_5206_vol.csv"; sheet = "Data1" },
    @{ xlsx = "abs_6416_rppi.xlsx"; csv = "abs_6416_rppi.csv"; sheet = "Data1" }
)

$excel = $null
try {
    $excel = New-Object -ComObject Excel.Application
    $excel.Visible = $false
    $excel.DisplayAlerts = $false

    foreach ($f in $files) {
        $xlsxPath = Join-Path $datadir $f.xlsx
        $csvPath = Join-Path $datadir $f.csv

        if (-not (Test-Path $xlsxPath)) {
            Write-Host "SKIP: $($f.xlsx) not found"
            continue
        }
        if (Test-Path $csvPath) {
            $size = (Get-Item $csvPath).Length
            Write-Host "SKIP: $($f.csv) already exists ($size bytes)"
            continue
        }

        Write-Host "Converting $($f.xlsx) -> $($f.csv)..."
        $wb = $excel.Workbooks.Open($xlsxPath)
        $ws = $wb.Sheets.Item($f.sheet)
        $ws.Copy()  # Copy to new workbook (so SaveAs doesn't affect original)
        $newWb = $excel.ActiveWorkbook
        $newWb.SaveAs($csvPath, 6)  # 6 = xlCSV
        $newWb.Close($false)
        $wb.Close($false)

        if (Test-Path $csvPath) {
            $size = (Get-Item $csvPath).Length
            Write-Host "  OK: $($f.csv) ($size bytes)"
        } else {
            Write-Host "  ERROR: $($f.csv) not created"
        }
    }
} catch {
    Write-Host "ERROR: $($_.Exception.Message)"
} finally {
    if ($excel) {
        $excel.Quit()
        [System.Runtime.InteropServices.Marshal]::ReleaseComObject($excel) | Out-Null
        [System.GC]::Collect()
    }
}

Write-Host "Done."
