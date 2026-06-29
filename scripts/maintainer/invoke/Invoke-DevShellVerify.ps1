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

function Write-DevShellVerifyResult {
    param(
        [Parameter(Mandatory)]$Diff,
        [switch]$Json
    )
    if ($Json) {
        if ($Diff.noBaseline) {
            @{ error = 'no_baseline'; message = 'Run: devshell baseline' } | ConvertTo-Json
            return 1
        }
        if ($Diff.baselineInvalid) {
            @{
                error   = 'baseline_invalid'
                message = 'Baseline file is unreadable or corrupt'
                changes = @($Diff.changes)
            } | ConvertTo-Json
            return 1
        }
        $Diff | ConvertTo-Json -Depth 5
        return $(if ($Diff.driftDetected) { 1 } else { 0 })
    }

    Write-Host ''
    Write-Host 'Baseline verify' -ForegroundColor Cyan
    if ($Diff.noBaseline -or $Diff.baselineInvalid) {
        if ($Diff.baselineInvalid -and $Diff.changes) {
            Write-Host "  $($Diff.changes[0])" -ForegroundColor Yellow
        }
        return 1
    }
    Write-Host "  Baseline: $($Diff.baselineTimestamp)" -ForegroundColor DarkGray
    Write-Host "  Current:  $($Diff.currentTimestamp)" -ForegroundColor DarkGray
    Write-Host ''
    if (-not $Diff.driftDetected) {
        Write-Host '  No drift detected.' -ForegroundColor Green
    } else {
        Write-Host '  Changes:' -ForegroundColor Yellow
        $Diff.changes | ForEach-Object { Write-Host "    $_" -ForegroundColor DarkGray }
    }
    Write-Host ''
    return $(if ($Diff.driftDetected) { 1 } else { 0 })
}

$product = Get-DevShellProductVersionFromRoot -RepoRoot $repoRoot
$current = Get-DevShellHealthReport -RepoRoot $repoRoot -Tier Core -ProductVersion $product
$diff = Compare-DevShellHealthBaseline -Current $current
exit (Write-DevShellVerifyResult -Diff $diff -Json:$Json)
