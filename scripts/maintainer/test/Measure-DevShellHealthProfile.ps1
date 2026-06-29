#Requires -Version 7.0
<#
.SYNOPSIS
    Measure devshell doctor vs health JSON timing (maintainer profiling).
#>
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '..\_Resolve-RepoRoot.ps1')
$Root = Resolve-WorkstationRepoRoot -Start $PSScriptRoot
$env:HOMEBASE_DEVSHELL_ROOT = $Root

Write-Host 'DevShell health profiling' -ForegroundColor Cyan
Write-Host "  Root: $Root" -ForegroundColor DarkGray
Write-Host ''

$doctor = Measure-Command {
    pwsh -NoProfile -File (Join-Path $Root 'devshell.ps1') doctor -Json *> $null
}
$health = Measure-Command {
    pwsh -NoProfile -File (Join-Path $Root 'devshell.ps1') health -Json *> $null
}
$healthDev = Measure-Command {
    pwsh -NoProfile -File (Join-Path $Root 'devshell.ps1') health -Json -Sections developer *> $null
}

Write-Host ("  doctor -Json:              {0:N2}s" -f $doctor.TotalSeconds)
Write-Host ("  health -Json (full):       {0:N2}s" -f $health.TotalSeconds)
Write-Host ("  health -Json -Sections dev:{0:N2}s" -f $healthDev.TotalSeconds)
Write-Host ''
Write-Host 'Registry/CIM: run privacy with -Verbose and count Get-ItemProperty lines in log.' -ForegroundColor DarkGray
