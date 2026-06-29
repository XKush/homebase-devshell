#Requires -Version 7.0
#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Privacy configuration — telemetry reduction without breaking Windows Update.
.NOTES
    Does NOT disable Windows Update security patches.
    Does NOT enable Microsoft Defender.
#>
param(
    [switch]$Force,
    [ValidateSet('Quad9', 'Cloudflare', 'Mullvad', 'None')]
    [string]$DnsProvider = 'Quad9'
)

. (Join-Path $PSScriptRoot '..\_Resolve-RepoRoot.ps1')
$repoRoot = Resolve-WorkstationRepoRoot -Start $PSScriptRoot

$ErrorActionPreference = 'Stop'
. "$repoRoot\lib\WorkstationCommon.ps1"
Assert-WorkstationAdmin
Assert-DefenderUntouched

if (-not (Confirm-WorkstationAction -Message 'Apply privacy settings?' -Force:$Force)) { return }

Write-WorkstationStep 'Registry backups'
Backup-RegistryKey 'HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection' 'Telemetry'
Backup-RegistryKey 'HKCU\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo' 'AdID'

Write-WorkstationStep 'Telemetry and diagnostics'
$telemetryPaths = @{
    'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection' = @{
        AllowTelemetry = 0
        DisableEnterpriseAuthProxy = 1
    }
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection' = @{
        AllowTelemetry = 0
    }
    'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search' = @{
        AllowCortana = 0
        AllowSearchToUseLocation = 0
    }
}
foreach ($path in $telemetryPaths.Keys) {
    foreach ($kv in $telemetryPaths[$path].GetEnumerator()) {
        Set-RegistryValueSafe -Path $path -Name $kv.Key -Value $kv.Value
    }
}

Write-WorkstationStep 'Advertising ID and consumer experiences'
Set-RegistryValueSafe -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo' -Name 'Enabled' -Value 0
Set-RegistryValueSafe -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' -Name 'SystemPaneSuggestionsEnabled' -Value 0
Set-RegistryValueSafe -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' -Name 'SubscribedContent-338388Enabled' -Value 0
Set-RegistryValueSafe -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' -Name 'SubscribedContent-310093Enabled' -Value 0
Set-RegistryValueSafe -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' -Name 'SubscribedContent-338389Enabled' -Value 0
Set-RegistryValueSafe -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent' -Name 'DisableWindowsConsumerFeatures' -Value 1
Set-RegistryValueSafe -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent' -Name 'DisableSoftLanding' -Value 1

Write-WorkstationStep 'Activity history and suggestions'
Set-RegistryValueSafe -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System' -Name 'EnableActivityFeed' -Value 0
Set-RegistryValueSafe -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System' -Name 'PublishUserActivities' -Value 0
Set-RegistryValueSafe -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System' -Name 'UploadUserActivities' -Value 0
Set-RegistryValueSafe -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'Start_TrackProgs' -Value 0

Write-WorkstationStep 'Cloud sync reduction (non-destructive)'
Set-RegistryValueSafe -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\SettingSync' -Name 'DisableSettingSync' -Value 2
Set-RegistryValueSafe -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\SettingSync' -Name 'DisableSettingSyncUserOverride' -Value 1
Set-RegistryValueSafe -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\SettingSync' -Name 'SyncPolicy' -Value 5

Write-WorkstationStep 'Location and feedback prompts'
Set-RegistryValueSafe -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors' -Name 'DisableLocation' -Value 1
Set-RegistryValueSafe -Path 'HKCU:\Software\Microsoft\Siuf\Rules' -Name 'NumberOfSIUFInPeriod' -Value 0 -Type DWord

Write-WorkstationStep 'Windows Update — security patches remain ENABLED'
Set-RegistryValueSafe -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU' -Name 'NoAutoUpdate' -Value 0
Write-WorkstationLog 'Windows Update not disabled — security patches continue' 'OK'

Write-WorkstationStep 'DNS privacy provider'
$dnsServers = switch ($DnsProvider) {
    'Quad9'     { @('9.9.9.9', '149.112.112.112') }
    'Cloudflare'{ @('1.1.1.1', '1.0.0.1') }
    'Mullvad'   { @('194.242.2.2', '194.242.2.3') }
    default     { @() }
}
if ($dnsServers.Count -gt 0) {
    $adapter = Get-NetAdapter | Where-Object { $_.Status -eq 'Up' -and $_.PhysicalMediaType -ne 'Unspecified' } | Select-Object -First 1
    if ($adapter) {
        Set-DnsClientServerAddress -InterfaceIndex $adapter.ifIndex -ServerAddresses $dnsServers
        Write-WorkstationLog "DNS set to $DnsProvider on $($adapter.Name)" 'OK'
    }
    # DoH templates (Windows 11+)
    $dohTemplates = @{
        '9.9.9.9'       = 'https://dns.quad9.net/dns-query'
        '149.112.112.112' = 'https://dns.quad9.net/dns-query'
        '1.1.1.1'       = 'https://cloudflare-dns.com/dns-query'
        '1.0.0.1'       = 'https://cloudflare-dns.com/dns-query'
        '194.242.2.2'   = 'https://dns.mullvad.net/dns-query'
        '194.242.2.3'   = 'https://dns.mullvad.net/dns-query'
    }
    foreach ($ip in $dnsServers) {
        if ($dohTemplates.ContainsKey($ip)) {
            try {
                Add-DnsClientDohServerAddress -ServerAddress $ip -DohTemplate $dohTemplates[$ip] -AllowFallbackToUdp $false -AutoUpgrade $true -ErrorAction Stop
            } catch {
                Write-WorkstationLog "DoH for $ip : $_" 'WARN'
            }
        }
    }
}

Write-WorkstationStep 'Privacy configuration complete'
