# HomeBase DevShell

🌍 **Language:** English | [Русский](README.ru.md)

**Your dev environment might be broken. You just don't know it yet.**

**One install. One check. Instant answer.**

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

```powershell
irm https://raw.githubusercontent.com/XKush/homebase-devshell/v2.0.0/install.ps1 | iex
```

Restart terminal → run **`devshell doctor`** → see **Ready to work**.

---

## Why this exists

- **Broken setups hide in plain sight** — bad paths, missing tools, slow profiles  
- **Onboarding eats your day** — new machine, new job, new reinstall  
- **You can't trust what you can't verify** — "probably fine" isn't a strategy  
- **Drift kills productivity** — config changes silently until something breaks  

HomeBase DevShell fixes one thing: **know if you're ready to work — in seconds.**

---

## See it work (3 seconds)

```powershell
devshell doctor
```

```
✔ Profile OK
✔ Tools OK
✔ Environment OK
✔ Ready to work

Passed: 71 · Failed: 0 · Profile: 489ms
```

That's it. No guesswork.

---

## Three commands. That's the product.

```powershell
devshell install   # set up (safe to re-run)
devshell doctor    # pass or fail — are you ready?
devshell status    # quick sanity check
```

| Command | One line |
|---------|----------|
| **`devshell install`** | Deploy profile + baseline setup |
| **`devshell doctor`** | Full health check before you code |
| **`devshell status`** | Version + load state |

<details>
<summary>Without alias (copy once after install)</summary>

```powershell
function devshell { pwsh -NoProfile -File "$HOME\.homebase\devshell\devshell.ps1" @args }
```

</details>

---

## Use it when

**New machine** — install → doctor → start coding  
**Something feels wrong** — one command finds what's broken  
**Every morning** — 5-second readiness check before deep work  

---

## Trust

- **Fail-safe install** — setup runs `doctor` automatically; no silent "success"  
- **Idempotent** — run `devshell install` again anytime after fixes  
- **No admin by default** — product install skips privileged system changes  
- **Local only** — nothing leaves your machine  
- **Clear reports** — failures write to `C:\Logs\Workstation\validation-*.json`  

---

## What this is **not**

- ❌ Not a framework to learn before you work  
- ❌ Not a shell replacement (it's PowerShell 7, enhanced)  
- ❌ Not a dev platform / plugin ecosystem  
- ❌ Not Linux or macOS  

Just: **install → doctor → work.**

---

## Quick start

```powershell
# 1 — install
irm https://raw.githubusercontent.com/XKush/homebase-devshell/v2.0.0/install.ps1 | iex

# 2 — new terminal, then verify
devshell doctor
devshell status
```

**Needs:** Windows 10/11 · [PowerShell 7+](https://aka.ms/powershell) · Git  

**Stuck?** [Troubleshooting](docs/TROUBLESHOOTING.md) · [Contributing](CONTRIBUTING.md)
