# Roadmap

This is a **contract** with users — not a wishlist. Items move only after community signal or maintainer review.

**Current product version:** 3.0.0 · **Platform spec:** 1.0.0 LOCKED

---

## v3.x — Stabilization (now)

| In scope | Out of scope |
|----------|----------------|
| Bug fixes | New public CLI commands |
| Documentation | Platform orchestrator changes |
| Test coverage (smoke → Pester) | Breaking JSON without schema bump |
| Community (Discussions, Issues, PRs) | Plugin implementations |
| Packaging / SHA256 / CI gates | “Privacy beast” / anonymity features |

**No new major features** until real-world usage confirms what matters.

Likely patch releases: `3.0.x` — fixes and docs only.

---

## v3.1 — Engineering quality (after stabilization)

Same public API. Internal work only:

- Pester for core logic (`PrivacyAudit`, health aggregation)
- PSScriptAnalyzer in CI
- Refactor large files without behavior change
- Smoke tests on clean Windows VMs
- Plugin manifest validation (scaffold)

See [CHANGELOG](../CHANGELOG.md) `[Unreleased]` for tracking.

---

## Future (not scheduled)

Explored **after** stabilization feedback — not committed dates:

| Area | Notes |
|------|--------|
| **Plugin API** | `plugins/` — Docker, WSL, VS Code, Azure, AWS, GitHub, Rust, Go |
| **History** | Richer trends, export, compare |
| **HTML reports** | Deeper styling, shareable bundles |
| **Integrations** | GitHub Actions templates, Intune-friendly JSON |

Ideas → [Discussions](https://github.com/XKush/homebase-devshell/discussions) · label `idea`

---

## How priorities change

1. **Usage data** — what people run (`health` vs `doctor` vs `privacy`)
2. **Discussions & Issues** — recurring pain, not one-off requests
3. **Maintainer capacity** — reliability over feature count

**Maturity signals (v3.x):** merged external PRs · constructive Discussions → doc/test changes · stable CI across releases · no surprise API breaks. See [RELEASE-CRITERIA.md](RELEASE-CRITERIA.md).
