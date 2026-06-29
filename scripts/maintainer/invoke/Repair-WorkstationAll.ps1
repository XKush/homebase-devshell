#Requires -Version 7.0
<#
.SYNOPSIS
    Post-production repair orchestrator — fonts, profiles, terminal, PATH.
#>
$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\lib\WorkstationCommon.ps1"

Write-WorkstationStep 'Post-production repair'
& "$PSScriptRoot\Repair-WorkstationFonts.ps1" -Force
& "$PSScriptRoot\Install-ShellProfile.ps1" -Force
& "$PSScriptRoot\Fix-WorkstationPath.ps1"
Copy-Item "$PSScriptRoot\profile\Microsoft.PowerShell_profile.ps1" "$HOME\Documents\PowerShell\Microsoft.PowerShell_profile.ps1" -Force
Write-WorkstationLog 'Full repair complete' 'OK'
