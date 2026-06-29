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

**Full inventory:** [SCRIPTS-INVENTORY.md](../internal-docs/product/SCRIPTS-INVENTORY.md)  
**Public surface:** [REPOSITORY-SURFACE.md](../docs/product/REPOSITORY-SURFACE.md)

Maintainer scripts live under **`scripts/maintainer/`** (`invoke/`, `configure/`, `test/`, `phase2/`). Root `.ps1` names are **compatibility shims**.

---

## Test-* (6)

| Script | Role |
|--------|------|
| [`Test-WorkstationPlatformHardening.ps1`](../Test-WorkstationPlatformHardening.ps1) | **Release gate** — 11 platform scenarios |
| `Test-WorkstationCommands.ps1` | Module command smoke (CI / maintainer) |
| `Test-HomeBasePaths.ps1` | Path SSOT checks (Phase 2) |
| `Test-LegacyEquivalence.ps1` | Baseline JSON diff (Phase 2) |
| `Test-ReleaseVersion.ps1` | Release version consistency (needs path update) |
| `Test-RestoreRehearsal.ps1` | Backup restore rehearsal |

WIP menu/anonymity tests are **gitignored** — not shipped.

---

## Configure-* (5)

| Script | Product install? |
|--------|------------------|
| `Configure-GitIdentity.ps1` | ✅ Yes (always) |
| `Configure-Privacy.ps1` | Admin only (`-SkipAdmin` default) |
| `Configure-Network.ps1` | Admin only |
| `Configure-PgpIdentity.ps1` | Optional (module) |
| `Configure-TorSecurity.ps1` | Optional (module) |

---

## Invoke-* (23)

Maintainer / operator batch scripts — **not** part of `devshell install|doctor|status`.

Groups: Phase 2 gates, audits, maintenance (`Invoke-Maintenance.ps1`), recovery (`Invoke-TerminalRecovery.ps1`). See [SCRIPTS-INVENTORY.md](../internal-docs/product/SCRIPTS-INVENTORY.md).

---

## CHANGELOG

| File | Role |
|------|------|
| [`CHANGELOG.md`](../CHANGELOG.md) | **Public** product history |
| [`internal-docs/charter/CHANGELOG.md`](../internal-docs/charter/CHANGELOG.md) | Pointer to root only |

---

## Phase 2 (planned)

Move maintainer scripts into:

```
scripts/maintainer/
scripts/admin/
scripts/install/
```

Root keeps thin forwarding stubs — requires a dedicated path migration (not started).
