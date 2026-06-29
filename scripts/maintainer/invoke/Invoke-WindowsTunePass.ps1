#Requires -Version 7.0
<#
.SYNOPSIS
    Windows tune pass — privacy, performance, network, organization, validate.
#>
param(
    [switch]$SkipPrivacy,
    [switch]$SkipPerformance,
    [switch]$SkipNetwork,
    [switch]$SkipOrganize,
    [ValidateSet('Quad9', 'Cloudflare', 'Mullvad', 'None')]
    [string]$DnsProvider = 'Quad9'
)

. (Join-Path $PSScriptRoot '..\_Resolve-RepoRoot.ps1')
$repoRoot = Resolve-WorkstationRepoRoot -Start $PSScriptRoot

$ErrorActionPreference = 'Continue'
$root = $repoRoot
. (Join-Path $root 'lib\WorkstationCommon.ps1')
Write-Host "`n  HOME BASE — WINDOWS TUNE PASS`n" -ForegroundColor Cyan

$adminScripts = @()
if (-not $SkipPrivacy)     { $adminScripts += @{ Name = 'Privacy';     Script = 'Configure-Privacy.ps1';     Args = @('-Force', '-DnsProvider', $DnsProvider) } }
if (-not $SkipPerformance) { $adminScripts += @{ Name = 'Performance'; Script = 'Optimize-Performance.ps1'; Args = @('-Force') } }
if (-not $SkipNetwork)     { $adminScripts += @{ Name = 'Network';     Script = 'Configure-Network.ps1';     Args = @('-Force') } }

foreach ($s in $adminScripts) {
    Write-Host "  [..] $($s.Name) (UAC)..." -ForegroundColor Yellow
    $path = Join-Path $root $s.Script
    $argList = @('-NoProfile', '-File', $path) + $s.Args
    $p = Start-Process pwsh -Verb RunAs -ArgumentList $argList -Wait -PassThru
    if ($p.ExitCode -ne 0) { Write-Host "  [warn] $($s.Name) exit $($p.ExitCode)" -ForegroundColor Yellow }
    else { Write-Host "  [OK] $($s.Name)" -ForegroundColor Green }
}

Write-WorkstationStep 'Organization audit'
& (Join-Path $root 'Invoke-OrganizationAudit.ps1')

if (-not $SkipOrganize) {
    Write-WorkstationStep 'Workstation organization'
    & (Join-Path $root 'Invoke-WorkstationOrganization.ps1') -Force
}

Write-WorkstationStep 'Housekeeping'
& (Join-Path $root 'Invoke-Housekeeping.ps1') -IncludeTemp

Write-WorkstationStep 'Validation'
& (Join-Path $root 'Validate-Workstation.ps1')
$valOk = ($LASTEXITCODE -eq 0)

Import-Module (Join-Path $root 'modules\KGreen.Workstation.psm1') -Force -ErrorAction SilentlyContinue
if (Get-Command windowsstatus -ErrorAction SilentlyContinue) { windowsstatus }

Write-Host "`n  Windows tune pass $(if ($valOk) { 'PASS' } else { 'DONE (check warnings)' }). Restart WT recommended.`n" -ForegroundColor $(if ($valOk) { 'Green' } else { 'Yellow' })
exit $(if ($valOk) { 0 } else { 1 })
