#Requires -Version 7.0
#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Performance tuning for ReviOS workstation.
.NOTES
    Safe, reversible changes only. Does not disable critical services.
#>
param(
    [switch]$Force,
    [switch]$WhatIf
)

$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\lib\WorkstationCommon.ps1"
Assert-WorkstationAdmin
Assert-DefenderUntouched

if (-not (Confirm-WorkstationAction -Message 'Apply performance optimizations?' -Force:$Force)) { return }

Write-WorkstationStep 'Creating system restore point'
try {
    Checkpoint-Computer -Description 'ReviOS Workstation Performance' -RestorePointType MODIFY_SETTINGS -ErrorAction Stop
    Write-WorkstationLog 'Restore point created' 'OK'
} catch {
    Write-WorkstationLog 'Restore point skipped (enable System Protection on C: if needed)' 'WARN'
}

Write-WorkstationStep 'Visual effects — best performance for foreground apps'
$visualPath = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects'
Backup-RegistryKey 'HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects' 'VisualEffects'
Set-RegistryValueSafe -Path $visualPath -Name 'VisualFXSetting' -Value 2  # Custom
Set-RegistryValueSafe -Path 'HKCU:\Control Panel\Desktop' -Name 'UserPreferencesMask' -Value ([byte[]](0x90,0x12,0x03,0x80,0x10,0x00,0x00,0x00)) -Type Binary
Set-RegistryValueSafe -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'TaskbarAnimations' -Value 0
Set-RegistryValueSafe -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'ListviewAlphaSelect' -Value 0
Set-RegistryValueSafe -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'ListviewShadow' -Value 0

Write-WorkstationStep 'Disabling common telemetry scheduled tasks (if present)'
$telemetryTasks = @(
    '\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser'
    '\Microsoft\Windows\Application Experience\ProgramDataUpdater'
    '\Microsoft\Windows\Autochk\Proxy'
    '\Microsoft\Windows\Customer Experience Improvement Program\Consolidator'
    '\Microsoft\Windows\Customer Experience Improvement Program\UsbCeip'
    '\Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticDataCollector'
    '\Microsoft\Windows\Feedback\Siuf\DmClient'
    '\Microsoft\Windows\Feedback\Siuf\DmClientOnScenarioDownload'
    '\Microsoft\Windows\Maps\MapsUpdateTask'
    '\Microsoft\Windows\Shell\FamilySafetyMonitor'
    '\Microsoft\Windows\Shell\FamilySafetyRefreshTask'
)
foreach ($task in $telemetryTasks) {
    try {
        $taskPath = Split-Path $task -Parent
        $taskName = Split-Path $task -Leaf
        if ([string]::IsNullOrEmpty($taskPath)) { $taskPath = '\' }
        Disable-ScheduledTask -TaskPath $taskPath -TaskName $taskName -ErrorAction Stop | Out-Null
        Write-WorkstationLog "Disabled task: $task" 'OK'
    } catch {
        Write-WorkstationLog "Task not found or already disabled: $task" 'WARN'
    }
}

Write-WorkstationStep 'Tuning non-critical services (manual start)'
$serviceTuning = @{
    'DiagTrack'   = 'Disabled'   # Connected User Experiences (often already off on ReviOS)
    'dmwappushservice' = 'Disabled'
    'SysMain'     = 'Manual'     # Superfetch — manual on SSD systems
    'WSearch'     = 'Manual'     # Indexer — manual if you use Everything instead
}
foreach ($entry in $serviceTuning.GetEnumerator()) {
    $svc = Get-Service -Name $entry.Key -ErrorAction SilentlyContinue
    if ($svc) {
        try {
            Set-Service -Name $entry.Key -StartupType $entry.Value -ErrorAction Stop
            if ($entry.Value -eq 'Disabled' -and $svc.Status -eq 'Running') {
                Stop-Service -Name $entry.Key -Force -ErrorAction SilentlyContinue
            }
            Write-WorkstationLog "Service $($entry.Key) -> $($entry.Value)" 'OK'
        } catch {
            Write-WorkstationLog "Service $($entry.Key) skipped: $_" 'WARN'
        }
    }
}

Write-WorkstationStep 'Startup apps — audit recommended'
Write-Host @'
Review startup items manually:
  Task Manager -> Startup apps
  Disable: OneDrive (if unused), gaming launchers, vendor bloat

Run: Get-CimInstance Win32_StartupCommand | Select-Object Name, Command, Location

'@ -ForegroundColor DarkGray

Write-WorkstationStep 'PowerShell startup — profile uses lazy loading (already in profile script)'

Write-WorkstationStep 'Windows Terminal — hardware acceleration'
$wtRender = 'HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Terminal Server\DefaultUserConfiguration'
# Terminal GPU rendering is controlled in settings.json (useAcrylic: false for speed)

Write-WorkstationStep 'Performance optimization complete'
