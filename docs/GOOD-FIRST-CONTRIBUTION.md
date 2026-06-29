# Good first contribution (15–20 minutes)

Goal: merge a small, useful PR without touching the locked platform stack.

## Fastest paths

| Task | Time | Files |
|------|------|-------|
| Fix typo / clarify README | 10 min | `README.md`, `README.ru.md`, `docs/*.md` |
| Add troubleshooting entry | 15 min | `docs/TROUBLESHOOTING.md` |
| Improve error message | 15 min | `scripts/maintainer/install/Validate-Workstation.ps1` (user-facing strings only) |
| Extend smoke assertion | 20 min | `scripts/maintainer/test/Test-HealthSmoke.ps1` |
| Translation tweak (RU) | 15 min | `README.ru.md`, `docs/ru/` |

## Setup (5 minutes)

```powershell
git clone https://github.com/XKush/homebase-devshell.git
cd homebase-devshell
pwsh -NoProfile -File devshell.ps1 health
```

No install required for docs-only PRs. For runtime changes, run smoke tests:

```powershell
pwsh -NoProfile -File scripts/maintainer/test/Test-HealthSmoke.ps1
pwsh -NoProfile -File scripts/maintainer/test/Test-PrivacyAuditSmoke.ps1
```

## PR checklist

- One focused change (one doc page or one message)
- Do **not** modify `lib/WorkstationOrchestrator.ps1` or platform spec without maintainer approval
- Link related Discussion or Issue if any
- Public API changes require [API-STABILITY.md](API-STABILITY.md) / [JSON-SCHEMA.md](JSON-SCHEMA.md) update

## Ideas welcome

Open a [Discussion](https://github.com/XKush/homebase-devshell/discussions) for “how should this work?” before a large PR.

Label **`good first issue`** issues are curated for newcomers.
