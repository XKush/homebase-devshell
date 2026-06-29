#Requires -Version 7.0
<#
.SYNOPSIS
    CI smoke for devshell health — validates JSON contract on any runner state.
#>
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '_Test-Common.ps1')
$Root = Get-TestWorkstationRoot -Start $PSScriptRoot

Write-Host 'Health smoke' -ForegroundColor Cyan

$doc = Invoke-TestHealthJson -Root $Root -SkipHistory

if (-not $doc.healthSchemaVersion) { throw 'health JSON missing healthSchemaVersion field' }
if (-not $doc.sections.developer) { throw 'health JSON missing sections.developer' }
if (-not $doc.sections.privacyConfiguration) { throw 'health JSON missing privacyConfiguration' }
if ($doc.summary.message -notmatch 'Ready to work|Not ready yet') {
    throw "health JSON unexpected summary: $($doc.summary.message)"
}

Write-Host "  [PASS] health -Json (ready=$($doc.summary.ready), schema=$($doc.healthSchemaVersion))" -ForegroundColor Green
Write-Host ''
Write-Host 'Health smoke — ALL PASS' -ForegroundColor Green
exit 0
