# HomeBase DevShell

**Fast, self-checking PowerShell 7 dev environment for Windows — without the framework bloat.**

Ships a production profile, a full command center (`doctor`, `home`, `go`), and a 5-command product CLI. Platform execution model is [locked at spec v1.0.0](docs/platform-spec-summary.md) for stability.

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

---

## Why this exists

Windows + PowerShell setups drift: slow profiles, broken paths, silent misconfigurations, and “works on my machine” dotfiles nobody can trust.

HomeBase DevShell gives you:

- **Sub-600ms profile load** with a real command center, not a junk drawer of aliases  
- **`devshell doctor`** — one health gate before you trust the environment  
- **Stable core** — product updates without rewriting your dispatch architecture  

---

## 60-second install

**Recommended (pinned release):**

```powershell
irm https://raw.githubusercontent.com/KGreen/homebase-devshell/v2.0.0/install.ps1 | iex
```

**From a clone:**

```powershell
git clone https://github.com/KGreen/homebase-devshell.git $HOME\.homebase\devshell
cd $HOME\.homebase\devshell
pwsh -File install.ps1
```

Restart your terminal, then:

```powershell
pwsh -File $HOME\.homebase\devshell\devshell.ps1 status
```

Add a alias for daily use:

```powershell
function devshell { pwsh -NoProfile -File "$HOME\.homebase\devshell\devshell.ps1" @args }
```

---

## Core commands (start here)

| Command | Purpose |
|---------|---------|
| **`devshell install`** | Bootstrap folders, deploy profile, baseline setup |
| **`devshell doctor`** | Full health validation — pass/fail gate |
| **`devshell status`** | Product version, platform lock, runtime state |

```powershell
pwsh -File devshell.ps1 install
pwsh -File devshell.ps1 doctor
pwsh -File devshell.ps1 status
```

### Optional (power users)

| Command | Purpose |
|---------|---------|
| `devshell reload` | Refresh profile stack |
| `devshell trace` | Last N execution trace rows (read-only, current session) |

---

## Example: `devshell doctor`

```
HomeBase DevShell v2.0.0 — install
Repository: C:\Users\you\.homebase\devshell

==> Bootstrap (folders + profile, user scope)
...
==> Health check (devshell doctor)

═══════════════════ VALIDATION REPORT ═══════════════════
Passed:   71
Failed:   0
Warnings: 0
Profile load: 489ms <= 600ms
Report: C:\Logs\Workstation\validation-20260629-030000.json
═══════════════════════════════════════════════════════

SUCCESS: HomeBase DevShell is ready.
```

If `Failed` > 0, open the JSON report under `C:\Logs\Workstation\` and re-run after fixes.

---

## Example: `devshell status`

```
HomeBase DevShell
  Product:  2.0.0
  Platform: 1.0.0 (LOCKED)
  Signed:   2026-06-29

Runtime
  Bootstrap:   OK
  Environment: OK
  Diagnostics: OK
  Hints:       Loaded
```

After install, the full in-session command center loads from your profile: `doctor`, `home`, `go`, `trustcheck`, and more.

---

## What this is **not**

- **Not a cloud product** — everything runs locally  
- **Not a general-purpose CLI framework** — no plugin router you must learn  
- **Not a log analytics platform** — execution trace is in-memory and read-only  
- **Not an open core / closed brain** — the platform spec is public and frozen, not hidden magic  
- **Not something you extend by patching orchestrator internals** — use extensions or module commands instead  

If you want a meta-framework for PowerShell dispatch, look elsewhere. If you want a **working dev shell that stays honest**, you're in the right place.

---

## Platform stability

Execution architecture is **LOCKED at spec v1.0.0**. Product releases (like `v2.0.0`) ship features and fixes without silently redesigning the core.

Details: [docs/platform-spec-summary.md](docs/platform-spec-summary.md)

---

## Requirements

- Windows 10/11  
- [PowerShell 7+](https://aka.ms/powershell)  
- Git (for remote install clone)  
- Optional: Windows Terminal, Git, Python (checked by `doctor`)

---

## Repository map

| Path | What |
|------|------|
| `install.ps1` · `devshell.ps1` | Product entry points |
| `profile/` · `lib/` · `modules/` | Shipped runtime |
| `docs/` | Guides + platform spec |
| `Validate-Workstation.ps1` | Health gate used by `devshell doctor` |

Maintainer docs: [docs/product/GITHUB-RELEASE-PLAN.md](docs/product/GITHUB-RELEASE-PLAN.md)

---

## Contributing & license

Issues and PRs welcome. Keep platform changes behind the [spec unlock process](docs/charter/PLATFORM-SPEC-SIGNOFF.md).

**License:** [MIT](LICENSE) · Russian docs: [docs/ru/README.md](docs/ru/README.md)
