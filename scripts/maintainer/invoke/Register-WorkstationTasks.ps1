#Requires -Version 7.0
<#
.SYNOPSIS
    Register scheduled tasks: daily trust probe + weekly maintenance.
#>
param([switch]$Force)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '..\_Resolve-RepoRoot.ps1')
$root = Resolve-WorkstationRepoRoot -Start $PSScriptRoot

$tasks = @(
    @{
        Name = 'KGreen-TrustProbe-Daily'
        Description = 'Daily HOME BASE trust probe + command health'
        Script = Resolve-WorkstationScript -Name 'Invoke-ScheduledTrustProbe.ps1' -Start $PSScriptRoot
        Schedule = @{ Daily = $true; At = '08:00' }
    }
    @{
        Name = 'KGreen-Maintenance-Weekly'
        Description = 'Weekly workstation maintenance + WOC cache'
        Script = Resolve-WorkstationScript -Name 'Invoke-Maintenance.ps1' -Start $PSScriptRoot
        Args = '-Full'
        Schedule = @{ Weekly = $true; DaysOfWeek = 'Sunday'; At = '09:00' }
    }
)

foreach ($t in $tasks) {
    $existing = Get-ScheduledTask -TaskName $t.Name -ErrorAction SilentlyContinue
    if ($existing -and -not $Force) {
        Write-Host "  [skip] $($t.Name) already registered" -ForegroundColor DarkGray
        continue
    }
    if ($existing) { Unregister-ScheduledTask -TaskName $t.Name -Confirm:$false }

    $actionArgs = if ($t.Args) { "-NoProfile -WindowStyle Hidden -File `"$($t.Script)`" $($t.Args)" } else { "-NoProfile -WindowStyle Hidden -File `"$($t.Script)`"" }
    $action = New-ScheduledTaskAction -Execute 'pwsh.exe' -Argument $actionArgs
    $trigger = if ($t.Schedule.Weekly) {
        New-ScheduledTaskTrigger -Weekly -DaysOfWeek $t.Schedule.DaysOfWeek -At $t.Schedule.At
    } else {
        New-ScheduledTaskTrigger -Daily -At $t.Schedule.At
    }
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable
    Register-ScheduledTask -TaskName $t.Name -Description $t.Description -Action $action -Trigger $trigger -Settings $settings -RunLevel Limited | Out-Null
    Write-Host "  [OK] $($t.Name)" -ForegroundColor Green
}

Write-Host "`n  Scheduled tasks registered." -ForegroundColor Cyan
