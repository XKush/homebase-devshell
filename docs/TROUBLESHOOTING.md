# Troubleshooting

## Install fails

| Message | Fix |
|---------|-----|
| PowerShell 7+ required | Install from [aka.ms/powershell](https://aka.ms/powershell), reopen terminal |
| git not found | Install [Git for Windows](https://git-scm.com/download/win), retry install line |
| Clone failed | Clone manually: `git clone https://github.com/XKush/homebase-devshell.git $HOME\.homebase\devshell` then `pwsh -File install.ps1` from that folder |

## `devshell doctor` fails

1. Note the report path: `C:\Logs\Workstation\validation-*.json`  
2. Open the JSON and fix listed failures (missing folders, tools, slow profile)  
3. Run `devshell install`, then `devshell doctor` again  

Exit code `0` and **`Failed: 0`** mean you are ready.

## Commands not found

- Restart the terminal after install  
- Use full path: `pwsh -File $HOME\.homebase\devshell\devshell.ps1 doctor`  
- Or add the `devshell` alias from [GETTING-STARTED.md](GETTING-STARTED.md)

## Wrong repository root

Set `$env:HOMEBASE_DEVSHELL_ROOT` to your checkout path and re-run `install.ps1`.

## Still stuck?

Open a [GitHub Issue](https://github.com/XKush/homebase-devshell/issues) with your doctor JSON (redact usernames/paths if you prefer).
