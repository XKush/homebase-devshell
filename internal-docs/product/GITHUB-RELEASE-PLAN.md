# HomeBase DevShell — GitHub Release Plan (v2.0.0)

**Product:** HomeBase DevShell · **Tag:** `v2.0.0` · **Platform spec:** `1.0.0` LOCKED (unchanged)

---

## 1. Version & tag strategy

| Artifact | Version | Rule |
|----------|---------|------|
| **Git tag** | `v2.0.0` | First public stable product release |
| **Product semver** | `2.0.0` | `KGreen.Workstation.psd1` `ModuleVersion` |
| **Platform spec** | `1.0.0` | Locked — not bumped with product tag |
| **CLI output** | `Product 2.0.0 · Platform Spec 1.0.0 (LOCKED)` | `devshell version` |

**Future tags:** `v2.0.x` PATCH (fixes) · `v2.1.0` MINOR (features, module commands) · `v3.0.0` MAJOR (breaking paths/API)

**Do not tag:** docs-only commits without user-visible change (optional PATCH if README/install fix affects users).

---

## 2. Release naming convention

```
v{MAJOR}.{MINOR}.{PATCH}

GitHub Release title:
  HomeBase DevShell v2.0.0 — Stable Public Release

Pre-release (if needed):
  HomeBase DevShell v2.1.0-rc.1
```

**Asset naming (optional attachments):**

- `HomeBase-DevShell-v2.0.0-source.zip` (auto from GitHub)
- No binary builds — PowerShell source distribution only

---

## 3. First public release — INCLUDED

### Product surface (primary)

- `install.ps1` — one-line bootstrap
- `devshell.ps1` — CLI (`install`, `doctor`, `status`, `reload`, `trace`)
- `README.md` — public product documentation
- `CHANGELOG.md` — v2.0.0 release notes
- `LICENSE` (MIT)

### Runtime (shipped, not marketed as “framework”)

- `profile/` — canonical PowerShell 7 profile
- `lib/` — locked platform stack (Wave A–D)
- `modules/KGreen.Workstation` — command center module
- `terminal/` — OMP / WT assets

### User-facing scripts

- `Install-Workstation.ps1`, `Install-ShellProfile.ps1`, `Validate-Workstation.ps1`
- Core maintenance scripts invoked by install/doctor

### Documentation (public, curated)

- `docs/quickstart.md` (optional stub linking README)
- `docs/platform-spec-summary.md` — **summary only** (links to full spec)
- `docs/charter/PLATFORM-SPEC-SIGNOFF.md` — transparency for advanced users
- `docs/charter/EXTENSION-GUIDELINES.md` — extension authors
- `examples/extension-hello/` (if present)

### Quality gates (CI)

- `Test-WorkstationPlatformHardening.ps1` on PR / release tag

---

## 4. First public release — EXCLUDED (do not headline)

| Category | Examples | Rationale |
|----------|----------|-----------|
| Internal migration WIP | Phase 2 stash artifacts, path migration scripts in flux | Confuses new users |
| Charter governance pack | `PATH-MIGRATION-*`, `EXECUTION-PLAN`, mid-reviews | Contributor/org internal |
| Baseline artifacts (most) | `phase2-step1-stable.json` except platform lock | Operator tooling |
| Sandbox / audit WIP | `MenuSystem.ps1` WIP, extra Shell commands not in release scope | Unstable |
| Security/anonymity deep ops | Tor hardening internals as primary story | Wrong product positioning for v2.0.0 OSS |
| Pre-release tags | `v2.0.0` baseline before DevShell packaging | Superseded by this release |

**Public messaging:** “DevShell + doctor + fast profile” — not “Wave B orchestrator architecture.”

---

## 5. Release checklist (maintainer)

```powershell
# 1. Hardening gate
pwsh -NoProfile -File Test-WorkstationPlatformHardening.ps1 -SaveReport

# 2. Version consistency
pwsh -NoProfile -File Test-ReleaseVersion.ps1

# 3. Product smoke
pwsh -NoProfile -File devshell.ps1 status
pwsh -NoProfile -File devshell.ps1 doctor   # expect PASS on clean machine

# 4. Tag
git tag -a v2.0.0 -m "HomeBase DevShell v2.0.0 — stable public release"
git push origin v2.0.0

# 5. GitHub Release
#    - Paste CHANGELOG [2.0.0] section
#    - Mark as Latest
#    - No pre-release
```

---

## 6. Post-release

| Channel | Action |
|---------|--------|
| README | Replace `<org>` in install one-liner with real GitHub org |
| Discussions | Pin “Getting started” linking README |
| Issues | Templates: bug / install help / feature (module vs platform) |
| v2.0.1 | Only if install/doctor regression — PATCH |

---

**Platform architecture remains LOCKED at v1.0.0.** Product releases do not unlock the spec without explicit sign-off.
