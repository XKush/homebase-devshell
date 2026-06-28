#Requires -Version 7.0
<#
.SYNOPSIS
    Optimize profile for startup performance — benchmark before/after.
#>
param([switch]$Apply)

$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\lib\WorkstationCommon.ps1"

$profilePath = 'C:\Scripts\Workstation\profile\Microsoft.PowerShell_profile.ps1'
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

Write-WorkstationStep 'Benchmark current profile'
$before = Measure-ProfileLoad -Path $livePath
Write-WorkstationLog "Before: ${before}ms"

if (-not $Apply) {
    Write-Host "Current load: ${before}ms. Run with -Apply to deploy optimized profile."
    return
}

Write-WorkstationStep 'Deploying optimized profile (already in canonical file after edit)'
Copy-Item $profilePath $livePath -Force
& "$PSScriptRoot\Install-ShellProfile.ps1" -Force | Out-Null

$after = Measure-ProfileLoad -Path $livePath
Write-WorkstationLog "After: ${after}ms" 'OK'
Write-Host "Improvement: $before ms -> $after ms ($([math]::Round(100 - ($after/$before*100), 1))% faster)"

@{
    BeforeMs = $before
    AfterMs  = $after
    Timestamp = (Get-Date).ToString('o')
} | ConvertTo-Json | Set-Content 'C:\Logs\Workstation\profile-benchmark.json' -Encoding UTF8
