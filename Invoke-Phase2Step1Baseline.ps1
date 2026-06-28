#Requires -Version 7.0
<#
.SYNOPSIS
    Phase 2 Step 1 — capture stable baseline after reloadprofile + gates.
#>
$ErrorActionPreference = 'Stop'
$wsRoot = $PSScriptRoot

Import-Module (Join-Path $wsRoot 'modules\KGreen.Workstation.psm1') -DisableNameChecking -Scope Global -Force

Write-Host '=== reloadprofile ===' -ForegroundColor Cyan
reloadprofile

Write-Host '=== doctor ===' -ForegroundColor Cyan
doctor | Out-Null

Write-Host '=== trustcheck ===' -ForegroundColor Cyan
& (Join-Path $wsRoot 'Test-WorkstationCommands.ps1') -Quick | Out-Null
Get-SystemTrustReport -Live -Save | Out-Null
trustcheck

Write-Host '=== Test-HomeBasePaths ===' -ForegroundColor Cyan
& (Join-Path $wsRoot 'Test-HomeBasePaths.ps1')
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host '=== Save-Phase2Baseline (Phase2-Step1-Stable) ===' -ForegroundColor Cyan
& (Join-Path $wsRoot 'Save-Phase2Baseline.ps1') -StableLabel 'Phase2-Step1-Stable'
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host '=== Test-LegacyEquivalence ===' -ForegroundColor Cyan
& (Join-Path $wsRoot 'Test-LegacyEquivalence.ps1')
exit $LASTEXITCODE
