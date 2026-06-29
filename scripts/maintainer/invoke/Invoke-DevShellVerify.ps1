#Requires -Version 7.0
<#
.SYNOPSIS
    Compare current health to saved baseline.
#>
[CmdletBinding()]
param([switch]$Json)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '..\_Resolve-RepoRoot.ps1')
$repoRoot = Resolve-WorkstationRepoRoot -Start $PSScriptRoot
. (Join-Path $repoRoot 'lib\WorkstationCommon.ps1')
. (Join-Path $repoRoot 'lib\DevShellHealth.ps1')
. (Join-Path $PSScriptRoot '_PrivacyInvokeCommon.ps1')

$product = Get-DevShellProductVersionFromRoot -RepoRoot $repoRoot
$current = Get-DevShellHealthReport -RepoRoot $repoRoot -Tier Core -ProductVersion $product
$diff = Compare-DevShellHealthBaseline -Current $current

if ($Json) {
    if ($diff.noBaseline) {
        @{ error = 'no_baseline'; message = 'Run: devshell baseline' } | ConvertTo-Json
        exit 1
    }
    if ($diff.baselineInvalid) {
        @{ error = 'baseline_invalid'; message = 'Baseline file is unreadable or corrupt'; changes = @($diff.changes) } | ConvertTo-Json
        exit 1
    }
    $diff | ConvertTo-Json -Depth 5
    exit $(if ($diff.driftDetected) { 1 } else { 0 })
}

Write-Host ''
Write-Host 'Baseline verify' -ForegroundColor Cyan
if ($diff.noBaseline) { exit 1 }
Write-Host "  Baseline: $($diff.baselineTimestamp)" -ForegroundColor DarkGray
Write-Host "  Current:  $($diff.currentTimestamp)" -ForegroundColor DarkGray
Write-Host ''
if (-not $diff.driftDetected) {
    Write-Host '  No drift detected.' -ForegroundColor Green
} else {
    Write-Host '  Changes:' -ForegroundColor Yellow
    $diff.changes | ForEach-Object { Write-Host "    $_" -ForegroundColor DarkGray }
}
Write-Host ''
exit $(if ($diff.driftDetected) { 1 } else { 0 })
