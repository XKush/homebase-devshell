#Requires -Version 7.0
<#
.SYNOPSIS
    Safe privacy fixes — idempotent, user-consented. Never touches Defender, Firewall, or Windows Update.
#>
[CmdletBinding()]
param(
    [switch]$Force,
    [ValidateSet('Quad9', 'Cloudflare', 'Mullvad', 'None')]
    [string]$DnsProvider = 'Quad9',
    [switch]$ApplyProfile,
    [string]$RepoRoot
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '..\_Resolve-RepoRoot.ps1')
if (-not $RepoRoot) { $RepoRoot = Resolve-WorkstationRepoRoot -Start $PSScriptRoot }
. (Join-Path $RepoRoot 'lib\WorkstationCommon.ps1')
. (Join-Path $RepoRoot 'lib\PrivacyAudit.ps1')
Assert-DefenderUntouched

$isAdmin = Test-WorkstationAdmin
$profile = if ($ApplyProfile) { Get-PrivacyProfile -RepoRoot $RepoRoot } else { $null }
$stats = @{ Applied = 0; Skipped = 0; Unavailable = 0 }

if (-not (Confirm-WorkstationAction -Message 'Apply safe privacy fixes? (Defender/Firewall/Windows Update unchanged)' -Force:$Force)) {
    Write-Host 'Cancelled.' -ForegroundColor DarkGray
    return
}

Write-WorkstationStep 'Safe privacy repair'
Write-Host "  Elevation: $(if ($isAdmin) { 'admin' } else { 'standard — HKLM/DoH skipped' })" -ForegroundColor DarkGray
Write-Host '  Policy: no Defender · no Firewall · no Windows Update changes' -ForegroundColor DarkGray

function Test-RegistryDwordMatch {
    param([string]$Path, [string]$Name, [int]$Expected)
    $cur = Get-PrivacyRegistryDword -Path $Path -Name $Name
    if ($null -eq $cur) { return ($Expected -eq 0) }
    return ($cur -eq $Expected)
}

function Set-RegistryDwordIfNeeded {
    param([string]$Path, [string]$Name, [int]$Value, [string]$Label)
    if (Test-RegistryDwordMatch -Path $Path -Name $Name -Expected $Value) {
        Write-Host "  [ok] $Label" -ForegroundColor DarkGray
        $script:stats.Skipped++
        return
    }
    Set-RegistryValueSafe -Path $Path -Name $Name -Value $Value
    Write-Host "  [fix] $Label" -ForegroundColor Cyan
    $script:stats.Applied++
}

# HKCU — no admin required
Set-RegistryDwordIfNeeded 'HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo' 'Enabled' 0 'Advertising ID off'
Set-RegistryDwordIfNeeded 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' 'SystemPaneSuggestionsEnabled' 0 'Suggested content off'
Set-RegistryDwordIfNeeded 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' 'SubscribedContent-338388Enabled' 0 'Tailored experiences off'
Set-RegistryDwordIfNeeded 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' 'SubscribedContent-310093Enabled' 0 'Consumer suggestions off'
Set-RegistryDwordIfNeeded 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' 'SubscribedContent-338389Enabled' 0 'Suggested content tiles off'
Set-RegistryDwordIfNeeded 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'Start_TrackProgs' 0 'Recent programs tracking off'
Set-RegistryDwordIfNeeded 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer' 'ShowRecent' 0 'Recent files off'
Set-RegistryDwordIfNeeded 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Search' 'EnableDynamicContentInWSB' 0 'Search highlights off'
Set-RegistryDwordIfNeeded 'HKCU:\Software\Microsoft\Clipboard' 'EnableClipboardHistory' 0 'Clipboard history off'
Set-RegistryDwordIfNeeded 'HKCU:\Software\Microsoft\Siuf\Rules' 'NumberOfSIUFInPeriod' 0 'Feedback prompts reduced'

if ($isAdmin) {
    Write-WorkstationStep 'Elevated privacy settings (admin)'
    Backup-RegistryKey 'HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection' 'Telemetry'
    Set-RegistryDwordIfNeeded 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection' 'AllowTelemetry' 0 'Telemetry minimal'
    Set-RegistryDwordIfNeeded 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search' 'AllowCortana' 0 'Cortana off'
    Set-RegistryDwordIfNeeded 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors' 'DisableLocation' 1 'Location off'
    Set-RegistryDwordIfNeeded 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System' 'EnableActivityFeed' 0 'Activity feed off'
    Set-RegistryDwordIfNeeded 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System' 'PublishUserActivities' 0 'Publish activities off'
    Set-RegistryDwordIfNeeded 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System' 'UploadUserActivities' 0 'Upload activities off'
    Set-RegistryDwordIfNeeded 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System' 'AllowClipboardHistory' 0 'Clipboard history (policy) off'
    Set-RegistryDwordIfNeeded 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent' 'DisableWindowsConsumerFeatures' 1 'Consumer features off'
    Set-RegistryDwordIfNeeded 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent' 'DisableSoftLanding' 1 'Soft landing off'

    $dnsChoice = if ($profile -and $profile.dnsProvider) { [string]$profile.dnsProvider } else { $DnsProvider }
    if ($profile -and $profile.doh -eq $false) { $dnsChoice = 'None' }
    if ($dnsChoice -ne 'None') {
        $dnsServers = switch ($dnsChoice) {
            'Quad9'      { @('9.9.9.9', '149.112.112.112') }
            'Cloudflare' { @('1.1.1.1', '1.0.0.1') }
            'Mullvad'    { @('194.242.2.2', '194.242.2.3') }
            default      { @() }
        }
        if ($dnsServers.Count -gt 0) {
            $adapter = Get-NetAdapter -ErrorAction SilentlyContinue |
                Where-Object { $_.Status -eq 'Up' -and $_.PhysicalMediaType -ne 'Unspecified' } | Select-Object -First 1
            if ($adapter) {
                $currentDns = (Get-DnsClientServerAddress -InterfaceIndex $adapter.ifIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue).ServerAddresses
                $dnsMatch = ($null -ne $currentDns) -and (@($currentDns | Sort-Object) -join ',') -eq (@($dnsServers | Sort-Object) -join ',')
                if ($dnsMatch) {
                    Write-Host "  [ok] DNS $dnsChoice on $($adapter.Name)" -ForegroundColor DarkGray
                    $stats.Skipped++
                } else {
                    Set-DnsClientServerAddress -InterfaceIndex $adapter.ifIndex -ServerAddresses $dnsServers
                    Write-Host "  [fix] DNS $dnsChoice on $($adapter.Name)" -ForegroundColor Cyan
                    $stats.Applied++
                }
            }
            if (Test-DnsOverHttpsConfigured) {
                Write-Host '  [ok] DNS over HTTPS templates' -ForegroundColor DarkGray
                $stats.Skipped++
            } else {
                $dohTemplates = @{
                    '9.9.9.9'         = 'https://dns.quad9.net/dns-query'
                    '149.112.112.112' = 'https://dns.quad9.net/dns-query'
                    '1.1.1.1'         = 'https://cloudflare-dns.com/dns-query'
                    '1.0.0.1'         = 'https://cloudflare-dns.com/dns-query'
                    '194.242.2.2'     = 'https://dns.mullvad.net/dns-query'
                    '194.242.2.3'     = 'https://dns.mullvad.net/dns-query'
                }
                $dohAdded = $false
                foreach ($ip in $dnsServers) {
                    if (-not $dohTemplates.ContainsKey($ip)) { continue }
                    try {
                        Add-DnsClientDohServerAddress -ServerAddress $ip -DohTemplate $dohTemplates[$ip] -AllowFallbackToUdp $false -AutoUpgrade $true -ErrorAction Stop
                        $dohAdded = $true
                    } catch {
                        if ($_.Exception.Message -match 'already exists|duplicate') {
                            $stats.Skipped++
                        } else {
                            Write-WorkstationLog "DoH $ip : $_" 'WARN'
                        }
                    }
                }
                if ($dohAdded) {
                    Write-Host '  [fix] DNS over HTTPS templates' -ForegroundColor Cyan
                    $stats.Applied++
                }
            }
        }
    }
} else {
    Write-Host '  [skip] HKLM telemetry / DoH — elevation required (re-run: Start-Process pwsh -Verb RunAs -ArgumentList ''-File devshell.ps1 privacy -Fix -Force'')' -ForegroundColor Yellow
    $stats.Unavailable++
}

if ($ApplyProfile -and $profile) {
    $dest = Join-Path $env:USERPROFILE '.homebase\privacy.json'
    $dir = Split-Path $dest -Parent
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
    $src = Get-PrivacyConfigPath -RepoRoot $RepoRoot
    if ($src -and ((-not (Test-Path $dest)) -or ((Get-FileHash $src).Hash -ne (Get-FileHash $dest).Hash))) {
        Copy-Item $src $dest -Force
        Write-Host "  [fix] Privacy profile saved: $dest" -ForegroundColor Cyan
        $stats.Applied++
    } else {
        Write-Host "  [ok] Privacy profile already at $dest" -ForegroundColor DarkGray
        $stats.Skipped++
    }
}

Write-WorkstationStep 'Privacy repair complete'
Write-Host "  Applied: $($stats.Applied) · Already OK: $($stats.Skipped) · Needs admin: $($stats.Unavailable)" -ForegroundColor DarkGray
if ($stats.Applied -eq 0) {
    Write-Host '  No registry changes needed — system already matches safe profile (HKCU scope).' -ForegroundColor Green
}
Write-Host '  Re-run: devshell privacy' -ForegroundColor DarkGray
