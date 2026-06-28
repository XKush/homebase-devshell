# KGreen Workstation Cheatsheet

## First steps
```powershell
help              # Interactive command guide
cheatsheet        # This file (in terminal)
devinfo           # Your dev environment summary
doctor            # Health check (52+ tests)
new-project myapp # New folder + git in C:\Projects
```

## Daily workflow
```powershell
projects          # Go to C:\Projects
mkcd my-app       # Create and enter folder
git init -b main  # Start git repo
New-Venv          # Python virtual environment
code .            # Open VS Code
```

## Git
| Command | Meaning |
|---------|---------|
| `gs` | Status |
| `ga .` | Stage all |
| `gc -m "msg"` | Commit |
| `gp` | Push |
| `gl` | Pull |
| `gd` | Diff |
| `glog` | Log graph |

## Files
| Command | Meaning |
|---------|---------|
| `ll` | Detailed list with icons |
| `lt` | Tree view |
| `cat file.py` | View with syntax highlight |
| `z folder` | Jump to directory (learns paths) |

## Maintenance
| Command | Meaning |
|---------|---------|
| `updateall` | winget + PS module updates |
| `backupconfig` | Snapshot settings |
| `repairterminal` | Fix profile + terminal |
| `cleanlogs` | Safe log/backup rotation |
| `doctor` | Full validation |

## Paths
| Path | Purpose |
|------|---------|
| `C:\Projects` | Your code |
| `C:\Scripts\Workstation` | Setup scripts |
| `C:\Tools` | Portable tools |
| `C:\Logs` | Logs |
| `C:\Backups` | Config backups |

## Python
```powershell
python script.py
pip install requests
Enter-Venv        # activate .venv
```

## Networking (authorized use only)
```powershell
Test-FirewallStatus
Show-ListeningPorts
ping / Test-NetConnection
nmap -sn 192.168.1.0/24   # only on networks you own
```

## Recovery
```powershell
backupconfig
# Restore (admin):
Start-Process pwsh -Verb RunAs -ArgumentList '-File C:\Scripts\Workstation\Rollback-Workstation.ps1 -Force'
```

## Owner
**KGreen** — customize git email: `git config --global user.email "you@example.com"`
