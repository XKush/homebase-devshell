#Requires -Version 7.0
# CI / pre-flight hook — command health + trust probe

param([switch]$Quick)

$ErrorActionPreference = 'Continue'
$root = 'C:\Scripts\Workstation'
$fail = 0

& (Join-Path $root 'Test-WorkstationCommands.ps1') @($(if ($Quick) { '-Quick' }))
if ($LASTEXITCODE) { $fail++ }

& (Join-Path $root 'Invoke-ScheduledTrustProbe.ps1')
if ($LASTEXITCODE) { $fail++ }

if ($fail) {
    Write-Host "CI FAIL: $fail check(s) failed" -ForegroundColor Red
    exit 1
}
Write-Host 'CI OK: commands + trust verified' -ForegroundColor Green
exit 0
