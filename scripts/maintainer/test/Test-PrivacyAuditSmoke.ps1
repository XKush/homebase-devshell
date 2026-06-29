#Requires -Version 7.0
<#
.SYNOPSIS
    CI smoke — privacy audits offline, stable JSON schema, non-admin safe.
#>
[CmdletBinding()]
param([string]$Root)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '..\_Resolve-RepoRoot.ps1')
if (-not $Root) { $Root = Resolve-WorkstationRepoRoot -Start $PSScriptRoot }
$env:HOMEBASE_DEVSHELL_ROOT = $Root
$env:WORKSTATION_ROOT = $Root

. (Join-Path $Root 'lib\WorkstationCommon.ps1')
. (Join-Path $Root 'lib\PrivacyAudit.ps1')

function Assert-PrivacyJsonSchema {
    param([string]$JsonText, [string]$Label)
    $doc = $JsonText | ConvertFrom-Json
    foreach ($key in @('reportSchemaVersion', 'scope', 'score', 'summary', 'checks')) {
        if (-not ($doc.PSObject.Properties.Name -contains $key)) {
            throw "$Label missing JSON field: $key"
        }
    }
    if ([string]$doc.reportSchemaVersion -ne '1.0.0') {
        throw "$Label reportSchemaVersion must be 1.0.0"
    }
    if ($null -eq $doc.score.value) { throw "$Label score.value missing" }
    if (-not ($doc.checks -is [Array]) -or $doc.checks.Count -lt 1) {
        throw "$Label checks array empty"
    }
    $first = $doc.checks[0]
    foreach ($ck in @('id', 'label', 'status', 'weight', 'deduction')) {
        if (-not ($first.PSObject.Properties.Name -contains $ck)) {
            throw "$Label check missing field: $ck"
        }
    }
}

$product = '0.0.0'
$psd1 = Join-Path $Root 'modules\KGreen.Workstation.psd1'
if (Test-Path $psd1) { $product = [string](Import-PowerShellDataFile $psd1).ModuleVersion }

Write-Host 'Privacy smoke — offline audits' -ForegroundColor Cyan

foreach ($scope in @('System', 'Browser', 'Tor', 'Vpn')) {
    $report = Get-PrivacyAuditReport -Scope $scope -RepoRoot $Root -ProductVersion $product
    $doc = ConvertTo-PrivacyReportDocument -Report $report -ProductVersion $product -Context $report.Context
    $json = $doc | ConvertTo-Json -Depth 8
    Assert-PrivacyJsonSchema -JsonText $json -Label $scope
    Write-Host "  [PASS] $scope audit ($($report.Checks.Count) checks, score $($report.Score))" -ForegroundColor Green
}

$doctorOut = pwsh -NoProfile -File (Join-Path $Root 'devshell.ps1') doctor -Privacy 2>&1 | Out-String
if ($doctorOut -notmatch 'Privacy configuration') { throw 'doctor -Privacy missing configuration header' }
if ($doctorOut -notmatch 'Does not measure network anonymity') { throw 'doctor -Privacy missing disclaimer' }
if ($doctorOut -notmatch '\d+/100') { throw 'doctor -Privacy missing score' }
Write-Host '  [PASS] devshell doctor -Privacy' -ForegroundColor Green

Write-Host ''
Write-Host 'Privacy smoke — ALL PASS' -ForegroundColor Green
exit 0
