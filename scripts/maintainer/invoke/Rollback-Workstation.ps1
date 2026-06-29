#Requires -Version 7.0
#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Roll back workstation changes using backups in C:\Backups\Workstation.
.NOTES
    Does NOT re-enable Microsoft Defender.
#>
param(
    [string]$BackupFolder,
    [switch]$Force
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '..\_Resolve-RepoRoot.ps1')
$repoRoot = Resolve-WorkstationRepoRoot -Start $PSScriptRoot
$script:WSRoot = $repoRoot
. (Join-Path $repoRoot 'lib\WorkstationCommon.ps1')
Assert-WorkstationAdmin
Assert-DefenderUntouched

if (-not $BackupFolder) {
    $latest = Get-ChildItem 'C:\Backups\Workstation' -Directory -ErrorAction SilentlyContinue |
        Sort-Object Name -Descending | Select-Object -First 1
    if (-not $latest) { throw 'No backup folder found in C:\Backups\Workstation' }
    $BackupFolder = $latest.FullName
}

if (-not (Test-Path $BackupFolder)) { throw "Backup not found: $BackupFolder" }
if (-not (Confirm-WorkstationAction -Message "Rollback using $BackupFolder ?" -Force:$Force)) { return }

Write-WorkstationStep 'Restoring PowerShell profiles'
$profiles = Get-ChildItem $BackupFolder -Filter '*profile*.ps1' -ErrorAction SilentlyContinue
foreach ($f in $profiles) {
    if ($f.Name -eq 'Microsoft.PowerShell_profile.ps1') {
        $target = Join-Path $HOME 'Documents\PowerShell\Microsoft.PowerShell_profile.ps1'
        Copy-Item $f.FullName $target -Force
        Write-WorkstationLog "Restored $target" 'OK'
    }
}

Write-WorkstationStep 'Restoring Windows Terminal settings'
$wtBackup = Join-Path $BackupFolder 'WindowsTerminal-settings.json'
if (Test-Path $wtBackup) {
    $wtLive = Join-Path $env:LOCALAPPDATA 'Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json'
    Copy-Item $wtBackup $wtLive -Force
    Write-WorkstationLog 'Terminal settings restored' 'OK'
}

Write-WorkstationStep 'Restoring registry exports'
$regDir = Join-Path $BackupFolder 'registry'
if (Test-Path $regDir) {
    Get-ChildItem $regDir -Filter '*.reg' | ForEach-Object {
        reg import $_.FullName 2>&1 | Out-Null
        Write-WorkstationLog "Imported $($_.Name)"
    }
}

Write-WorkstationStep 'Restoring firewall policy'
$fwp = Join-Path $BackupFolder 'firewall-policy.wfw'
if (Test-Path $fwp) {
    netsh advfirewall import $fwp | Out-Null
    Write-WorkstationLog 'Firewall policy restored' 'OK'
}

Write-WorkstationStep 'Re-enabling disabled scheduled tasks (telemetry tasks)'
$telemetryTasks = @(
    '\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser'
    '\Microsoft\Windows\Customer Experience Improvement Program\Consolidator'
)
foreach ($task in $telemetryTasks) {
    Enable-ScheduledTask -TaskName $task -ErrorAction SilentlyContinue | Out-Null
}

Write-WorkstationStep 'Service rollback — set DiagTrack/SysMain to default manual'
foreach ($svc in @('SysMain', 'WSearch')) {
    Set-Service -Name $svc -StartupType Manual -ErrorAction SilentlyContinue
}

Write-WorkstationStep 'Rollback complete — restart recommended'
Write-Host 'Defender was NOT re-enabled (per policy).' -ForegroundColor Yellow
