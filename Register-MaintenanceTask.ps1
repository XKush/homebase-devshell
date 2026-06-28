#Requires -Version 7.0
#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Register weekly maintenance scheduled task for KGreen workstation.
#>
$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\lib\WorkstationCommon.ps1"
Assert-WorkstationAdmin

$taskName = 'ReviOS-Workstation-Maintenance'
$action = New-ScheduledTaskAction -Execute 'pwsh.exe' -Argument '-NoProfile -WindowStyle Hidden -File C:\Scripts\Workstation\Invoke-Maintenance.ps1 -Full'
$trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Sunday -At 3am
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable
Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Settings $settings -Force -Description 'Weekly workstation health, log rotation, and config backup' | Out-Null
Write-WorkstationLog "Scheduled task registered: $taskName (Sundays 03:00)" 'OK'
