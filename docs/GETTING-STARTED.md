# Getting started

Everything you need is in the [README](../README.md). This page is a short checklist.

## Install

```powershell
irm https://raw.githubusercontent.com/XKush/homebase-devshell/v2.0.0/install.ps1 | iex
```

## After install

1. Restart Windows Terminal  
2. Run **`devshell doctor`** — must show `Failed: 0`  
3. Run **`devshell status`** — confirms the environment loaded  

## Daily commands

| Command | When |
|---------|------|
| `devshell doctor` | After changes, new tools, or when something feels wrong |
| `devshell status` | Quick sanity check |
| `devshell install` | Re-run setup safely (idempotent) |

## Alias (optional)

```powershell
function devshell { pwsh -NoProfile -File "$HOME\.homebase\devshell\devshell.ps1" @args }
```

## More help

- [Troubleshooting](TROUBLESHOOTING.md)  
- [Русский README](../README.ru.md)
