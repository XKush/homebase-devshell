# Minimal fork example

A stripped-down HomeBase DevShell layout without Tor/PGP security pack wiring.

## What to remove or skip

| Area | Full install | Minimal |
|------|--------------|---------|
| `Install-Software.ps1` | winget: oh-my-posh, fzf, eza, … | `-SkipTools` / `install.ps1 -SkipTools` |
| Doctor tier | `Full` (75 checks) | `Core` only |
| Security commands | `sec`, `tor-*`, `pgp-*` | Do not load `lib/AnonymityKit.ps1` extensions |
| `WORKSTATION_LANG` | `en` (OSS default) | set as needed |

## Bootstrap

```powershell
git clone https://github.com/XKush/homebase-devshell.git my-devshell
cd my-devshell
pwsh -File install.ps1 -SkipTools
```

After install:

```powershell
devshell doctor          # Core tier — should pass with pwsh + git + profile only
devshell doctor -Tier Full   # optional — will fail until you install extra tools
```

## Custom paths

Edit `Config/homebase.defaults.json` before install, or set `WORKSTATION_ROOT` to your checkout.
Runtime logs still default to `C:\Logs\Workstation` unless you override `LogsRoot` in the same config file.

## Security pack (opt-in)

Keep Tor/PGP isolated: use `sec` menu only when `C:\Security` and toolkit deps exist.
See [docs/ru/TOR-MAX-SECURITY.md](../../docs/ru/TOR-MAX-SECURITY.md) for the full security workflow.
