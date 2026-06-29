# DevReady

**HomeBase DevShell** prepares, verifies and maintains professional Windows workstations.

A workstation **readiness and privacy configuration auditing toolkit** for Windows developers and security professionals. PowerShell 7 · local only · no cloud.

🌍 **English** · [Русский](README.ru.md)

[![CI](https://github.com/XKush/homebase-devshell/actions/workflows/ci.yml/badge.svg)](https://github.com/XKush/homebase-devshell/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![PowerShell 7](https://img.shields.io/badge/PowerShell-7+-5391FE?logo=powershell&logoColor=white)](https://aka.ms/powershell)
[![Windows](https://img.shields.io/badge/Windows-10%20%7C%2011-0078D6?logo=windows&logoColor=white)](https://github.com/XKush/homebase-devshell)
[![Release](https://img.shields.io/github/v/release/XKush/homebase-devshell?label=release)](https://github.com/XKush/homebase-devshell/releases/latest)

![DevReady — install, devshell health, Ready to work](docs/assets/devready-demo.gif)

**Inspect before run:** [`install.ps1` @ v3.0.0](https://github.com/XKush/homebase-devshell/blob/v3.0.0/install.ps1) · `devshell init` (dry-run, no changes) · [zip + SHA256](packaging/README.md)

---

## 30-second start

```powershell
irm https://raw.githubusercontent.com/XKush/homebase-devshell/v3.0.0/install.ps1 | iex
```

Close the terminal. Open a new one. Run:

```powershell
devshell health
```

Unified dashboard: Developer · Privacy Configuration · Browser · Network → **Ready to work.**

Or the classic developer check:

```powershell
devready
```

<details>
<summary>Three commands (all you need at first)</summary>

| Command | When |
|---------|------|
| **`devshell health`** | Unified dashboard + `-Json` for CI |
| **`devready`** | Developer readiness only (same as `doctor`) |
| **`devshell install`** | First-time setup (Core) |

</details>

<details>
<summary>More commands (optional)</summary>

```powershell
devshell init          # dry-run plan (no winget, no file changes)
devshell doctor -Tier Full   # all tools + security audits (~75 checks)
devshell install -WithTools    # winget stack (oh-my-posh, fzf, …)
devshell status
```

</details>

<details>
<summary>After PASS — command center (power users)</summary>

Menus, cockpit, and 100+ helpers: [Command center (EN)](docs/en/COMMAND-CENTER.md) · [RU](docs/ru/COMMAND-CENTER.md)

Not required for Core DevReady.

</details>

---

## Why DevReady exists

| Problem | DevReady answer |
|---------|-----------------|
| Broken PATH, missing git, dead profile — silent until 2am | **`devshell health`** surfaces it in seconds |
| New laptop / reinstall | One install line, one **`health`** check |
| Privacy/OS config drift before sensitive work | Dashboard + **`baseline`** / **`verify`** |

Everything runs **on your PC only**. Nothing is uploaded.

---

## What you get

**Level 0 — DevReady (start here)**

| Command | What it does |
|---------|----------------|
| **`devshell health`** | Unified dashboard → **Ready to work** or fix hints; `-Json` for CI |
| **`devready`** | Developer checks only (subset of health) |
| **`devshell install`** | Core bootstrap (profile, folders) — add `-WithTools` for winget stack |
| **`devshell baseline`** / **`verify`** | Save and compare configuration baseline |

Command center (`home`, `go`, menus) lives in [docs](docs/en/COMMAND-CENTER.md) — **after** you pass Core.

### Doctor tiers

| Tier | When | Checks |
|------|------|--------|
| **Core** (default OSS) | After `install.ps1` | pwsh, git, profile, module, command-health |
| **Full** | Power user / your daily driver | ~75 checks — oh-my-posh, fzf, eza, menus, Tor/PGP opt-in |

```powershell
devshell doctor -Tier Full
```

---

## Repository map

```
homebase-devshell/
├── install.ps1          ← one-line bootstrap (irm | iex)
├── devshell.ps1         ← product CLI
├── README.md            ← you are here
├── CHANGELOG.md         ← release history
│
├── docs/                ← user guides (start → troubleshoot)
├── examples/minimal/    ← fork without security pack
├── Config/              ← path defaults (patched on install)
├── profile/             ← canonical PowerShell profile
├── modules/             ← command center (144 commands, opt-in depth)
├── lib/                 ← platform runtime (spec 1.0.0 LOCKED)
│
├── scripts/maintainer/  ← install chain, CI gates (not for first run)
├── Test-*Audit.ps1      ← menu/security CI audits
└── internal-docs/       ← charter & ADR (contributors only)
```

Full layout: [docs/product/REPOSITORY-SURFACE.md](docs/product/REPOSITORY-SURFACE.md)

---

## Docs

| Doc | For |
|-----|-----|
| [Getting started](docs/GETTING-STARTED.md) | Paths, install flow, diagram |
| [Roadmap](docs/ROADMAP.md) | v3.x contract — what we ship and what we defer |
| [Project principles](docs/PROJECT-PRINCIPLES.md) | Engineering guardrails |
| [Manifesto](docs/MANIFESTO.md) | Why we exist · what we never do |
| [Troubleshooting](docs/TROUBLESHOOTING.md) | When doctor fails |
| [Privacy](docs/PRIVACY.md) | Privacy configuration module |
| [API stability](docs/API-STABILITY.md) | Frozen CLI contract (v3+) |
| [JSON schemas](docs/JSON-SCHEMA.md) | Report compatibility policy |
| [Start here (Discussion)](https://github.com/XKush/homebase-devshell/discussions/5) | Welcome guide for new users |
| [ADR](docs/adr/) | Architecture decisions |
| [Command center (EN)](docs/en/COMMAND-CENTER.md) | `go`, `home`, tiers |
| [Command center (RU)](docs/ru/COMMAND-CENTER.md) | Russian cockpit |
| [Brand & naming](docs/product/BRAND.md) | DevReady vs HomeBase DevShell |

---

## Safe by default

- **User scope** — default install skips admin prompts  
- **Idempotent** — run `install` again; it won't make things worse  
- **Defender** — this suite never enables Microsoft Defender AV  
- **Privacy pack** (Tor/PGP) — opt-in via `sec` menu, not required for Core  

---

## Not for you if

- You need macOS/Linux dotfiles (this is Windows + pwsh 7)  
- You want a framework to study for a week before using it  
- You expect a hosted SaaS dashboard  

---

## For contributors

[CONTRIBUTING.md](CONTRIBUTING.md) · [Good first PR (~15 min)](docs/GOOD-FIRST-CONTRIBUTION.md) · [Discussions — Start here](https://github.com/XKush/homebase-devshell/discussions/5) · [SECURITY.md](SECURITY.md) · [scripts/README.md](scripts/README.md)

Platform execution architecture is **locked at spec v1.0.0** — product/UX/docs/CI changes welcome; orchestrator changes need maintainer sign-off.

---

**Share the one-liner:** `irm …/install.ps1 | iex` then **`devshell health`**

[⭐ Star on GitHub](https://github.com/XKush/homebase-devshell) if it saved you an hour of debugging.
