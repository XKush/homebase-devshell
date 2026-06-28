# HOME BASE — Execution Plan

Безопасный план модернизации. **Phase 0 не меняет код.**

---

## Principles

| Rule | |
|------|---|
| Docs before code | Charter = law |
| No breaking without migration | 2 minor releases warning |
| Trust gate | doctor + trustcheck after each phase |
| Rollback | backup before structural change |

---

## Phase 0 — Documentation ✅

| | |
|---|---|
| **Duration** | 1–2 weeks |
| **Code changes** | **None** |
| **Deliverables** | `docs/charter/*` complete |
| **Exit criteria** | EXECUTIVE-SUMMARY approved |

### Tasks

- [x] README, QUICKSTART, ARCHITECTURE, PHILOSOPHY
- [x] Standards (CODING, UI, LANGUAGE, LOGGING, COMMAND, TESTING)
- [x] Policies (SECURITY, BACKUP)
- [x] VERSIONING, LIFECYCLE, ROADMAP
- [x] CONTRIBUTING, CHANGELOG, LICENSE-RECOMMENDATION
- [x] ADR-0001 … ADR-0008
- [x] EXECUTION-PLAN, EXECUTIVE-SUMMARY

---

## Phase 1 — Open Source Minimum ✅

| | |
|---|---|
| **Duration** | 1 week |
| **Risk** | Low |
| **Code changes** | Minimal (psd1 version only) |

### Tasks

- [x] Add `LICENSE` (MIT) — root
- [x] Root `README.md` (RU primary)
- [x] Add `SECURITY.md`
- [x] `KGreen.Workstation.psd1` ModuleVersion = 2.0.0
- [x] Git tag `v2.0.0` (`84bde27`)

### Exit criteria

- [x] LICENSE + README + SECURITY + psd1
- [x] Tag `v2.0.0`
- [ ] `.gitignore` runtime audit (optional)
- [ ] `docs/ru/README.md` → link to charter (optional)

### Rollback

`git checkout v2.0.0` — no runtime mutation.

---

## Phase 1.5 — Release Stabilization ✅

| | |
|---|---|
| **Duration** | 3–5 days |
| **Risk** | **None** (docs + read-only script) |
| **Code changes** | **None** to module/runtime |

**Goal:** Закрепить процесс релизов **до** Phase 2 (Path Abstraction). Rollback anchor: **v2.0.0**.

### Tasks

- [x] `Test-ReleaseVersion.ps1` — psd1 / README / CHANGELOG / Git tag
- [x] [RELEASE-CHECKLIST.md](./RELEASE-CHECKLIST.md)
- [x] [RELEASE-REQUIREMENTS.md](./RELEASE-REQUIREMENTS.md)
- [x] [SUPPORT-POLICY.md](./SUPPORT-POLICY.md)
- [x] [COMPATIBILITY.md](./COMPATIBILITY.md)
- [x] [ENVIRONMENT-MATRIX.md](./ENVIRONMENT-MATRIX.md)

### Exit criteria

- [x] `pwsh -File Test-ReleaseVersion.ps1` PASS on v2.0.0
- [x] Release docs cross-linked from charter README
- [x] MIGRATION.md + ARCHITECTURE-FREEZE.md published
- [x] Single docs commit **without** new tag (`v2.0.0` remains product baseline)

### Rollback

Same as Phase 1 — **`v2.0.0`** tag unchanged. Process docs do not create product releases.

---

## Architecture Freeze 🔒 (ACTIVE)

**Declared:** v2.0.0 · **Until:** Phase 2 complete

See [ARCHITECTURE-FREEZE.md](./ARCHITECTURE-FREEZE.md).

| Allowed | Blocked |
|---------|---------|
| Bugfixes | New commands |
| Docs / tests / release infra | Features / UI redesign |
| Phase 2 after MIGRATION.md + approval | Path moves without migration procedure |

**Pre-Phase-2 requirement:** [MIGRATION.md](./MIGRATION.md) ✅

---

## Phase 2 — Path Configuration

| | |
|---|---|
| **Duration** | 2–4 weeks |
| **Risk** | **Medium** |
| **Code changes** | Yes — path abstraction |

### Tasks

1. Create `Config/homebase.defaults.json`
2. Implement `Get-HomeBasePath` in Core (or lib)
3. Migrate high-traffic paths first: Logs, Backups, Validation
4. `Fix-WorkstationPath.ps1` v2 — junction legacy → new
5. Document env `HOMEBASE_RUNTIME`
6. Validate + revise full run on test machine

### Exit criteria

- [ ] Zero hardcoded `C:\Logs\Workstation` in new code
- [ ] Legacy junctions work 12 months
- [ ] ADR-0007 status → Accepted

### Rollback

Junctions point back; restore `homebase.defaults.json` from backup.

---

## Phase 3 — Repository Restructure

| | |
|---|---|
| **Duration** | 3–6 weeks |
| **Risk** | **Medium** |
| **Code changes** | Yes — file moves + shims |

### Target layout

```
Workstation/
├── Core/
├── Modules/HomeBase/     # future rename
├── Scripts/
├── Tests/
├── Docs/
├── Assets/
├── Config/
└── profile fragments
```

### Tasks

1. Move 50+ root `.ps1` → `Scripts/` by category
2. Shim at old paths: `Write-Warning deprecated; & new path`
3. Update `$script:WSRoot` resolution
4. Fix relative imports in moved scripts
5. Update Validate path checks

### Exit criteria

- [ ] All commands work from profile
- [ ] Shims log deprecation once per session
- [ ] Validate 75/75

### Rollback

Git revert + restore from backup snapshot.

---

## Phase 4 — Presentation Layer

| | |
|---|---|
| **Duration** | 4–8 weeks |
| **Risk** | Low–Medium |
| **Code changes** | Yes — UI refactor |

### Tasks

1. `Show-HomeBasePanel` implementation
2. Migrate: `home`, `revise`, `doctor`, `trustcheck`, `go`, `anon`
3. Locale SSOT — migrate inline RU from Private/*.ps1
4. Validate labels RU via locale
5. UI compliance audit script

### Exit criteria

- [ ] UI-STYLE-GUIDE audit pass ≥ 90%
- [ ] No user-facing English in primary flows
- [ ] Screenshots in docs updated

### Rollback

Feature flag `$env:HOMEBASE_UI_LEGACY=1`

---

## Phase 5 — HOME BASE v3.0

| | |
|---|---|
| **Duration** | 8+ weeks |
| **Risk** | **High** if rushed |
| **Code changes** | Yes — rename + removal |

### Tasks

1. v2.1, v2.2: deprecate warnings (poriadok, jarvis, menu/palette/nav)
2. `HomeBase` module alias alongside `KGreen.Workstation`
3. Remove deprecated after **2 minor releases**
4. Migration guide in CHANGELOG
5. Major version bump 3.0.0

### Exit criteria

- [ ] Zero deprecated in Recommended lifecycle
- [ ] Module rename complete
- [ ] trustcheck VERIFIED on clean install

### Rollback

Keep v2.x branch; pin ModuleVersion in profile.

---

## Phase dependency graph

```
Phase 0 (docs)
    ↓
Phase 1 (OSS) ✅
    ↓
Phase 1.5 (release process) ✅
    ↓
Phase 2 (paths) ──→ Phase 3 (structure)
                          ↓
                    Phase 4 (UI)
                          ↓
                    Phase 5 (v3)
```

Phase 2 and 3 can overlap with care; Phase 5 **requires** 2+4 complete.

---

## Per-phase checklist

```powershell
# Run after every phase
backupconfig
doctor
revise
trustcheck
validation
```

All must pass before merge to main.

---

## Related

- [ROADMAP.md](./ROADMAP.md)
- [VERSIONING.md](./VERSIONING.md)
- [LIFECYCLE.md](./LIFECYCLE.md)
