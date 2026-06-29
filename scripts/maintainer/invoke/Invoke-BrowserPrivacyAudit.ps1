#Requires -Version 7.0
[CmdletBinding()]
param(
    [ValidateSet('Chrome', 'Edge', 'Firefox', 'All')]
    [string]$Browser = 'All',
    [switch]$Json
)

$ErrorActionPreference = 'Continue'
. (Join-Path $PSScriptRoot '..\_Resolve-RepoRoot.ps1')
$repoRoot = Resolve-WorkstationRepoRoot -Start $PSScriptRoot
. (Join-Path $repoRoot 'lib\WorkstationCommon.ps1')
. (Join-Path $repoRoot 'lib\PrivacyAudit.ps1')
. (Join-Path $PSScriptRoot '_PrivacyInvokeCommon.ps1')

$product = Get-DevShellProductVersionFromRoot -RepoRoot $repoRoot
$report = Get-PrivacyAuditReport -Scope Browser -RepoRoot $repoRoot -Browser $Browser -ProductVersion $product
Write-PrivacyInvokeResult -Report $report -RepoRoot $repoRoot -Json:$Json
exit $(if ($report.WarnCount -eq 0 -and $report.FailCount -eq 0) { 0 } else { 1 })
