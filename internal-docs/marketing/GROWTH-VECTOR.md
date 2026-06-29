# Growth vector — first 100 users

**Product:** DevReady (HomeBase DevShell) · **Version:** 2.2.0 · **Updated:** 2026-06-29

Audience: maintainers. No runtime changes.

---

## Current state (honest audit)

### Strengths

| Area | Status |
|------|--------|
| **Core promise** | Clear: install → `devready` → pass/fail |
| **OSS surface** | README EN/RU, docs hub, CI 4/4+, MIT, releases tagged |
| **Brand** | DevReady name + `devready` shim — memorable |
| **Trust** | Local-only, no cloud, no Defender enablement |
| **CI** | release-version, command-health, platform-hardening, install-smoke, init-smoke, release-assets |
| **Friction reducers** | `devshell init`, zip+SHA256, packaging manifests, article drafts |

### Gaps (block first users)

| Gap | Impact | Priority |
|-----|--------|----------|
| **Low social proof** | Few stars/screenshots | P0 |
| **social preview** | OG card default until manual Settings upload | P2 |
| **winget-pkgs PR** | Manifest template only — not in community repo yet | P2 |

### What we removed (studio hygiene)

- Playwright upload hacks — GitHub has no API; manual Settings only
- `.github/growth/` in public tree — moved to `internal-docs/marketing/`
- Temp scratch files — gitignored

---

## Positioning (one sentence)

**DevReady tells Windows developers in 30 seconds whether PowerShell, git, and PATH are actually ready — before the first commit.**

Not: dotfiles framework, Kali clone, cloud dashboard.

---

## ICP (ideal first user)

1. **New laptop / reinstall** — "did my setup script actually work?"
2. **Junior on Windows** — scared of broken `$PROFILE`
3. **Solo indie** — no IT team to validate env
4. **PowerShell-curious** — already on pwsh 7, not WSL-only

**Anti-ICP:** macOS/Linux dotfiles hunters, enterprise MDM teams, people who never run doctor twice.

---

## Funnel

```
Discovery → Trust → Install → Aha → Share
```

| Stage | Goal | Tactic |
|-------|------|--------|
| **Discovery** | 500 repo visits/mo | GitHub topics, Reddit, Habr, X |
| **Trust** | >30s on README | GIF, Issue #2 gallery, zip+hash |
| **Install** | >40% complete | `devshell init`, pinned release |
| **Aha** | See green "Ready to work" | Core doctor ≤35 checks |
| **Share** | 1 screenshot / 10 installs | Issue #2, Discussion #4 |

---

## 90-day roadmap (product + growth)

### Wave 1 — Proof (weeks 1–2) · done

- [x] README GIF + Issue #2 seed + Discussion #4 + release v2.1.1
- [ ] Upload `.github/social-preview.png` in Settings (manual, once)

### Wave 2 — Reduce friction (weeks 3–6) · shipped v2.2.0

- [x] `devshell init` — dry-run / print what install would do (no winget)
- [x] README "inspect before run" — link to tagged `install.ps1`
- [x] Release asset: `devready-vX.Y.Z.zip` + SHA256 (CI on tag)
- [x] Scoop + winget manifest templates (`packaging/`)
- [x] Habr + r/PowerShell article drafts (`internal-docs/marketing/articles/`)
- [ ] Pester smoke tests in CI (optional quality signal)
- [ ] Submit winget manifest to microsoft/winget-pkgs

### Wave 3 — Discovery (weeks 7–12)

- [ ] Publish Habr article (copy from `articles/habr-devready.md`)
- [ ] Post r/PowerShell (copy from `articles/reddit-powershell.md`)
- [ ] "Compare" doc: DevReady vs manual checklist
- [ ] Scoop bucket repo or community PR

**Locked:** platform spec 1.0.0 — orchestrator unchanged.

---

## Channels (ranked)

| Channel | Effort | Expected yield |
|---------|--------|----------------|
| **GitHub Search** | Low | Long tail |
| **r/PowerShell** | Medium | Spike; address `irm\|iex` with init+zip |
| **Habr (RU)** | Medium | RU README + article draft ready |
| **X** | Low | GIF link |
| **YouTube Short** | High | High trust |

---

## Metrics

| Metric | Now | 30d target | 90d target |
|--------|-----|------------|------------|
| GitHub stars | low | 25 | 100 |
| Release zip downloads | track | 50 | 500 |
| Issue #2 screenshots | 1+ | 5 | 20 |
| CI green | 5/5+ | green | green |

---

## Messaging cheatsheet

```powershell
irm https://raw.githubusercontent.com/XKush/homebase-devshell/v2.2.0/install.ps1 | iex
devready
```

**Reply to "irm iex is malware":**

> Run `devshell init` first, or use the release zip + SHA256 from GitHub Releases.

---

## Next maintainer action

1. Post Habr + Reddit from article drafts  
2. Manual social preview upload (Settings)  
3. Open winget-pkgs PR after v2.2.0 release assets land
