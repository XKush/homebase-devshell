# Release criteria (v3+)

Checklist **before every** product tag (`vX.Y.Z`). All items must pass unless explicitly waived in an ADR.

Maintainers: run this list; do not add new governance documents — use [MANIFESTO](MANIFESTO.md), [PROJECT-PRINCIPLES](PROJECT-PRINCIPLES.md), [JSON-SCHEMA](JSON-SCHEMA.md), and [adr/](adr/) as gates.

---

## Decision gates (any change)

| Change type | Check first |
|-------------|-------------|
| New feature or command | [MANIFESTO](MANIFESTO.md) · [PROJECT-PRINCIPLES](PROJECT-PRINCIPLES.md) · [ROADMAP](ROADMAP.md) (v3.x = no new public CLI) |
| JSON field or schema | [JSON-SCHEMA](JSON-SCHEMA.md) · [API-STABILITY](API-STABILITY.md) |
| Architecture / policy | New [ADR](adr/) |

---

## Pre-release checklist

### CI and tests

- [ ] GitHub Actions **CI fully green** on the release commit (all jobs on `main`)
- [ ] `pwsh -File scripts/maintainer/test/Test-ReleaseVersion.ps1` — **PASS**
- [ ] `pwsh -File scripts/maintainer/test/Test-HealthSmoke.ps1` — **PASS**
- [ ] `pwsh -File scripts/maintainer/test/Test-DoctorSmoke.ps1` — **PASS**
- [ ] `pwsh -File scripts/maintainer/test/Test-PrivacyAuditSmoke.ps1` — **PASS**

### Version and packaging

- [ ] `modules/KGreen.Workstation.psd1` `ModuleVersion` = release version
- [ ] `install.ps1` pin matches `homebase-devshell/vX.Y.Z`
- [ ] `CHANGELOG.md` has `[X.Y.Z]` section with accurate notes
- [ ] After tag: CI **release-assets** uploaded zip + SHA256; Scoop/WinGet hashes synced if needed

### Public API and docs

- [ ] **No breaking CLI or JSON changes** in a PATCH/MINOR without semver + schema bump per [API-STABILITY](API-STABILITY.md)
- [ ] New or changed JSON fields documented in [JSON-SCHEMA](JSON-SCHEMA.md)
- [ ] README / `docs/` match actual commands (`devshell health` as primary entry)
- [ ] [ROADMAP](ROADMAP.md) still accurate for the release type (patch = stability only)

### Quality bar

- [ ] **No open critical bugs** that block install, `health`, or `doctor` on a supported Windows + pwsh 7 setup
- [ ] Defender policy unchanged: suite does **not** enable Microsoft Defender AV

---

## Semver quick reference

| Bump | When | API |
|------|------|-----|
| **PATCH** `3.0.x` | Bugfix, docs, tests | Frozen — no breaking changes |
| **MINOR** `3.1.0` | Additive JSON, internal quality, non-breaking enhancements | CLI frozen unless ADR + roadmap update |
| **MAJOR** `4.0.0` | Remove/rename commands or breaking JSON | New schema major + ADR |

---

## Maturity goals (not version numbers)

Success for v3.x is measured by:

- External **Pull Requests** merged through review
- **Discussions** that led to doc or test improvements
- **No breaking public API** between v3.x tags without explicit major bump
- **CI green** across consecutive releases

See [ROADMAP](ROADMAP.md) for scope contract.

---

## Tag command (maintainers)

```powershell
pwsh -File scripts/maintainer/test/Test-ReleaseVersion.ps1 -SkipGit
# … run smoke tests …
git tag -s vX.Y.Z -m "HomeBase DevShell vX.Y.Z — <one line>"
git push origin main
git push origin vX.Y.Z
```

**Signed tags:** use `git tag -s` for release tags when GPG is configured (`gpg --list-secret-keys`). Unsigned tags are acceptable only for emergency hotfix — document in CHANGELOG.

Verify release: https://github.com/XKush/homebase-devshell/releases
