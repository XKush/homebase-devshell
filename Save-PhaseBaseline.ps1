#Requires -Version 7.0
<#
.SYNOPSIS
    Capture pre/post wave baseline for Phase 2 architectural layers.
.PARAMETER Wave
    Layer name (Profile for Wave A).
.PARAMETER Moment
    Pre (before first migration commit) or Post (after wave exit).
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateSet('Profile')]
    [string]$Wave,

    [ValidateSet('Pre', 'Post')]
    [string]$Moment = 'Pre',

    [switch]$SkipBackup
)

$ErrorActionPreference = 'Stop'
$wsRoot = $PSScriptRoot

function Invoke-Step {
    param([string]$Name, [scriptblock]$Action)
    Write-Host "=== $Name ===" -ForegroundColor Cyan
    & $Action
    if ($LASTEXITCODE -and $LASTEXITCODE -ne 0) {
        throw "Step failed: $Name (exit $LASTEXITCODE)"
    }
}

$label = switch ($Wave) {
    'Profile' { "Phase2-Wave-A-$Moment" }
}

$snapshotLabel = switch ($Moment) {
    'Pre'  { 'pre' }
    'Post' { 'post' }
}

Import-Module (Join-Path $wsRoot 'modules\KGreen.Workstation.psm1') -DisableNameChecking -Scope Global -Force

if (-not $SkipBackup) {
    Invoke-Step 'backupconfig' { backupconfig }
}

Invoke-Step 'Save-Phase2Baseline' {
    & (Join-Path $wsRoot 'Save-Phase2Baseline.ps1') -StableLabel $label
}

Invoke-Step 'Get-Phase2LegacyPathReport' {
    & (Join-Path $wsRoot 'Get-Phase2LegacyPathReport.ps1') -SaveJson | Out-Null
}

Invoke-Step 'doctor' { doctor | Out-Null }

Invoke-Step 'trustcheck' {
    Get-SystemTrustReport -Live -Save | Out-Null
    trustcheck | Out-Null
    . (Join-Path $wsRoot 'lib\HomeBasePaths.ps1')
    $trustPath = Join-Path (Get-HomeBasePath -Name Logs) 'trust-report.json'
    $t = Get-Content $trustPath -Raw | ConvertFrom-Json
    if ($t.Level -ne 'VERIFIED' -or $t.Score -ne 100) {
        throw "Trust not VERIFIED 100: $($t.Level) $($t.Score)"
    }
}

Invoke-Step 'Test-LegacyEquivalence' {
    & (Join-Path $wsRoot 'Test-LegacyEquivalence.ps1')
}

Invoke-Step 'Save-ProfileSnapshot' {
    & (Join-Path $wsRoot 'Save-ProfileSnapshot.ps1') -Label $snapshotLabel -Wave $Wave | Out-Null
}

Write-Host ''
Write-Host "Wave baseline complete: $Wave / $Moment ($label)" -ForegroundColor Green
exit 0
