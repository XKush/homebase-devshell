# Brand — DevReady × HomeBase DevShell

## Names (use consistently)

| Name | Role | Where |
|------|------|--------|
| **DevReady** | Public, clickable, shareable | README title, social, `devready` command |
| **HomeBase DevShell** | Product / repo / technical | GitHub repo, `devshell` CLI, module metadata |
| **devshell doctor** | Verb developers remember | Docs, scripts, CI |
| **devready** | Shortest path to the check | PATH shim after install |

### Taglines

- **EN:** *Is your Windows dev box ready? One command to find out.*
- **RU:** *Готов ли Windows к разработке? Одна команда — и вы знаете.*

### One-liner for GitHub / social

> **DevReady** — Windows dev environment health check. Install. Run `devready`. Code.

---

## What to share

**Install (copy-paste):**

```powershell
irm https://raw.githubusercontent.com/XKush/homebase-devshell/v2.2.2/install.ps1 | iex
```

**Daily check:**

```powershell
devready
```

Hashtags (optional): `#DevReady` `#PowerShell` `#WindowsDev` `#dotfiles`

---

## Logo / visuals

No official logo yet. Use text lockup:

```
DevReady
────────
HomeBase DevShell
```

Badge colors: PowerShell blue `#5391FE`, success green for "Ready to work".

### GitHub social preview (1200×630)

Asset: [`.github/social-preview.png`](../../.github/social-preview.png)

Set once in **Settings → General → Social preview** when preparing a release. Not required for install or doctor.

---

## What we do not call it

- ~~ReviOS Professional Workstation~~ (legacy, removed from install banner)
- ~~KGreen Workstation~~ (internal module name only)
- ~~framework~~ / ~~platform you must learn~~ — it's a **utility**: install → check → work

---

## Tiers (messaging)

| Message | Audience |
|---------|----------|
| "Core passes from zero" | OSS / GitHub visitors |
| "Full workstation" | Power users who installed winget stack |
| "Security pack opt-in" | Tor/PGP — never the first sentence in README |

---

## Repo display name (GitHub)

- **Repository:** `homebase-devshell` (URL stable)
- **Description:** `DevReady — Windows dev environment health check for PowerShell 7. One-line install, devready tells you if you're set up.`
- **Topics:** keep existing + `devready`, `health-check`, `developer-experience`
