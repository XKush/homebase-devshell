# ReviOS Professional Workstation Setup

Production-ready PowerShell suite for **performance**, **privacy**, **hardening**, and a **dark hacker-style terminal** — without enabling Microsoft Defender Antivirus.

---

## Policy

| Rule | Status |
|------|--------|
| Microsoft Defender AV | **Must remain disabled** — no script here enables, installs, or reactivates it |
| Windows Update security patches | **Remain enabled** |
| Illegal / unauthorized access | **Not supported** — lab use only with authorization |

---

## Quick Start

```powershell
# 1. User-level setup (no admin)
pwsh -File C:\Scripts\Workstation\Install-Workstation.ps1

# 2. Full setup including hardening (elevated)
Start-Process pwsh -Verb RunAs -ArgumentList '-File C:\Scripts\Workstation\Install-Workstation.ps1 -Force'

# 3. Reload shell
. $PROFILE
```

---

## Folder Structure

| Path | Purpose |
|------|---------|
| `C:\Tools` | Portable binaries, Sysinternals, custom tools |
| `C:\Scripts` | Automation scripts (this suite lives in `Workstation\`) |
| `C:\Projects` | Development projects |
| `C:\Logs` | Application and workstation logs |
| `C:\Backups` | Configuration backups before changes |
| `C:\Security` | Policies, exports, Alfa adapter guidelines |

---

## Scripts Reference

| Script | Admin | Description |
|--------|-------|-------------|
| `Install-Workstation.ps1` | Mixed | Master orchestrator |
| `Install-Software.ps1` | No* | winget packages + PS modules |
| `Install-ShellProfile.ps1` | No | Profile, Terminal theme, default shell |
| `Optimize-Performance.ps1` | Yes | Telemetry tasks, services, visual tuning |
| `Configure-Privacy.ps1` | Yes | Telemetry, ads, DoH DNS |
| `Harden-Security.ps1` | Yes | Firewall, UAC, SMB, RDP, exploit mitigations |
| `Configure-Network.ps1` | Yes | Firewall rules, Alfa guidelines |
| `Backup-Configuration.ps1` | No | Export settings before/after changes |
| `Rollback-Workstation.ps1` | Yes | Restore from latest backup |

\*Some winget installs may prompt for elevation.

---

## Single winget Command

```powershell
winget install -e `
  --id Microsoft.PowerShell `
  --id Microsoft.WindowsTerminal `
  --id Git.Git `
  --id Microsoft.VisualStudioCode `
  --id Python.Python.3.12 `
  --id Microsoft.Sysinternals `
  --id WiresharkFoundation.Wireshark `
  --id Insecure.Nmap `
  --id Fastfetch-cli.Fastfetch `
  --id 7zip.7zip `
  --id KeePassXC.KeePassXC `
  --id Bitwarden.Bitwarden `
  --id voidtools.Everything `
  --id Notepad++.Notepad++ `
  --id OBSProject.OBSStudio `
  --id JanDeDobbeleer.OhMyPosh `
  --id junegunn.fzf `
  --id sharkdp.bat `
  --id eza-community.eza `
  --id ajeetdsouza.zoxide `
  --accept-package-agreements `
  --accept-source-agreements `
  --disable-interactivity
```

PowerShell modules (user scope):

```powershell
Install-Module PSReadLine, posh-git, Terminal-Icons -Scope CurrentUser -Force
```

---

## PowerShell Profile Features

Canonical profile: `C:\Scripts\Workstation\profile\Microsoft.PowerShell_profile.ps1`

- **Oh My Posh** — Tokyo Night / hacker palette (`terminal\revios-hacker.omp.json`)
- **PSReadLine** — syntax colors, history + plugin predictions, Ctrl+R fzf search
- **posh-git** — branch/status in prompt
- **Terminal Icons** — file type icons in listings
- **zoxide** — `z` directory jumping
- **eza** — modern `ls` / `ll` / `lt`
- **bat** — syntax-highlighted `cat`
- **fastfetch** — session banner
- **Git aliases** — `gs`, `ga`, `gc`, `gp`, `gl`, `gd`, `glog`
- **Navigation** — `projects`, `tools`, `scripts`, `logs`, `Open-Project`
- **Lazy loading** — fast non-interactive startup

---

## Section Details

### 1. Performance (`Optimize-Performance.ps1`)

| Change | Why |
|--------|-----|
| Visual effects tuned | Less compositor overhead |
| Telemetry scheduled tasks disabled | Less background CPU (if present on ReviOS) |
| DiagTrack / dmwappush disabled | Telemetry services |
| SysMain → Manual | SSD-friendly; reduces idle disk activity |
| WSearch → Manual | Optional if using Everything search |

**Not disabled:** critical services (RPC, DNS, DHCP client, network stack, Windows Update).

### 2. Security (`Harden-Security.ps1`)

| Change | Why |
|--------|-----|
| UAC secure prompt | Blocks silent elevation |
| SMB1 disabled | Legacy protocol attack surface |
| TLS 1.0/1.1 disabled | Weak crypto |
| LLMNR disabled | Spoofing on untrusted LANs |
| RDP disabled by default | Reduce remote attack surface |
| Firewall block inbound | Default deny inbound all profiles |
| Exploit Protection mitigations | DEP/ASLR/CFG on browsers + PowerShell |
| SmartScreen warn | App reputation (not Defender AV) |
| PS script block logging | Audit trail in Event Viewer |
| PS transcription | Logs to `C:\Logs\Workstation\PowerShellTranscripts` |
| Audit policies | Logon, lockout, process creation |

**Limitation:** Attack Surface Reduction (ASR) rules require **Microsoft Defender Antivirus** — intentionally **not** configured here.

### 3. Privacy (`Configure-Privacy.ps1`)

| Change | Why |
|--------|-----|
| AllowTelemetry = 0 | Minimize diagnostic data |
| Advertising ID off | No ad tracking ID |
| Consumer features off | No suggested apps/tips |
| Activity feed off | No cross-device activity upload |
| Setting sync restricted | Less cloud metadata |
| DNS → Quad9/Cloudflare/Mullvad | Privacy-focused resolvers |
| DoH enabled | Encrypted DNS where supported |
| Windows Update **not** disabled | Security patches continue |

### 4. Networking (`Configure-Network.ps1`)

- Public profile: block inbound SMB/NetBIOS
- Firewall logging enabled (check `%systemroot%\system32\LogFiles\Firewall\`)
- Policy export: `C:\Security\exports\firewall-policy.wfw`
- Alfa guidelines: `C:\Security\Alfa-Adapter-Guidelines.md`

---

## DNS Providers

| Provider | DNS | DoH |
|----------|-----|-----|
| **Quad9** (default) | 9.9.9.9, 149.112.112.112 | dns.quad9.net |
| **Cloudflare** | 1.1.1.1, 1.0.0.1 | cloudflare-dns.com |
| **Mullvad** | 194.242.2.2, 194.242.2.3 | dns.mullvad.net |

```powershell
Configure-Privacy.ps1 -DnsProvider Cloudflare -Force
```

---

## Rollback

Automatic backups: `C:\Backups\Workstation\<timestamp>\`

```powershell
# Restore latest backup (admin)
Start-Process pwsh -Verb RunAs -ArgumentList '-File C:\Scripts\Workstation\Rollback-Workstation.ps1 -Force'

# Restore specific backup
Rollback-Workstation.ps1 -BackupFolder 'C:\Backups\Workstation\20250628-120000' -Force
```

Manual rollback:
1. Import `.reg` files from backup `registry\` folder
2. Copy profile + Terminal JSON from backup
3. `netsh advfirewall import C:\Backups\Workstation\<ts>\firewall-policy.wfw`

**Defender is never re-enabled by rollback.**

---

## Maintenance Schedule

| Frequency | Task |
|-----------|------|
| Weekly | `winget upgrade --all`; review `C:\Logs\Workstation` |
| Monthly | `Backup-Configuration.ps1`; review firewall logs |
| Monthly | Audit startup apps (Task Manager) |
| Quarterly | Review `Harden-Security.ps1` for new mitigations |
| After major updates | Re-run `Install-ShellProfile.ps1 -Force` if Terminal resets |

---

## Windows Terminal

- Default profile: **PowerShell 7**
- Color scheme: **ReviOS Hack Dark**
- Font: **Caskaydia Cove Nerd Font**
- Start directory: `C:\Projects`

---

## Without Defender — Compensating Controls

1. Keep **Windows Update** enabled
2. **Firewall** default deny inbound
3. **SmartScreen** warnings for unknown apps
4. **Exploit Protection** mitigations
5. **UAC** always on
6. **PowerShell logging** for forensics
7. **DNS-over-HTTPS** against tampering
8. Consider periodic on-demand scans of downloads (your choice — not installed here)

---

## Logs

| Location | Content |
|----------|---------|
| `C:\Logs\Workstation\workstation.log` | Setup script log |
| `C:\Logs\Workstation\PowerShellTranscripts\` | PS transcription (if hardening applied) |
| `%systemroot%\system32\LogFiles\Firewall\pfirewall.log` | Blocked/allowed connections |

---

## License / Responsibility

For **authorized** security research and professional use only. You are responsible for compliance with applicable laws and network policies.
