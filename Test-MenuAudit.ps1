#Requires -Version 7.0
<#
.SYNOPSIS
    CI gate — go menu registry, fzf views, and home recommendation targets.
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

Write-Host ("menu audit OK — registry={0} views={1} catalog={2}" -f `
    $audit.Counts.registry, $audit.Counts.views, $audit.Counts.catalog) -ForegroundColor Green
exit 0
