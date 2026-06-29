# DevReady

**Is your Windows dev box ready? One command to find out.**

Powered by **HomeBase DevShell** — a local health check for PowerShell 7 on Windows. No cloud. No admin. No guesswork.

🌍 **English** · [Русский](README.ru.md)

[![CI](https://github.com/XKush/homebase-devshell/actions/workflows/ci.yml/badge.svg)](https://github.com/XKush/homebase-devshell/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![PowerShell 7](https://img.shields.io/badge/PowerShell-7+-5391FE?logo=powershell&logoColor=white)](https://aka.ms/powershell)
[![Windows](https://img.shields.io/badge/Windows-10%20%7C%2011-0078D6?logo=windows&logoColor=white)](https://github.com/XKush/homebase-devshell)
[![Release](https://img.shields.io/github/v/release/XKush/homebase-devshell?label=release)](https://github.com/XKush/homebase-devshell/releases/latest)

---

## 30-second start

```powershell
irm https://raw.githubusercontent.com/XKush/homebase-devshell/v2.1.0/install.ps1 | iex
```

Close the terminal. Open a new one. Run:

```powershell
devready
```

See **`Ready to work`**? Start coding. Anything else — fix what it shows, run again.

<details>
<summary>Prefer the full CLI name?</summary>

```powershell
devshell doctor          # same check (Core tier)
devshell doctor -Tier Full   # all tools + security audits
devshell install
devshell status
```

</details>

---

## Why DevReady exists

| Problem | DevReady answer |
|---------|-----------------|
| Broken PATH, missing git, dead profile — silent until 2am | **`devready`** surfaces it in seconds |
| New laptop / reinstall | One install line, one check |
| "Works on my machine" before the first commit | Green = go. Not green = not yet. |

Everything runs **on your PC only**. Nothing is uploaded.

---

## What you get

### Public surface (what strangers need)

| Command | What it does |
|---------|----------------|
| **`devready`** | Shortcut → health check (Core tier) |
| **`devshell install`** | First-time bootstrap (profile + optional tools) |
| **`devshell doctor`** | Am I ready? `-Tier Core` or `-Tier Full` |
| **`devshell status`** | Did the platform load? |

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
| [Troubleshooting](docs/TROUBLESHOOTING.md) | When doctor fails |
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

[CONTRIBUTING.md](CONTRIBUTING.md) · [SECURITY.md](SECURITY.md) · [scripts/README.md](scripts/README.md)

Platform execution architecture is **locked at spec v1.0.0** — product/UX/docs/CI changes welcome; orchestrator changes need maintainer sign-off.

---

**Share the one-liner:** `irm …/install.ps1 | iex` then **`devready`**

[⭐ Star on GitHub](https://github.com/XKush/homebase-devshell) if it saved you an hour of debugging.
