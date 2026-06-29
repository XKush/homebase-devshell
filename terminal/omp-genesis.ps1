$logsRoot = if ($env:WORKSTATION_LOGS) { $env:WORKSTATION_LOGS } else { 'C:\Logs\Workstation' }
$p = Join-Path $logsRoot 'genesis-state.json'
if (Test-Path $p) {
    $g = Get-Content $p -Raw | ConvertFrom-Json
    Write-Output $g.Callsign
} else {
    Write-Output 'OP:??'
}
