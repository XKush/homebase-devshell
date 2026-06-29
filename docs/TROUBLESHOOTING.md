# Troubleshooting

## Install didn't work

| Message | What to do |
|---------|------------|
| Need PowerShell 7 | Install from [aka.ms/powershell](https://aka.ms/powershell), try again |
| git not found | Install [Git for Windows](https://git-scm.com/download/win), try again |

## Doctor didn't say "Ready to work"

1. Run install again  
2. Run doctor again  
3. Still stuck? Open the log file doctor mentions and fix what's listed  

```powershell
pwsh -File $HOME\.homebase\devshell\devshell.ps1 install
pwsh -File $HOME\.homebase\devshell\devshell.ps1 doctor
```

## "Command not found"

Close terminal completely. Open a new one. Paste the full command from the [README](../README.md).

## Optional: short `devshell` shortcut

Only if you want fewer keystrokes later:

```powershell
function devshell { pwsh -NoProfile -File "$HOME\.homebase\devshell\devshell.ps1" @args }
```

## Still stuck?

[Open an issue](https://github.com/XKush/homebase-devshell/issues)
