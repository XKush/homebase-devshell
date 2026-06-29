#Requires -Version 7.0
#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Register weekly maintenance scheduled task for KGreen workstation.
#>
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '..\_Resolve-RepoRoot.ps1')
$repoRoot = Resolve-WorkstationRepoRoot -Start $PSScriptRoot
. (Join-Path $repoRoot 'lib\WorkstationCommon.ps1')
Assert-WorkstationAdmin

$taskName = 'ReviOS-Workstation-Maintenance'
$maintenance = Resolve-WorkstationScript -Name 'Invoke-Maintenance.ps1' -Start $PSScriptRoot
$action = New-ScheduledTaskAction -Execute 'pwsh.exe' -Argument "-NoProfile -WindowStyle Hidden -File `"$maintenance`" -Full"
$trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Sunday -At 3am
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable
Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Settings $settings -Force -Description 'Weekly workstation health, log rotation, and config backup' | Out-Null
Write-WorkstationLog "Scheduled task registered: $taskName (Sundays 03:00)" 'OK'
