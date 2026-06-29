#Requires -Version 7.0
[CmdletBinding()]
param([switch]$Json])

$ErrorActionPreference = 'Continue'
. (Join-Path $PSScriptRoot '..\_Resolve-RepoRoot.ps1')
$repoRoot = Resolve-WorkstationRepoRoot -Start $PSScriptRoot
. (Join-Path $repoRoot 'lib\WorkstationCommon.ps1')
. (Join-Path $repoRoot 'lib\PrivacyAudit.ps1')
. (Join-Path $PSScriptRoot '_PrivacyInvokeCommon.ps1')

$product = Get-DevShellProductVersionFromRoot -RepoRoot $repoRoot
$report = Get-PrivacyAuditReport -Scope Vpn -RepoRoot $repoRoot -ProductVersion $product
Write-PrivacyInvokeResult -Report $report -RepoRoot $repoRoot -Json:$Json
exit 0
