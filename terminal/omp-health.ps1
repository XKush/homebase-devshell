$logsRoot = if ($env:WORKSTATION_LOGS) { $env:WORKSTATION_LOGS } else { 'C:\Logs\Workstation' }
$p = Join-Path $logsRoot 'woc-last-session.json'
if (Test-Path $p) {
    $h = (Get-Content $p -Raw | ConvertFrom-Json).HealthScore
    Write-Output ("H:{0}" -f $h)
} else {
    Write-Output 'H:??'
}
