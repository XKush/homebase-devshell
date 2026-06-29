#Requires -Version 7.0
<#
.SYNOPSIS
    CI gate — Tor/PGP anonymity kit command wiring.
#>
$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'modules\KGreen.Workstation.psm1') -DisableNameChecking -Force

$result = Test-AnonymityKitAudit
if (-not $result.OK) {
    foreach ($issue in $result.Issues) {
        Write-Host "FAIL: $issue" -ForegroundColor Red
    }
    exit 1
}

Write-Host ("anon kit audit OK — $($result.KitCount) items, $($result.Essential) essential") -ForegroundColor Green
if ($result.Warnings.Count) {
    foreach ($w in $result.Warnings) {
        Write-Host "WARN: $w" -ForegroundColor Yellow
    }
}
exit 0
