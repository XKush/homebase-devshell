# HomeBase DevShell — OSS Adoption Guide

**Audience:** maintainers · **Layer:** public OSS growth only (no runtime changes)

---

## Messaging

### One-liner (non-technical)

> Install a fast PowerShell dev shell on Windows and know it's healthy before you start working.

### Elevator pitch (2 sentences)

HomeBase DevShell gives Windows developers a one-line install and a single health command — `devshell doctor` — so you stop guessing whether your profile, paths, and tools are actually ready. It's a practical daily shell, not a framework you have to study first.

### Target audience

| **For** | **Not for** |
|---------|-------------|
| Windows developers using PowerShell 7 daily | People who want cross-platform shell managers |
| Anyone tired of slow or broken `$PROFILE` setups | Architects looking for a dispatch/orchestration framework |
| New machine / reinstall / "is my env OK?" workflows | Teams needing centralized cloud provisioning |
| Solo devs who want pass/fail validation | Users who never open a terminal |

---

## GitHub landing metadata

### Repository short description (GitHub "About")

```
Fast, self-checking PowerShell 7 dev shell for Windows — one-line install, devshell doctor health gate.
```

**Character count:** ~95 (fits GitHub About field)

### Suggested topics (GitHub SEO)

```
powershell
powershell-core
pwsh
windows
dev-environment
developer-tools
shell
dotfiles
windows-terminal
cli
open-source
productivity
```

**Apply via CLI:**

```powershell
gh repo edit XKush/homebase-devshell `
  --description "Fast, self-checking PowerShell 7 dev shell for Windows — one-line install, devshell doctor health gate." `
  --add-topic powershell --add-topic powershell-core --add-topic pwsh `
  --add-topic windows --add-topic dev-environment --add-topic developer-tools `
  --add-topic shell --add-topic dotfiles --add-topic windows-terminal `
  --add-topic cli --add-topic open-source --add-topic productivity
```

### Pinned structure (recommended)

| Pin | Content |
|-----|---------|
| **README** | Default — already optimized for first visitors |
| **Release v2.0.0** | Pin latest stable so install URL and notes are one click away |
| **Discussion: Getting started** | Optional — "Install → doctor → status" thread with FAQ |
| **Issue template** | Bug vs install-help vs feature (avoid platform-internals in titles) |

**Do not pin:** charter docs, baseline JSON, hardening reports, Wave migration notes.

---

## First-time user experience flow

```
User runs install one-liner
        │
        ▼
install.ps1 clones repo → %USERPROFILE%\.homebase\devshell
        │
        ▼
Install-Workstation.ps1 (folders + profile, user scope, no admin/software by default)
        │
        ▼
devshell doctor (Validate-Workstation, 600ms profile budget)
        │
        ├── PASS → "SUCCESS: HomeBase DevShell is ready."
        │            User restarts terminal
        │            First command: devshell status (or doctor again)
        │
        └── FAIL → JSON report in C:\Logs\Workstation\
                     User fixes items → devshell doctor again
```

### Step-by-step (what the user sees)

1. **Install script header** — `HomeBase DevShell v2.0.0 — install`
2. **Clone** (if remote) — `Cloning repository to C:\Users\you\.homebase\devshell ...`
3. **Bootstrap** — `==> Bootstrap (folders + profile, user scope)`
4. **Health check** — `==> Health check (devshell doctor)` + validation report
5. **Success path** — green `SUCCESS`, prompts to restart terminal and run `status`
6. **New session** — profile loads; `home`, `go`, module `doctor` available in-shell

### First command after restart

**Recommended:** `devshell status` — confirms product version and runtime loaded OK.

**Trust gate:** `devshell doctor` — run again anytime after changes or when something feels wrong.

### Expected `devshell doctor` output (healthy machine)

- `Failed: 0`
- `Profile load: …ms <= 600ms`
- Exit code `0`
- Report path under `C:\Logs\Workstation\validation-*.json`

### Recovery playbook

| Symptom | Action |
|---------|--------|
| Doctor fails on paths | Open JSON report → fix missing dirs/tools → `devshell install` → `devshell doctor` |
| Profile slow | Doctor shows load ms; check warnings in report |
| Wrong repo root | Set `$env:HOMEBASE_DEVSHELL_ROOT` to checkout, re-run install |
| Broken profile after edit | `devshell install -Force` equivalent via full install script from repo root |
| Still stuck | Open GitHub Issue with doctor JSON (redact paths if needed) |

---

## Internal vs public mental model boundary

### Show to normal users (README, release notes, Discussions)

- One-line install URL  
- Three commands: `install`, `doctor`, `status`  
- Doctor pass/fail + log path  
- Real use cases (new PC, slow profile, team consistency)  
- Requirements and recovery table  
- "What this is not"  

### Hide from README (keep in `docs/` for contributors)

| Internal concept | Public replacement |
|------------------|-------------------|
| Wave A–D stack | "shipped runtime" / "profile + modules" |
| Orchestrator, Registry, Router | *(omit)* |
| Event Core, lifecycle events | *(omit)* |
| Platform spec LOCK v1.0.0 | "stable core" or link in Advanced section only |
| Extension registry / bridge | "extensions" in CONTRIBUTING only |
| Hardening gate 11/11 | CI/maintainer docs |
| Baseline JSON artifacts | `internal-docs/baselines/` only |
| Charter sign-off process | `internal-docs/charter/` only |

### Never show to normal users

- `$script:WorkstationCommandRegistry` and sibling registries  
- Dispatch architecture diagrams (A→B→C→D)  
- Event contract names (`command.execute.*`, etc.)  
- Internal migration WIP (MenuSystem, Tor ops, sandbox)  
- Operator-only scripts as primary story  
- "Framework" / "platform" positioning in hero copy  

### Rule of thumb

**Public layer answers:** *What do I run? Does it work? How do I fix it?*  
**Internal layer answers:** *How is it wired? Who can change the core?*

If copy mentions a noun the user cannot run as a command, it probably belongs in `docs/`, not the README hero.

---

## README change log (this pass)

- OSS-first rewrite: outcomes over architecture  
- Install block moved to top  
- Three core commands as sole primary entry  
- Added use cases, failure recovery, first-run clarity  
- Removed platform lock / spec / repository map from main flow  
- Optional commands relegated to Advanced footer  

**Runtime:** unchanged · **Architecture lock v1.0.0:** unchanged
