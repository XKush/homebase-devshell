# Repository surface — what GitHub visitors see

**HomeBase DevShell** is intentionally minimal on the repository root.

---

## Public product (this is the whole story)

| Root file | Purpose |
|-----------|---------|
| **`README.md`** | Install → doctor → Ready to work |
| **`install.ps1`** | One-line bootstrap |
| **`devshell.ps1`** | Three commands: `install` · `doctor` · `status` |
| **`CHANGELOG.md`** | Release history (single source of truth) |
| **`LICENSE`** | MIT |

Also: `README.ru.md`, `SECURITY.md`, `CONTRIBUTING.md` — support, not hero.

---

## User commands (only three)

```powershell
devshell install
devshell doctor
devshell status
```

Everything else lives under **`scripts/maintainer/`** — not at the repository root.

---

## Where maintainer scripts live

| Subfolder | Examples |
|-----------|----------|
| `scripts/maintainer/install/` | `Install-Workstation.ps1`, `Validate-Workstation.ps1`, install chain |
| `scripts/maintainer/invoke/` | `Invoke-Maintenance.ps1`, audits, organization |
| `scripts/maintainer/configure/` | `Configure-Privacy.ps1`, `Fix-WorkstationPath.ps1` |
| `scripts/maintainer/test/` | `Test-WorkstationPlatformHardening.ps1`, release gates |
| `scripts/maintainer/phase2/` | Phase 2 migration tooling |

`install.ps1` and `devshell.ps1` call `scripts/maintainer/install/` directly. There are **no root shims** in the OSS surface.

---

## Where things live

| Path | Audience |
|------|----------|
| `docs/` | First-time users (getting started, troubleshooting) |
| `scripts/maintainer/` | Maintainer scripts (invoke, configure, test, phase2) |
| `internal-docs/` | Platform lock, baselines, release engineering |
| `lib/`, `modules/`, `profile/` | Shipped runtime (not marketed as a framework) |

---

## What we do **not** expect strangers to run

- `Invoke-*` batch audits and maintenance passes  
- `Configure-*` privacy/Tor/PGP (optional, module-driven)  
- `Test-*` except indirectly via release CI / hardening gate  
- Phase 2 migration tooling under `scripts/maintainer/phase2/`  

If you only want a working dev shell: **use the README install line and `devshell doctor`.**

---

## Platform note

Execution architecture is locked at spec **v1.0.0**. Product docs do not expose internal dispatch design. See `internal-docs/` for maintainers.
