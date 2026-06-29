#Requires -Version 7.0
<#
.SYNOPSIS
    Unified workstation health — dashboard, JSON, baseline, verify, history.
#>
[CmdletBinding()]
param(
    [ValidateSet('Core', 'Full')]
    [string]$Tier = 'Core',
    [switch]$Json,
    [ValidateSet('html')]
    [string]$Export,
    [string[]]$SectionFilter,
    [string]$OutFile,
    [switch]$SkipHistory
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '..\_Resolve-RepoRoot.ps1')
$repoRoot = Resolve-WorkstationRepoRoot -Start $PSScriptRoot
. (Join-Path $repoRoot 'lib\WorkstationCommon.ps1')
. (Join-Path $repoRoot 'lib\DevShellHealth.ps1')
. (Join-Path $PSScriptRoot '_PrivacyInvokeCommon.ps1')

$product = Get-DevShellProductVersionFromRoot -RepoRoot $repoRoot
$report = Get-DevShellHealthReport -RepoRoot $repoRoot -Tier $Tier -ProductVersion $product -SectionFilter $SectionFilter

if (-not $SkipHistory) {
    $historyPath = (Get-DevShellHealthPaths -RepoRoot $repoRoot).History
    Save-DevShellHealthHistory -Report $report -HistoryPath $historyPath
}

if ($Json) {
    $report | ConvertTo-Json -Depth 12
} else {
    Write-DevShellHealthDashboard -Report $report
}

if ($Export -eq 'html') {
    $out = if ($OutFile) {
        $OutFile
    } else {
        $logs = Get-DevShellHealthLogsRoot -RepoRoot $repoRoot
        Join-Path $logs ("health-{0}.html" -f (Get-Date -Format 'yyyyMMdd-HHmmss'))
    }
    Export-DevShellHealthHtml -Report $report -OutPath $out
}

$exitCode = if ($report.summary.ready) { 0 } else { 1 }
$global:LASTEXITCODE = $exitCode
exit $exitCode
