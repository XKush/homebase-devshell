# Growth vector — first 100 users

**Product:** DevReady (HomeBase DevShell) · **Version:** 2.1.1 · **Updated:** 2026-06-29

Audience: maintainers. No runtime changes.

---

## Current state (honest audit)

### Strengths

| Area | Status |
|------|--------|
| **Core promise** | Clear: install → `devready` → pass/fail |
| **OSS surface** | README EN/RU, docs hub, CI 4/4, MIT, releases tagged |
| **Brand** | DevReady name + `devready` shim — memorable |
| **Trust** | Local-only, no cloud, no Defender enablement |
| **CI** | release-version, command-health, platform-hardening, install-smoke |

### Gaps (block first users)

| Gap | Impact | Priority |
|-----|--------|----------|
| **Zero social proof** | No stars, screenshots, testimonials | P0 |
| **No video/GIF** | README is text-only; hard to trust on mobile | P0 |
| **Install friction** | `irm \| iex` scares security-conscious devs | P1 |
| **Niche** | Windows + pwsh 7 only — smaller funnel | Accept |
| **No Scoop/winget package** | Discovery outside GitHub weak | P1 |
| **social preview** | OG card still default until manual Settings upload | P2 |
| **internal-docs in tree** | Clones full maintainer history (~noise for forks) | P2 |

### What we removed (studio hygiene)

- Playwright upload hacks — GitHub has no API; manual Settings only
- `.github/growth/` in public tree — moved here under `internal-docs/marketing/`
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
| **Discovery** | 500 repo visits/mo | GitHub topics, Reddit, X, Dev.to |
| **Trust** | >30s on README | GIF of `devready` PASS, Issue #2 gallery |
| **Install** | >40% complete | Pin release, troubleshooting issue #3 |
| **Aha** | See green "Ready to work" | Core doctor ≤35 checks, fast output |
| **Share** | 1 screenshot / 10 installs | Issue #2, Discussion #4 |

---

## 90-day roadmap (product + growth)

### Wave 1 — Proof (weeks 1–2) · no architecture changes

- [x] Record 15s GIF: install → `devready` → PASS (embed in README)
- [x] Seed Issue #2 with maintainer screenshot (demo PNG)
- [x] Pin release v2.1.1 + issues #1–#3 on GitHub (issues were pinned; release v2.1.1 published)
- [ ] Upload `.github/social-preview.png` in Settings (manual, once — no API)
- [x] Post launch copy to Discussion #4 (v2.1.1 comment)

### Wave 2 — Reduce friction (weeks 3–6)

- [ ] `devshell init` — dry-run / print what install would do (no winget)
- [ ] README "inspect before run" — link to tagged `install.ps1` on GitHub
- [ ] Pester smoke tests in CI (public signal of quality)
- [ ] Release asset: `devready-vX.Y.Z.zip` + SHA256 (no git clone required)

### Wave 3 — Discovery (weeks 7–12)

- [ ] Scoop bucket or winget manifest (community install path)
- [ ] Dev.to / Habr RU article (install story, not architecture)
- [ ] "Compare" doc: DevReady vs manual checklist (not vs Oh My Zsh)
- [ ] Optional: exclude `internal-docs/` from install tree (smaller product zip)

**Locked:** platform spec 1.0.0 — no new public CLI verbs without maintainer sign-off.

---

## Channels (ranked)

| Channel | Effort | Expected yield |
|---------|--------|----------------|
| **GitHub Search** (topics: `devready`, `powershell`, `windows-dev`) | Low | Steady long tail |
| **Reddit** r/PowerShell, r/windows | Medium post | Spike + backlash risk on `irm\|iex` |
| **X / Bluesky** #DevReady #PowerShell | Low | Needs GIF |
| **Habr (RU)** | Medium article | RU README already exists |
| **YouTube Short** | High | High trust |
| **Conference / meetup** | High | Low volume, high quality |

**Avoid early:** Hacker News (hostile to Windows), aggressive issue spam, paid ads.

---

## Metrics

| Metric | Now | 30d target | 90d target |
|--------|-----|------------|------------|
| GitHub stars | ~0 | 25 | 100 |
| Release downloads | — | track via zip | 500 |
| Issue #2 screenshots | 0 | 5 | 20 |
| CI green | 4/4 | 4/4 | 4/4 |
| Core doctor pass (clean VM) | yes | yes | yes |

Track weekly: stars, clone traffic (GitHub Insights), Discussion #4 replies.

---

## Messaging cheatsheet

**Share line:**

```powershell
irm https://raw.githubusercontent.com/XKush/homebase-devshell/v2.1.1/install.ps1 | iex
devready
```

**Reply to "why not just winget everything?"**

> DevReady doesn't install your stack blindly — it checks whether what's already there actually works.

**Reply to "irm iex is malware"**

> Fair. Read `install.ps1` on GitHub, tag v2.1.1, or wait for zip release + hash in Wave 2.

---

## Risk register

| Risk | Mitigation |
|------|------------|
| Scope creep | Issue #1 scope template; platform LOCKED |
| CI red on release | Never ship without 4/4 green |
| Brand split (DevReady vs homebase-devshell) | README always shows both once |
| Maintainer burnout | Waves are sequential; no daily posting requirement |

---

## Next maintainer action (today)

1. GIF → README  
2. Manual social preview upload (Settings)  
3. One launch post (Discussion #4)  
4. Do not add automation scripts that fight GitHub UI
