# HOME BASE — Versioning

Semver policy для HOME BASE.

---

## 1. Format

```
MAJOR.MINOR.PATCH[+BUILD]
```

| Component | When to bump |
|-----------|--------------|
| **MAJOR** | Breaking: command removed, path migration v3, JSON schema breaking |
| **MINOR** | New commands, new doctor checks, UI panel, deprecations announced |
| **PATCH** | Bugfix, locale, docs-only in repo, selfcheck fix |
| **BUILD** | Optional: git sha, validation timestamp |

**Current:** `2.0.0` (product baseline, tag `v2.0.0`)

**Target manifest:** `KGreen.Workstation.psd1` → `ModuleVersion = '2.0.0'`

### Tags vs documentation

- **Git tag** = product release (user-visible or runtime change).
- **Docs / release governance** = commit only, **no tag**, **no version bump**.
- Next tag **`v2.0.1`** only when product PATCH (bugfix, doctor, module, profile, behavior).

---

## 2. Git tags

```
v2.0.0
v2.1.0
v2.1.1
```

Tag **only** from Release gate ([RELEASE-CHECKLIST.md](./RELEASE-CHECKLIST.md)).

### Version consistency check

```powershell
pwsh -File C:\Scripts\Workstation\Test-ReleaseVersion.ps1
pwsh -File C:\Scripts\Workstation\Test-ReleaseVersion.ps1 -RequireTagAtHead
```

Sources of truth (order): **psd1** → Git tag → README → CHANGELOG. See [RELEASE-REQUIREMENTS.md](./RELEASE-REQUIREMENTS.md) §6.

---

## 3. CHANGELOG linkage

Every MINOR/MAJOR → [CHANGELOG.md](./CHANGELOG.md) section.

PATCH batchable weekly.

---

## 4. JSON SchemaVersion

Reports gain `SchemaVersion: 2` without breaking readers:

- Missing field = v1 implicit
- Writers add field on next touch

---

## 5. Deprecation timeline

```
Release N:     Deprecated + warning
Release N+1:   Deprecated + alias
Release N+2:   Removed (MAJOR bump)
```

Minimum **2 minor** releases between deprecation and removal.

---

## 6. Branching (recommended)

| Branch | Purpose |
|--------|---------|
| `main` | stable, tagged |
| `develop` | integration |
| `feature/*` | PRs |

---

## 7. Related

- [LIFECYCLE.md](./LIFECYCLE.md)
- [CHANGELOG.md](./CHANGELOG.md)
- [ROADMAP.md](./ROADMAP.md)
