#Requires -Version 7.0
<#
.SYNOPSIS
    DevReady privacy audit — system settings score (read-only unless -Fix).
#>
[CmdletBinding()]
param(
    [switch]$Fix,
    [switch]$Apply,
    [switch]$Json,
    [ValidateSet('Quad9', 'Cloudflare', 'Mullvad', 'None')]
    [string]$DnsProvider = 'Quad9'
)

$ErrorActionPreference = 'Continue'
. (Join-Path $PSScriptRoot '..\_Resolve-RepoRoot.ps1')
$repoRoot = Resolve-WorkstationRepoRoot -Start $PSScriptRoot
. (Join-Path $repoRoot 'lib\WorkstationCommon.ps1')
. (Join-Path $repoRoot 'lib\PrivacyAudit.ps1')
. (Join-Path $PSScriptRoot '_PrivacyInvokeCommon.ps1')

$product = Get-DevShellProductVersionFromRoot -RepoRoot $repoRoot

if ($Fix) {
    $repairArgs = @{ Force = $true; RepoRoot = $repoRoot; DnsProvider = $DnsProvider }
    if ($Apply) { $repairArgs['ApplyProfile'] = $true }
    & (Join-Path $repoRoot 'scripts\maintainer\configure\Repair-PrivacySettings.ps1') @repairArgs
    Write-Host ''
    Write-Host 'Re-checking after privacy repair...' -ForegroundColor Cyan
}

$report = Get-PrivacyAuditReport -Scope System -RepoRoot $repoRoot -ProductVersion $product
Write-PrivacyInvokeResult -Report $report -RepoRoot $repoRoot -Json:$Json

$exitCode = if ($report.WarnCount -eq 0 -and $report.FailCount -eq 0) { 0 } else { 1 }
$global:LASTEXITCODE = $exitCode
exit $exitCode
