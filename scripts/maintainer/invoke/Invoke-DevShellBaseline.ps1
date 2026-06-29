#Requires -Version 7.0
<#
.SYNOPSIS
    Save current health snapshot as baseline for verify.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '..\_Resolve-RepoRoot.ps1')
$repoRoot = Resolve-WorkstationRepoRoot -Start $PSScriptRoot
. (Join-Path $repoRoot 'lib\WorkstationCommon.ps1')
. (Join-Path $repoRoot 'lib\DevShellHealth.ps1')
. (Join-Path $PSScriptRoot '_PrivacyInvokeCommon.ps1')

$product = Get-DevShellProductVersionFromRoot -RepoRoot $repoRoot
$report = Get-DevShellHealthReport -RepoRoot $repoRoot -Tier Core -ProductVersion $product
Save-DevShellHealthBaseline -Report $report
Write-Host 'Run devshell verify after system changes.' -ForegroundColor DarkGray
exit 0
