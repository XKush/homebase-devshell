#Requires -Version 7.0
[CmdletBinding()]
param([switch]$Json)

$ErrorActionPreference = 'Continue'
. (Join-Path $PSScriptRoot '..\_Resolve-RepoRoot.ps1')
$repoRoot = Resolve-WorkstationRepoRoot -Start $PSScriptRoot
. (Join-Path $repoRoot 'lib\WorkstationCommon.ps1')
. (Join-Path $repoRoot 'lib\PrivacyAudit.ps1')
. (Join-Path $PSScriptRoot '_PrivacyInvokeCommon.ps1')

$product = Get-DevShellProductVersionFromRoot -RepoRoot $repoRoot
$report = Get-PrivacyAuditReport -Scope Opsec -RepoRoot $repoRoot -ProductVersion $product
Write-PrivacyInvokeResult -Report $report -RepoRoot $repoRoot -Json:$Json
Write-Host 'OPSEC note: no tool guarantees anonymity — review WARN items manually.' -ForegroundColor DarkGray
Write-Host ''
exit $(if ($report.Score -ge 65) { 0 } else { 1 })
