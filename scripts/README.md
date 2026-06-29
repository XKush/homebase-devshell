# Scripts catalog

Runtime scripts for **HomeBase DevShell** (public name: **DevReady**).

**End users:** only [`install.ps1`](../install.ps1) and [`devshell.ps1`](../devshell.ps1) at the repository root — or `devready` / `devshell` on PATH after install.

---

## Product surface (root)

| Script | Command | Purpose |
|--------|---------|---------|
| [`install.ps1`](../install.ps1) | `irm … \| iex` | Clone, bootstrap, optional winget tools |
| [`devshell.ps1`](../devshell.ps1) | `devshell …` | `init` · `install` · `doctor` · `status` |

PATH shims: `devready.cmd` (doctor Core) · `devshell.cmd` (full CLI)

---

## Install chain — `scripts/maintainer/install/`

| Script | Called by | Purpose |
|--------|-----------|---------|
| `Install-Workstation.ps1` | install / devshell install | Master orchestrator |
| `Install-ShellProfile.ps1` | Install-Workstation | Deploy profile |
| `Install-Software.ps1` | Install-Workstation (unless `-SkipSoftware`) | winget stack |
| `Validate-Workstation.ps1` | devshell doctor | Health gate `-Tier Core\|Full`; `-Fix` auto-repair |
| `Repair-DevReadyEnvironment.ps1` | doctor `-Fix` | winget + PSGallery + local scripts (safe sources) |
| `Invoke-PrivacyAudit.ps1` | devshell privacy | Privacy score + `-Fix` |
| `Repair-PrivacySettings.ps1` | privacy `-Fix` | Safe registry/DNS (no Defender/Firewall/WU) |
| `Invoke-BrowserPrivacyAudit.ps1` | devshell browser | Chrome / Edge / Firefox |
| `Invoke-TorReadinessAudit.ps1` | devshell tor | Tor install/harden check |
| `Invoke-VpnAudit.ps1` | devshell vpn | VPN / TUN / DNS heuristic |
| `Invoke-OpsecCheck.ps1` | devshell opsec | Combined OPSEC snapshot |
| `Invoke-MetadataToolkit.ps1` | devshell metadata | exiftool view/strip |
| `Show-DevShellInitPlan.ps1` | devshell init | Dry-run install plan |
| `Backup-Configuration.ps1` | Install-Workstation | Pre-change backup |
| `Fix-WorkstationPath.ps1` | Install-Workstation | PATH repair |
| `Configure-GitIdentity.ps1` | Install-Workstation | Git placeholder identity |

`Install-Workstation -SkipValidation` when called from product `install.ps1` (doctor runs after command-health).

---

## CI / release gates — `scripts/maintainer/test/`

| Script | CI job | Purpose |
|--------|--------|---------|
| `Test-ReleaseVersion.ps1` | release-version | psd1 + install pin + CHANGELOG + tag |
| `Test-HealthSmoke.ps1` | health-smoke | `health -Json` contract |
| `Test-DoctorSmoke.ps1` | doctor-smoke | `doctor` Core JSON |
| `Test-PrivacyAuditSmoke.ps1` | privacy-smoke | Privacy audits + doctor `-Privacy` |
| `Test-WorkstationCommands.ps1` | command-health | 72 commands + command-health.json |
| `Test-WorkstationPlatformHardening.ps1` | platform-hardening | Platform spec scenarios |
| `Test-HomeBasePaths.ps1` | manual | Path SSOT |
| `Test-LegacyEquivalence.ps1` | Phase 2 | Baseline diff |

Root audits: `Test-MenuAudit.ps1` · `Test-MenuDeepAudit.ps1` · `Test-AnonymityKitAudit.ps1`

**Before tagging:** [docs/RELEASE-CRITERIA.md](../docs/RELEASE-CRITERIA.md)

---

## Configure — `scripts/maintainer/configure/`

Admin / optional — skipped by default OSS install (`-SkipAdmin`).

Examples: `Harden-Security.ps1`, `Configure-Privacy.ps1`, `Repair-WorkstationFonts.ps1`

---

## Invoke — `scripts/maintainer/invoke/`

Maintainer batch scripts — **not** part of `devshell install|doctor|status`.

Examples: `Build-DevReadyRelease.ps1`, `Invoke-WorkstationRevision.ps1`, `Invoke-CommandCenterCI.ps1`

---

## Phase 2 — `scripts/maintainer/phase2/`

Migration and legacy path reports — maintainers only.

---

## More

| Resource | |
|----------|--|
| Public repo map | [docs/product/REPOSITORY-SURFACE.md](../docs/product/REPOSITORY-SURFACE.md) |
| Full inventory | [internal-docs/product/SCRIPTS-INVENTORY.md](../internal-docs/product/SCRIPTS-INVENTORY.md) |
| Changelog | [CHANGELOG.md](../CHANGELOG.md) |
