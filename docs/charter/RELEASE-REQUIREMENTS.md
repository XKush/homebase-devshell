# HOME BASE — Release Requirements

Минимальные требования к **каждому** новому релизу. Без выполнения — tag не создаётся.

---

## 1. Universal requirements (all releases)

Applies to **PATCH**, **MINOR**, and **MAJOR**.

| # | Requirement | Verification |
|---|-------------|--------------|
| R1 | Semver bump follows [VERSIONING.md](./VERSIONING.md) | review |
| R2 | `ModuleVersion` = README = tag | `Test-ReleaseVersion.ps1` |
| R3 | CHANGELOG entry | `[X.Y.Z]` or `[Unreleased]` → released |
| R4 | No secrets in commit | manual / `.gitignore` |
| R5 | `doctor` PASS | 75/75 |
| R6 | `trustcheck` VERIFIED | Score 100 |
| R7 | Git annotated tag `vX.Y.Z` | `git tag -l` |

```powershell
pwsh -File Test-ReleaseVersion.ps1
doctor
trustcheck
```

---

## 2. PATCH release (x.y.Z)

**When:** bugfix, locale, docs-only in repo, selfcheck fix.

| # | Additional |
|---|------------|
| P1 | `Test-WorkstationCommands.ps1 -Quick` exit 0 |
| P2 | `revise -Quick` completes |
| P3 | CHANGELOG **Fixed** or **Changed** section populated |
| P4 | No new deprecations |
| P5 | No breaking JSON schema changes |

Optional: `Test-MenuDeepAudit.ps1`

---

## 3. MINOR release (x.Y.z)

**When:** new commands, new doctor checks, UI panel, deprecation announced.

| # | Additional |
|---|------------|
| M1 | All PATCH requirements |
| M2 | Full `revise` (not `-Quick`) |
| M3 | `Test-WorkstationCommands.ps1` (full) |
| M4 | `Test-MenuDeepAudit.ps1` |
| M5 | `Test-AnonymityKitAudit.ps1` (if security/menu touched) |
| M6 | [LIFECYCLE.md](./LIFECYCLE.md) updated for new/changed commands |
| M7 | [SUPPORT-POLICY.md](./SUPPORT-POLICY.md) supported line updated |
| M8 | Deprecations: warning text + CHANGELOG **Deprecated** |
| M9 | `docs/ru/COMMANDS.md` synced (`Sync-WorkstationDocs` or revise) |

---

## 4. MAJOR release (X.y.z)

**When:** breaking changes, command removal, path schema v3, module rename.

| # | Additional |
|---|------------|
| J1 | All MINOR requirements |
| J2 | Migration guide in CHANGELOG + dedicated doc |
| J3 | Minimum **2 prior minors** carried deprecation warnings |
| J4 | [SECURITY.md](../../SECURITY.md) supported table updated |
| J5 | [ENVIRONMENT-MATRIX.md](./ENVIRONMENT-MATRIX.md) re-certified |
| J6 | Manual smoke: `home`, `go`, `anon`, `backupconfig`, `restoreconfig -WhatIf` |
| J7 | Rollback procedure tested (`git checkout` previous MAJOR tag) |
| J8 | ADR added or updated for architectural break |

---

## 5. Phase-gated releases

| Phase | Extra gate before tag |
|-------|----------------------|
| **1.5** (now) | `Test-ReleaseVersion.ps1` + this document published |
| **2** Path | Full matrix 🔬 rows + `backupconfig` + rollback to v2.0.0 tested |
| **3** Structure | All shims warn once; Validate path checks pass |
| **4** UI | UI-STYLE-GUIDE audit ≥ 90% |
| **5** v3 | MAJOR checklist + alias period complete |

---

## 6. Version sources of truth (order)

```
1. modules/KGreen.Workstation.psd1  → ModuleVersion  (authoritative)
2. Git tag                           → v{ModuleVersion}
3. README.md                         → user-visible version
4. docs/charter/CHANGELOG.md         → release history
5. JSON reports                      → SchemaVersion (additive, separate)
```

Conflict resolution: **psd1 wins**. Run `Test-ReleaseVersion.ps1` before tag.

### Tags vs commits

| Change | Tag `vX.Y.Z`? |
|--------|---------------|
| Docs, release process, charter | ❌ No |
| Bugfix / runtime / module / profile / commands | ✅ Yes (PATCH/MINOR/MAJOR) |

Product baseline until first PATCH: **`v2.0.0` only**.

---

## 7. Artifacts per release

| Artifact | Location |
|----------|----------|
| Git tag | `vX.Y.Z` |
| CHANGELOG section | `docs/charter/CHANGELOG.md` |
| Validation JSON | `C:\Logs\Workstation\validation-*.json` |
| Trust report | `C:\Logs\Workstation\trust-report.json` |
| Config backup | `C:\Backups\Workstation\{timestamp}/` |

Store backup folder name in CHANGELOG for Phase 2+ rollback.

---

## 8. Related

- [RELEASE-CHECKLIST.md](./RELEASE-CHECKLIST.md)
- [TESTING-STANDARD.md](./TESTING-STANDARD.md)
- [VERSIONING.md](./VERSIONING.md)
- [EXECUTION-PLAN.md](./EXECUTION-PLAN.md)
