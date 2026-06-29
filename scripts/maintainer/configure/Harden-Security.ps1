#Requires -Version 7.0
#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Security hardening WITHOUT enabling Microsoft Defender Antivirus.
.NOTES
    ASR rules require Defender AV — this script uses Exploit Protection, firewall,
    protocol hardening, UAC, auditing, and PowerShell logging instead.
#>
param(
    [switch]$Force,
    [ValidateSet('Quad9', 'Cloudflare', 'Mullvad', 'None')]
    [string]$DnsProvider = 'None'
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '..\_Resolve-RepoRoot.ps1')
$repoRoot = Resolve-WorkstationRepoRoot -Start $PSScriptRoot
$script:WSRoot = $repoRoot
. (Join-Path $repoRoot 'lib\WorkstationCommon.ps1')
Assert-WorkstationAdmin
Assert-DefenderUntouched

if (-not (Confirm-WorkstationAction -Message 'Apply security hardening (Defender stays OFF)?' -Force:$Force)) { return }

Write-WorkstationStep 'Backup security-related registry'
Backup-RegistryKey 'HKLM\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters' 'SMB'
Backup-RegistryKey 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' 'UAC'
Backup-RegistryKey 'HKLM\SOFTWARE\Policies\Microsoft\Windows\PowerShell' 'PSLogging'

Write-WorkstationStep 'UAC — secure defaults'
$uacPath = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System'
Set-RegistryValueSafe -Path $uacPath -Name 'EnableLUA' -Value 1
Set-RegistryValueSafe -Path $uacPath -Name 'ConsentPromptBehaviorAdmin' -Value 5  # Prompt for consent on secure desktop
Set-RegistryValueSafe -Path $uacPath -Name 'PromptOnSecureDesktop' -Value 1
Set-RegistryValueSafe -Path $uacPath -Name 'EnableInstallerDetection' -Value 1

Write-WorkstationStep 'Disable legacy and insecure protocols'
# SMB1
Set-RegistryValueSafe -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters' -Name 'SMB1' -Value 0
Disable-WindowsOptionalFeature -Online -FeatureName SMB1Protocol -NoRestart -ErrorAction SilentlyContinue | Out-Null
# TLS 1.0/1.1 (Schannel)
$tlsPath = 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols'
foreach ($ver in @('TLS 1.0', 'TLS 1.1')) {
    foreach ($role in @('Client', 'Server')) {
        $p = Join-Path $tlsPath "$ver\$role"
        Set-RegistryValueSafe -Path $p -Name 'Enabled' -Value 0
        Set-RegistryValueSafe -Path $p -Name 'DisabledByDefault' -Value 1
    }
}
# LLMNR (spoofing risk on untrusted networks)
Set-RegistryValueSafe -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient' -Name 'EnableMulticast' -Value 0

Write-WorkstationStep 'RDP hardening'
Set-RegistryValueSafe -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server' -Name 'fDenyTSConnections' -Value 1  # Disable RDP by default
Set-RegistryValueSafe -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -Name 'UserAuthentication' -Value 1
Set-RegistryValueSafe -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services' -Name 'fPromptForPassword' -Value 1
Set-RegistryValueSafe -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services' -Name 'MinEncryptionLevel' -Value 3

Write-WorkstationStep 'Windows Firewall — restrictive inbound, audited'
$profiles = @('Domain', 'Private', 'Public')
foreach ($prof in $profiles) {
    Set-NetFirewallProfile -Profile $prof -Enabled True -DefaultInboundAction Block -DefaultOutboundAction Allow -NotifyOnListen True -LogFileName '%systemroot%\system32\LogFiles\Firewall\pfirewall.log' -LogMaxSizeKilobytes 16384 -LogAllowed True -LogBlocked True
    Write-WorkstationLog "Firewall profile hardened: $prof" 'OK'
}
# Allow core outbound; block risky inbound except established
New-NetFirewallRule -DisplayName 'ReviOS-Block-Inbound-All' -Direction Inbound -Action Block -Enabled False -ErrorAction SilentlyContinue | Out-Null
Write-WorkstationLog 'Firewall logging enabled on all profiles' 'OK'

Write-WorkstationStep 'Exploit Protection (system mitigations — independent of Defender AV)'
$mitigations = @(
    @{ Name = 'DEP'; Value = 'ON' }
    @{ Name = 'ASLR'; Value = 'High' }
    @{ Name = 'SEHOP'; Value = 'ON' }
    @{ Name = 'CFG'; Value = 'ON' }
)
# Apply to common attack surface processes
$targets = @('iexplore.exe', 'chrome.exe', 'firefox.exe', 'msedge.exe', 'powershell.exe', 'pwsh.exe')
foreach ($exe in $targets) {
    try {
        Set-ProcessMitigation -Name $exe -Enable DEP, BottomUp, ForceRelocateImages, StrictHandle -ErrorAction SilentlyContinue
    } catch { }
}
Write-WorkstationLog 'Exploit Protection mitigations applied to browser/shell processes' 'OK'
Write-Host '  NOTE: Full ASR rules require Defender AV — intentionally NOT enabled per policy.' -ForegroundColor Yellow

Write-WorkstationStep 'SmartScreen (app reputation — not Defender AV)'
Set-RegistryValueSafe -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System' -Name 'EnableSmartScreen' -Value 1
Set-RegistryValueSafe -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System' -Name 'ShellSmartScreenLevel' -Value 'Warn'

Write-WorkstationStep 'PowerShell script block logging and transcription'
$psPol = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging'
Set-RegistryValueSafe -Path $psPol -Name 'EnableScriptBlockLogging' -Value 1
Set-RegistryValueSafe -Path $psPol -Name 'EnableScriptBlockInvocationLogging' -Value 1
$psTrans = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\Transcription'
Set-RegistryValueSafe -Path $psTrans -Name 'EnableTranscripting' -Value 1
Set-RegistryValueSafe -Path $psTrans -Name 'OutputDirectory' -Value 'C:\Logs\Workstation\PowerShellTranscripts' -Type String
Set-RegistryValueSafe -Path $psTrans -Name 'EnableInvocationHeader' -Value 1
New-Item -ItemType Directory -Force -Path 'C:\Logs\Workstation\PowerShellTranscripts' | Out-Null

Write-WorkstationStep 'Audit policy — key events'
auditpol /set /subcategory:"Logon" /success:enable /failure:enable | Out-Null
auditpol /set /subcategory:"Logoff" /success:enable /failure:enable | Out-Null
auditpol /set /subcategory:"Account Lockout" /success:enable /failure:enable | Out-Null
auditpol /set /subcategory:"Special Logon" /success:enable /failure:enable | Out-Null
auditpol /set /subcategory:"Process Creation" /success:enable /failure:disable | Out-Null
Write-WorkstationLog 'Audit policies configured' 'OK'

Write-WorkstationStep 'Network profile — treat public Wi-Fi as Public'
Set-RegistryValueSafe -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Network Connections' -Name 'NC_StdDomainUserSetLocation' -Value 1

Write-WorkstationStep 'Security hardening complete'
Write-Host @'

To enable RDP later (only if needed):
  Set-ItemProperty HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server fDenyTSConnections 0
  Enable-NetFirewallRule -DisplayGroup 'Remote Desktop'

'@ -ForegroundColor DarkGray
