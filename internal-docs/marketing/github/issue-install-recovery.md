## Install didn't work? Start here

Most failures are fixable in **2–5 minutes**. Use this checklist before opening a new issue.

### 1. Prerequisites

| Check | Command / action |
|-------|------------------|
| PowerShell **7+** | `$PSVersionTable.PSVersion` — must be 7.x |
| **Git** installed | `git --version` |
| Execution policy | `Set-ExecutionPolicy RemoteSigned -Scope CurrentUser` |

### 2. Run install again (safe)

```powershell
irm https://raw.githubusercontent.com/XKush/homebase-devshell/v2.1.1/install.ps1 | iex
```

Then **close terminal → open new terminal**.

### 3. Run doctor manually

```powershell
pwsh -File $HOME\.homebase\devshell\devshell.ps1 doctor
```

### 4. Common failures

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| `irm` blocked | Execution policy | RemoteSigned (CurrentUser) |
| PS 5 errors | Wrong shell | Install PS7: https://aka.ms/powershell |
| `git clone failed` | No git / network | Install Git, retry |
| Doctor FAIL on tools | winget tool missing | Optional — see [Troubleshooting](https://github.com/XKush/homebase-devshell/blob/main/docs/TROUBLESHOOTING.md) |
| Profile not loaded | Old terminal session | Close all terminals, open new pwsh |

### 5. Logs (if needed)

Default logs folder: `C:\Logs\Workstation\` (or path from your install config)

### 6. Still stuck?

Reply here with:

- Windows version
- `$PSVersionTable.PSVersion`
- Exact command you ran
- Last 20 lines of output (no secrets)

Or use **New issue → Install or doctor help** for structured form.
