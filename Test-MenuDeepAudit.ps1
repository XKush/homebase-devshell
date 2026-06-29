#Requires -Version 7.0
<#
.SYNOPSIS
    Deep menu audit — go registry + command self-checks.
#>
$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'modules\KGreen.Workstation.psm1') -DisableNameChecking -Force

$audit = Test-WorkstationGoMenuAudit
if (-not $audit.OK) {
    foreach ($issue in $audit.Issues) {
        Write-Host "FAIL: $issue" -ForegroundColor Red
    }
    exit 1
}

$self = @(Invoke-AllCommandSelfChecks)
$selfFails = @($self | Where-Object { -not $_.OK })
if ($selfFails.Count) {
    foreach ($row in $selfFails) {
        Write-Host "FAIL selfcheck: $($row.Command) — $($row.Detail)" -ForegroundColor Red
    }
    exit 1
}

$total = $self.Count
Write-Host ("menu deep audit OK — registry={0} selfcheck={1}/{1}" -f $audit.Counts.registry, $total) -ForegroundColor Green
exit 0
