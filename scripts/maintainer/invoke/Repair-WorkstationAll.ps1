#Requires -Version 7.0
<#
.SYNOPSIS
    Post-production repair orchestrator — fonts, profiles, terminal, PATH.
#>
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '..\_Resolve-RepoRoot.ps1')
$repoRoot = Resolve-WorkstationRepoRoot -Start $PSScriptRoot
. (Join-Path $repoRoot 'lib\WorkstationCommon.ps1')

Write-WorkstationStep 'Post-production repair'
& (Resolve-WorkstationScript -Name 'Repair-WorkstationFonts.ps1' -Start $PSScriptRoot) -Force
& (Resolve-WorkstationScript -Name 'Install-ShellProfile.ps1' -Start $PSScriptRoot) -Force
& (Resolve-WorkstationScript -Name 'Fix-WorkstationPath.ps1' -Start $PSScriptRoot)
Copy-Item (Join-Path $repoRoot 'profile\Microsoft.PowerShell_profile.ps1') "$HOME\Documents\PowerShell\Microsoft.PowerShell_profile.ps1" -Force
Write-WorkstationLog 'Full repair complete' 'OK'
