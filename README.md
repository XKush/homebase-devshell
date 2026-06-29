# HomeBase DevShell

🌍 **Language:** English | [Русский](README.ru.md)

**Is your setup ready to work?**

**Install. Check. Done.**

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

```powershell
irm https://raw.githubusercontent.com/XKush/homebase-devshell/v2.0.6/install.ps1 | iex
```

Close terminal. Open it again. Run:

```powershell
pwsh -File $HOME\.homebase\devshell\devshell.ps1 doctor
```

See **Ready to work**? You're done.

---

## Why

- Your setup can be broken without you noticing  
- New PC or reinstall shouldn't mean guessing for an hour  
- You shouldn't start coding until you know things work  

---

## What you'll see

```
✔ Profile OK
✔ Tools OK
✔ Environment OK
✔ Ready to work
```

Green checkmarks = go. Anything else = not ready yet.

---

## Three buttons (that's all)

| | |
|---|---|
| **install** | First-time setup |
| **doctor** | Am I ready to work? |
| **status** | Did everything load? (optional) |

Same commands, anytime:

```powershell
pwsh -File $HOME\.homebase\devshell\devshell.ps1 install
pwsh -File $HOME\.homebase\devshell\devshell.ps1 doctor
pwsh -File $HOME\.homebase\devshell\devshell.ps1 status
```

No config. No setup wizard. Copy, run, read the answer.

---

## When to use it

- **New Windows PC** — before your first commit  
- **Something broke** — one check instead of guessing  
- **Start of the day** — 10 seconds, peace of mind  

---

## Safe by default

- Runs on **your PC only** — nothing uploaded  
- **No admin prompts** in the default install  
- **Run install again** if something failed — it won't make things worse  

---

## Not for you if

- You want a big framework to learn first  
- You're not on Windows + PowerShell 7  
- You want a replacement for bash/zsh on Mac/Linux  

---

**Need help?** [Troubleshooting](docs/TROUBLESHOOTING.md) · Windows 10/11 · [PowerShell 7](https://aka.ms/powershell) · Git
