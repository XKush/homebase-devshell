#Requires -Version 7.0
<#
.SYNOPSIS
    Backup profiles, terminal settings, registry exports, and firewall policy.
#>
param([switch]$Force)

$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\lib\WorkstationCommon.ps1"

$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$dest = Join-Path 'C:\Backups\Workstation' $stamp
New-Item -ItemType Directory -Force -Path $dest | Out-Null

Write-WorkstationStep "Backup destination: $dest"

$profilePaths = @(
    "$HOME\Documents\PowerShell\Microsoft.PowerShell_profile.ps1"
    "$HOME\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1"
    'C:\Scripts\Workstation\profile\Microsoft.PowerShell_profile.ps1'
)
foreach ($p in $profilePaths) {
    if (Test-Path $p) {
        Copy-Item $p (Join-Path $dest (Split-Path $p -Leaf)) -Force
        Write-WorkstationLog "Backed up $p" 'OK'
    }
}

$wtPath = Join-Path $env:LOCALAPPDATA 'Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json'
if (Test-Path $wtPath) {
    Copy-Item $wtPath (Join-Path $dest 'WindowsTerminal-settings.json') -Force
}

$omp = 'C:\Scripts\Workstation\terminal\revios-hacker.omp.json'
if (Test-Path $omp) { Copy-Item $omp $dest -Force }

# Registry exports (user + key machine policies)
$regKeys = @(
    'HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
    'HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'
    'HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection'
    'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System'
)
$regDir = Join-Path $dest 'registry'
New-Item -ItemType Directory -Force -Path $regDir | Out-Null
foreach ($key in $regKeys) {
    $out = Join-Path $regDir (($key -replace '[\\:*?"<>|]', '_') + '.reg')
    reg export $key $out /y 2>&1 | Out-Null
}

# Firewall
$fwp = Join-Path $dest 'firewall-policy.wfw'
netsh advfirewall export $fwp 2>&1 | Out-Null

# Manifest
@{
    Timestamp   = $stamp
    Computer    = $env:COMPUTERNAME
    User        = $env:USERNAME
    PowerShell  = $PSVersionTable.PSVersion.ToString()
    BackupPath  = $dest
    Note        = 'Microsoft Defender intentionally not included — remains disabled'
} | ConvertTo-Json | Set-Content (Join-Path $dest 'manifest.json') -Encoding UTF8

Write-WorkstationStep "Backup complete: $dest"
