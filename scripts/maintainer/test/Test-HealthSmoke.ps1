#Requires -Version 7.0
<#
.SYNOPSIS
    CI smoke for devshell health — validates JSON contract on any runner state.
#>
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '..\_Resolve-RepoRoot.ps1')
$Root = Resolve-WorkstationRepoRoot -Start $PSScriptRoot

Write-Host 'Health smoke' -ForegroundColor Cyan

$out = pwsh -NoProfile -File (Join-Path $Root 'devshell.ps1') health -Json 2>&1 | Out-String
if ($out -notmatch 'healthSchemaVersion') { throw 'health -Json missing healthSchemaVersion' }

try {
    $doc = $out.Trim() | ConvertFrom-Json
} catch {
    throw "health -Json invalid JSON: $_"
}

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
