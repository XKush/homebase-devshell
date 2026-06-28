# HOME BASE v2.0.0 — Architecture Freeze

**Статус:** ACTIVE  
**С:** 2026-06-29  
**До:** завершения Phase 2 (Path Abstraction)  
**Baseline tag:** `v2.0.0` (единственная официальная product baseline)

---

## 1. Declaration

HOME BASE enters **Architecture Freeze** at product version **v2.0.0**.

Цель: не менять **функциональность** и **архитектуру runtime** одновременно с Phase 2 (paths) — чтобы любой инцидент имел однозначный источник.

---

## 2. Запрещено до конца Phase 2

| Category | Examples |
|----------|----------|
| **New commands** | новые exported functions |
| **New features** | menu categories, anon workflows, trust formulas |
| **API changes** | export list, parameter contracts |
| **UI redesign** | Presentation layer (Phase 4) |
| **Repo restructure** | Scripts/ move (Phase 3) |
| **Breaking migrations** | path moves without MIGRATION.md procedure |

---

## 3. Разрешено во время freeze

| Category | Examples |
|----------|----------|
| **Bugfixes** | crashes, data loss, trust false negatives |
| **Documentation** | charter, MIGRATION, policies, ADR |
| **Release process** | Test-ReleaseVersion, checklists |
| **Tests / audits** | Test-MenuDeepAudit, doctor checks **if fixing false results only** |
| **Phase 2 prep docs** | ADR updates, config schema design in docs |

Phase 2 **code** starts only after:

- [x] MIGRATION.md published
- [x] Release governance (Phase 1.5) committed
- [ ] `backupconfig` + rollback drill to `v2.0.0`
- [ ] Explicit user approval to begin Phase 2

---

## 4. Version tagging during freeze

| Change type | Git tag? | Version bump? |
|-------------|----------|---------------|
| Docs / release process | ❌ No | ❌ No — stays **2.0.0** product |
| Bugfix user-visible | ✅ Yes | PATCH `2.0.1` |
| Phase 2 complete | ✅ Yes | MINOR `2.1.0` (recommended) |

**Rule:** tag = **product change the user can feel**. Process docs commit without tag.

---

## 5. Exit criteria (end freeze)

Architecture Freeze lifts when **Phase 2 exit criteria** met:

- [ ] `Get-HomeBasePath` in production code paths
- [ ] `homebase.defaults.json` deployed (defaults = current paths)
- [ ] Junction compatibility verified
- [ ] `doctor` 75/75, `trustcheck` VERIFIED
- [ ] MIGRATION.md §7 executed and verified
- [ ] RELEASE-CHECKLIST passed for release tag (e.g. `v2.1.0`)

Then Phase 3 planning may begin; freeze rules for **new commands** extend until Phase 2 is stable **1 minor release** (recommended).

---

## 6. Rollback anchor

```powershell
git checkout v2.0.0
fixprofile
reloadprofile
restoreconfig   # if needed
doctor
trustcheck
```

See [MIGRATION.md](./MIGRATION.md) §4.

---

## 7. Related

- [MIGRATION.md](./MIGRATION.md)
- [EXECUTION-PLAN.md](./EXECUTION-PLAN.md)
- [RELEASE-REQUIREMENTS.md](./RELEASE-REQUIREMENTS.md)
- [SUPPORT-POLICY.md](./SUPPORT-POLICY.md)
