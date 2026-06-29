# Command center (EN)

> **Product:** [README.md](../../README.md) · **Russian:** [docs/ru/COMMAND-CENTER.md](../ru/COMMAND-CENTER.md)

Navigation after installing HomeBase DevShell.

## Navigation

| Command | What it does |
|---------|----------------|
| `go` / **Ctrl+Alt+G** | Two-level menu: **[next]** from home → categories → Enter = action |
| `menu` / `palette` | Same as `go` |
| `sec` / **Ctrl+Alt+S** | Tor + PGP only |
| **Ctrl+Alt+K** | `komandy` — command catalog |
| **Ctrl+Alt+B** | `home` — cockpit overview |

**Enter** = run · **Esc** = back · **Ctrl+/** = help

## Quick start (after install)

1. `devshell doctor` — environment ready (Core tier)
2. `home` — cockpit overview
3. `go` — action menu

## Tiers

| Tier | Command | Checks |
|------|---------|--------|
| Core (default OSS) | `devshell doctor` | pwsh, git, profile, module, command-health |
| Full workstation | `devshell doctor -Tier Full` | All tools, menus, security audits (~75 checks) |

## More

| Topic | File |
|-------|------|
| All commands | [docs/ru/COMMANDS.md](../ru/COMMANDS.md) |
| Quick reference | [docs/ru/QUICKREF.md](../ru/QUICKREF.md) |
| Trust | [docs/ru/TRUST.md](../ru/TRUST.md) |
| Tor / PGP (opt-in) | [docs/ru/TOR-MAX-SECURITY.md](../ru/TOR-MAX-SECURITY.md) |
