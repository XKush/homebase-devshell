# Troubleshooting

## Install didn't work

| Message | What to do |
|---------|------------|
| Need PowerShell 7 | Install from [aka.ms/powershell](https://aka.ms/powershell), try again |
| git not found | Install [Git for Windows](https://git-scm.com/download/win), try again |

## Doctor didn't say "Ready to work"

`devready` ends with **Ready to work.** (green) or **Not ready yet.** with **Try this:** hints.

1. Run **`devshell doctor -Fix`** (or `devready -Fix` if shims work) — installs/repairs from winget + PSGallery  
2. Follow the **Try this:** hints, then run `devready` again  
3. Or run `devshell install` and open a **new** terminal  
4. Still stuck? See failed lines above or the JSON report path in the output  

```powershell
pwsh -File $HOME\.homebase\devshell\devshell.ps1 doctor -Fix
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
