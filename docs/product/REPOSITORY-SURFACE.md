# Repository surface — what GitHub visitors see

**DevReady** is the public name. **HomeBase DevShell** is the product engine behind `install.ps1` and `devshell.ps1`.

---

## Root — product face

| File | Label | Purpose |
|------|-------|---------|
| **`README.md`** | DevReady hero | Install → `devready` → Ready to work |
| **`README.ru.md`** | DevReady (RU) | Russian mirror |
| **`install.ps1`** | Bootstrap | `irm … \| iex` one-liner |
| **`devshell.ps1`** | Product CLI | `install` · `doctor` · `status` |
| **`CHANGELOG.md`** | Release log | Semver product history |
| **`LICENSE`** | MIT | |
| **`CONTRIBUTING.md`** | Contributors | |
| **`SECURITY.md`** | Security | |

PATH shims (after install): **`devready.cmd`** · **`devshell.cmd`** in `%LOCALAPPDATA%\Microsoft\WindowsApps`

---

## `.github/` — automation & templates

| Path | Purpose |
|------|---------|
| `workflows/ci.yml` | Release gates (4 jobs) |
| `ISSUE_TEMPLATE/` | Bug, install-help |
| `pull_request_template.md` | PR checklist |
| `FUNDING.yml` | Sponsor link (optional) |
| `social-preview.png` | Maintainer asset for Settings → Social preview |

Growth copy and launch templates: `internal-docs/marketing/` (not public tree).

---

## Root — CI audit gates

| File | Purpose |
|------|---------|
| `Test-MenuAudit.ps1` | `go` menu registry integrity |
| `Test-MenuDeepAudit.ps1` | Menu + command self-checks |
| `Test-AnonymityKitAudit.ps1` | Tor/PGP kit wiring (opt-in) |

Not for end users — run via `doctor -Tier Full` or GitHub Actions.

---

## User commands

```powershell
devready                    # → devshell doctor (Core)
devshell install
devshell doctor [-Tier Full]
devshell status
```

---

## Directory tree (labeled)

```
├── docs/                 User guides + BRAND.md
├── examples/minimal/     Fork without security pack
├── Config/               homebase.defaults.json (paths SSOT)
├── profile/              Canonical pwsh profile
├── modules/              KGreen.Workstation — command center
├── lib/                  Platform runtime (spec 1.0.0 LOCKED)
├── terminal/             OMP themes, WT template
│
├── scripts/maintainer/
│   ├── install/          Install-Workstation, Validate-Workstation, …
│   ├── invoke/           Batch audits, revision, CI helpers
│   ├── configure/        Privacy, PATH, fonts (admin optional)
│   ├── test/             Release gates, command-health
│   └── phase2/           Migration tooling (maintainers)
│
└── internal-docs/        Charter, ADR — not marketed
```

---

## Audience matrix

| Path | Who |
|------|-----|
| Root README + `docs/` | First-time users |
| `modules/` + `lib/` | Shipped runtime (don't market as framework) |
| `scripts/maintainer/` | Maintainers & CI |
| `internal-docs/` | Serious contributors, release engineering |

---

## Platform note

Execution architecture locked at **spec v1.0.0**. Product polish (docs, brand, install UX, CI) is welcome without touching the orchestrator contract.
