#Requires -Version 7.0
<#
.SYNOPSIS
    Profile startup diagnostics — benchmark and optimization suggestions (read-only).
.NOTES
    Wave A Commit 5: recommendations only. Does not deploy or mutate profile state.
#>
param(
    [switch]$Apply
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '..\_Resolve-RepoRoot.ps1')
$repoRoot = Resolve-WorkstationRepoRoot -Start $PSScriptRoot
$script:WSRoot = $repoRoot
. (Join-Path $repoRoot 'lib\HomeBasePaths.ps1')
. (Join-Path $repoRoot 'lib\WorkstationCommon.ps1')

$profilePath = Join-Path (Get-HomeBasePath -Name RepositoryRoot) 'profile\Microsoft.PowerShell_profile.ps1'
$livePath    = Join-Path $HOME 'Documents\PowerShell\Microsoft.PowerShell_profile.ps1'

function Measure-ProfileLoad {
    param([string]$Path)
    $sw = [Diagnostics.Stopwatch]::StartNew()
    pwsh -NoProfile -Command @"
`$env:WORKSTATION_BANNER_SHOWN='1'
`$env:CI='1'
. '$Path'
"@ | Out-Null
    $sw.Stop()
    return $sw.ElapsedMilliseconds
}

function Get-ProfileOptimizationRecommendations {
    param([int]$LoadMs)

    $rec = [System.Collections.Generic.List[string]]::new()
    if ($LoadMs -gt 600) {
        $rec.Add('Profile load exceeds 600ms budget — review deferred imports in profile bootstrap')
    } elseif ($LoadMs -gt 300) {
        $rec.Add('Profile load above 300ms target — consider WORKSTATION_STARTUP_MODE=minimal')
    } else {
        $rec.Add('Profile load within target — no startup optimization required')
    }

    if (-not (Test-Path $livePath)) {
        $rec.Add('Live PS7 profile missing — run Install-ShellProfile.ps1 or fixprofile')
    } elseif ((Test-Path $profilePath) -and ((Get-FileHash $profilePath).Hash -ne (Get-FileHash $livePath).Hash)) {
        $rec.Add('Canonical profile differs from live profile — run fixprofile to sync')
    }

    if (-not (Get-Command oh-my-posh -ErrorAction SilentlyContinue)) {
        $rec.Add('Oh My Posh not installed — prompt theme unavailable')
    }

    return @($rec)
}

if ($Apply) {
    Write-Warning 'Optimize-Profile -Apply is disabled in diagnostics layer. Review suggestions below and apply fixes manually.'
}

Write-WorkstationStep 'Benchmark current profile'
$loadMs = Measure-ProfileLoad -Path $livePath
Write-WorkstationLog "Profile load: ${loadMs}ms"

$recommendations = Get-ProfileOptimizationRecommendations -LoadMs $loadMs

Write-Host ''
Write-Host 'Profile optimization suggestions:' -ForegroundColor Cyan
foreach ($r in $recommendations) {
    Write-Host "  → $r" -ForegroundColor Yellow
}
Write-Host ''

[ordered]@{
    LoadMs            = $loadMs
    Recommendations   = @($recommendations)
    Timestamp         = (Get-Date).ToString('o')
    ApplySupported    = $false
}
