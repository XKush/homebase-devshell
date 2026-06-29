# Scripts index

**HomeBase DevShell** ships most scripts at the **repository root** so install paths stay stable (`$PSScriptRoot`).

This folder is a **catalog only** — not the runtime location (Phase 2 may move files here with root shims).

---

## Product (user-facing)

| Script | Purpose |
|--------|---------|
| [`install.ps1`](../install.ps1) | One-line bootstrap |
| [`devshell.ps1`](../devshell.ps1) | `install` · `doctor` · `status` |

---

## Install chain (called by product install)

| Script | Purpose |
|--------|---------|
| [`Install-Workstation.ps1`](../Install-Workstation.ps1) | Master setup orchestrator |
| [`Install-ShellProfile.ps1`](../Install-ShellProfile.ps1) | Deploy PowerShell profile |
| [`Validate-Workstation.ps1`](../Validate-Workstation.ps1) | Health gate (`devshell doctor`) |
| [`Backup-Configuration.ps1`](../Backup-Configuration.ps1) | Pre-change backup |
| [`Fix-WorkstationPath.ps1`](../Fix-WorkstationPath.ps1) | PATH repair |
| [`Configure-GitIdentity.ps1`](../Configure-GitIdentity.ps1) | Git defaults |

---

## Admin / full install (skipped by default product install)

| Script | Purpose |
|--------|---------|
| `Optimize-Performance.ps1` | Performance tuning (elevated) |
| `Configure-Privacy.ps1` | Privacy / DNS |
| `Harden-Security.ps1` | Security hardening |
| `Configure-Network.ps1` | Network setup |
| `Install-Software.ps1` | Optional software stack |

---

## Maintainer / CI (not for first-time users)

| Pattern | Examples |
|---------|----------|
| `Invoke-*` | Audits, baselines, integration rehearsal, commit gate |
| `Save-*` | Profile snapshots, phase baselines |
| `Test-*` | `Test-WorkstationPlatformHardening.ps1` (release gate), legacy equivalence |
| `Sync-*` / `Generate-*` | Doc sync, cheatsheet generation |
| `Repair-*` / `Rollback-*` | Recovery tooling |

Platform internals: see [`internal-docs/`](../internal-docs/).

---

## Phase 2 (planned)

Move maintainer scripts into:

```
scripts/maintainer/
scripts/admin/
scripts/install/
```

Root keeps thin forwarding stubs — requires a dedicated path migration (not started).
