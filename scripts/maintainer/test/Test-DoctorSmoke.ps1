#Requires -Version 7.0
<#
.SYNOPSIS
    CI smoke — devshell doctor Core produces validation JSON.
#>
[CmdletBinding()]
param([string]$Root)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '..\_Resolve-RepoRoot.ps1')
if (-not $Root) { $Root = Resolve-WorkstationRepoRoot -Start $PSScriptRoot }
$env:HOMEBASE_DEVSHELL_ROOT = $Root
$env:WORKSTATION_ROOT = $Root

. (Join-Path $Root 'lib\HomeBasePaths.ps1')
. (Join-Path $Root 'lib\WorkstationCommon.ps1')
$logs = Get-WorkstationLogsRoot

$null = pwsh -NoProfile -File (Join-Path $Root 'devshell.ps1') doctor -Tier Core -Json 2>$null
$latest = Get-ChildItem $logs -Filter 'validation-*.json' -ErrorAction SilentlyContinue |
    Sort-Object LastWriteTime -Descending | Select-Object -First 1
if (-not $latest) { throw 'doctor -Json did not produce validation-*.json' }

$doc = Get-Content $latest.FullName -Raw | ConvertFrom-Json
if (-not $doc.Passed) { throw 'validation JSON missing Passed array' }
if (-not ($doc.PSObject.Properties.Name -contains 'Failed')) { throw 'validation JSON missing Failed' }

Write-Host "  [PASS] doctor Core ($($doc.Passed.Count) passed, $($doc.Failed.Count) failed)" -ForegroundColor Green
exit 0
