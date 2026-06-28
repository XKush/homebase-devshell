$p = 'C:\Logs\Workstation\genesis-state.json'
if (Test-Path $p) {
    $g = Get-Content $p -Raw | ConvertFrom-Json
    Write-Output $g.Callsign
} else {
    Write-Output 'OP:??'
}
