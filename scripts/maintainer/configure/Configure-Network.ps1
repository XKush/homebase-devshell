#Requires -Version 7.0

. (Join-Path $PSScriptRoot '..\_Resolve-RepoRoot.ps1')
$repoRoot = Resolve-WorkstationRepoRoot -Start $PSScriptRoot
#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Network firewall rules, logging, and Wi-Fi security guidance.
#>

. (Join-Path $PSScriptRoot '..\_Resolve-RepoRoot.ps1')
$repoRoot = Resolve-WorkstationRepoRoot -Start $PSScriptRoot
param([switch]$Force)

$ErrorActionPreference = 'Stop'
. "$repoRoot\lib\WorkstationCommon.ps1"
Assert-WorkstationAdmin
Assert-DefenderUntouched

if (-not (Confirm-WorkstationAction -Message 'Apply network hardening?' -Force:$Force)) { return }

Write-WorkstationStep 'Firewall baseline'
foreach ($prof in @('Domain', 'Private', 'Public')) {
    Set-NetFirewallProfile -Profile $prof -Enabled True -DefaultInboundAction Block -DefaultOutboundAction Allow -LogBlocked True -LogAllowed True -LogMaxSizeKilobytes 32768
}

Write-WorkstationStep 'Allow essential outbound (already default Allow outbound)'

Write-WorkstationStep 'Block inbound SMB on Public profile'
New-NetFirewallRule -DisplayName 'ReviOS-Block-SMB-In-Public' -Direction Inbound -Protocol TCP -LocalPort 445 -Profile Public -Action Block -Enabled True -ErrorAction SilentlyContinue | Out-Null
New-NetFirewallRule -DisplayName 'ReviOS-Block-NetBIOS-In-Public' -Direction Inbound -Protocol UDP -LocalPort 137,138 -Profile Public -Action Block -Enabled True -ErrorAction SilentlyContinue | Out-Null

Write-WorkstationStep 'Allow mDNS only on Private (optional discovery)'
New-NetFirewallRule -DisplayName 'ReviOS-mDNS-Private-In' -Direction Inbound -Protocol UDP -LocalPort 5353 -Profile Private -Action Allow -Enabled True -ErrorAction SilentlyContinue | Out-Null

Write-WorkstationStep 'Export firewall policy'
$exportPath = 'C:\Security\exports\firewall-policy.wfw'
New-Item -ItemType Directory -Force -Path (Split-Path $exportPath) | Out-Null
netsh advfirewall export $exportPath | Out-Null
Write-WorkstationLog "Firewall exported: $exportPath" 'OK'

Write-WorkstationStep 'Network profile recommendations'
Write-Host @'

Wi-Fi / Alfa adapter — professional use guidelines:
  1. Use WPA3 or WPA2-Enterprise on production networks; avoid open/WEP.
  2. Set unknown networks to Public profile (Settings -> Network -> Wi-Fi -> properties).
  3. Disable auto-connect to open hotspots.
  4. For research: use isolated lab VLAN/VM; never probe networks without authorization.
  5. Monitor adapter driver updates from Alfa — unsigned drivers are a supply-chain risk.
  6. Wireshark/Nmap: capture only on interfaces you own or have written permission to test.
  7. On Public Wi-Fi: use VPN; assume DNS/ARP attacks; prefer DoH (configured in Configure-Privacy.ps1).

Alfa monitor mode / packet injection (where legally permitted):
  - Prefer dedicated lab AP + isolated switch.
  - Document scope and authorization before any RF survey.
  - Keep research traffic off production credentials.

'@ -ForegroundColor Cyan

$guidePath = 'C:\Security\Alfa-Adapter-Guidelines.md'
@'
# Alfa Wireless Adapter — Professional Use Guidelines

## Legal and ethical baseline
- Only monitor, scan, or capture on networks you own or have **explicit written authorization** to test.
- Comply with local telecommunications and computer misuse laws.

## Driver and hardware
- Install drivers from official Alfa / chipset vendor sources only.
- Verify driver signature before installation.
- Keep firmware updated; document changes in `C:\Logs\Workstation`.

## Network hygiene
- Unknown SSIDs → **Public** firewall profile.
- Disable auto-connect to open networks.
- Prefer WPA3; use VPN on untrusted Wi-Fi.

## Research lab setup (recommended)
- Dedicated USB Alfa adapter for lab work only.
- Isolated VLAN or air-gapped test AP.
- VM snapshot before running capture tools.
- Store captures encrypted under `C:\Security\exports`.

## Tooling
- Wireshark: promiscuous mode only in authorized environments.
- Nmap: `-sn` for discovery; full scans only with scope approval.
- Log all engagements in `C:\Logs\Workstation`.

## Without Microsoft Defender
- Maintain strict firewall rules (see `Configure-Network.ps1`).
- Keep Windows Update enabled for OS patches.
- Use SmartScreen + exploit mitigations from `Harden-Security.ps1`.
- Consider secondary on-demand scanner for downloaded artifacts (your choice — not installed here).
'@ | Set-Content $guidePath -Encoding UTF8
Write-WorkstationLog "Guide written: $guidePath" 'OK'

Write-WorkstationStep 'Network configuration complete'
