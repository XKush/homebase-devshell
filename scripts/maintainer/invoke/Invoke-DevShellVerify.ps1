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
exit (Write-DevShellVerifyOutput -Diff $diff -Json:$Json)
