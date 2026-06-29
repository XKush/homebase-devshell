# HomeBase DevShell

🌍 **Language:** English | [Русский](README.ru.md)

**Stop guessing if your dev environment is broken. Run one command — know instantly.**

A clean PowerShell environment for Windows that tells you in seconds if your machine is ready to work.

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

```powershell
irm https://raw.githubusercontent.com/XKush/homebase-devshell/v2.0.0/install.ps1 | iex
```

Restart your terminal, then run **`devshell doctor`**. When you see **Ready to work**, you're good.

---

## Why this matters

Your shell can be broken — and you won't know until something fails mid-task.

Broken paths, missing tools, a profile that loads too slow, config that drifted since last week. It all looks fine until it isn't.

**`devshell doctor`** catches that drift *before* it breaks your day: one pass/fail check so you trust the environment before you write code.

---

## The proof moment

```powershell
devshell doctor
```

When everything is healthy:

```
✔ Profile OK
✔ Tools OK
✔ Environment OK
✔ Ready to work

Profile load: 489ms
Passed: 71 · Failed: 0
```

No guesswork. No "probably fine." You know.

<details>
<summary>Full report (when you need details)</summary>

```
═══════════════════ VALIDATION REPORT ═══════════════════
Passed:   71
Failed:   0
Warnings: 0
Profile load: 489ms <= 600ms
Report: C:\Logs\Workstation\validation-20260629-030000.json
═══════════════════════════════════════════════════════
```

If **`Failed` > 0**, open the JSON report, fix what's listed, run `devshell doctor` again.

</details>

---

## Quick start (60 seconds)

**1. Install**

```powershell
irm https://raw.githubusercontent.com/XKush/homebase-devshell/v2.0.0/install.ps1 | iex
```

**2. Restart** Windows Terminal (or open a new PowerShell 7 window).

**3. Verify**

```powershell
pwsh -File $HOME\.homebase\devshell\devshell.ps1 doctor
```

**4. Check status**

```powershell
pwsh -File $HOME\.homebase\devshell\devshell.ps1 status
```

**Optional — add a short alias for daily use:**

```powershell
function devshell { pwsh -NoProfile -File "$HOME\.homebase\devshell\devshell.ps1" @args }
```

Then: `devshell install` · `devshell doctor` · `devshell status` — that's the whole product surface.

---

## Core commands

Three commands. Nothing else required.

| Command | What it does |
|---------|----------------|
| **`devshell install`** | Sets up folders, deploys your PowerShell profile, runs baseline setup |
| **`devshell doctor`** | Health check — catches broken shell, paths, and tools before you work |
| **`devshell status`** | Confirms version and that the environment loaded correctly |

```powershell
devshell install
devshell doctor
devshell status
```

Without the alias:

```powershell
pwsh -File $HOME\.homebase\devshell\devshell.ps1 doctor
```

---

## Real use cases

**New Windows machine**  
Install → doctor → start working. Know the shell is wired before you clone anything.

**"Something feels off"**  
Your environment might be broken and you don't know it yet. Doctor finds drift in one run.

**Second PC or reinstall**  
Same install URL, same pass/fail gate — less "works on my machine."

**Daily driver**  
Fast profile with `home`, `go`, and shortcuts — without hand-maintaining a 500-line `$PROFILE`.

---

## If something fails

See [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) or the quick fixes below.

| Problem | What to do |
|---------|------------|
| Install says **PowerShell 7+ required** | Install from [aka.ms/powershell](https://aka.ms/powershell), reopen terminal |
| **git not found** during remote install | Install [Git for Windows](https://git-scm.com/download/win), retry the install line |
| **`devshell doctor` fails** | Read `C:\Logs\Workstation\validation-*.json`, fix listed items, re-run doctor |
| **Commands not found after install** | Restart terminal; use full path or add the `devshell` alias above |
| **Re-run setup safely** | `devshell install` is idempotent — run it again after fixes |

---

## Requirements

- Windows 10 or 11  
- [PowerShell 7+](https://aka.ms/powershell)  
- Git (for the one-line remote install)  
- Optional: Windows Terminal, Python (checked by doctor)

---

## What this is **not**

- Not a cloud service — everything runs locally  
- Not a framework you must learn before doing work  
- Not Linux/macOS (Windows + PowerShell 7 only)  

Minimal surface. Honest health check. If that's what you need, you're in the right place.

---

## More

- [Getting started](docs/GETTING-STARTED.md) · [Troubleshooting](docs/TROUBLESHOOTING.md) · [Contributing](CONTRIBUTING.md)  
- [CHANGELOG](CHANGELOG.md) · [License MIT](LICENSE) · [Русский](README.ru.md)
