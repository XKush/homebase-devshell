## Read before posting a feature idea

HomeBase DevShell is intentionally **small**. The public product is three commands:

| Command | Purpose |
|---------|---------|
| `install` | First-time setup |
| `doctor` | Am I ready to work? |
| `status` | Did everything load? |

**Platform architecture is LOCKED (v1.0.0).** We do not expand the core CLI or runtime stack in response to feature requests.

---

### What we **will** consider (packaging / docs)

- README clarity and install friction
- Doctor messaging and troubleshooting docs
- Optional **extension packs** (themes, configs, team templates) — separate from core install
- GitHub onboarding, issues, releases

### What we **won't** add to OSS core

- New public CLI commands
- Cloud accounts / telemetry / required signup
- Architecture refactors (Orchestrator, Router, Registry, Event Core)
- "Framework" surface that competes with install → doctor → status

---

### Better places for your idea

| Idea type | Where |
|-----------|--------|
| Bug in install / doctor | [Install help template](https://github.com/XKush/homebase-devshell/issues/new?template=install-help.yml) |
| Optional config / theme pack | Discussions → Ideas |
| Maintainer / power-user tooling | Already under `scripts/maintainer/` — not product surface |

---

### Free forever (OSS core)

- `install.ps1`, `devshell.ps1`
- `doctor`, `status`
- MIT license
- Stable release channel (`v2.0.x`)

Thank you for keeping scope tight — it protects everyone who just wants **Install. Check. Done.**
