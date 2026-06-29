# HOME BASE — Migration Policy

**Контракт между разработчиком и пользователем** на период v2.x → v3.x.

Единственная официальная baseline-точка продукта: **Git tag `v2.0.0`**.

Изменения процесса (checklist, policies, verification scripts) **не** создают новый product tag.

---

## 1. Migration Policy — принципы

| # | Принцип |
|---|---------|
| M1 | **No silent breaks** — breaking change только с предупреждением и migration guide |
| M2 | **Backup first** — `backupconfig` перед любой миграцией |
| M3 | **Rollback always possible** — минимум до `v2.0.0` + `restoreconfig` |
| M4 | **Additive by default** — новые поля JSON, новые пути — без удаления старых в PATCH/MINOR |
| M5 | **Two minors rule** — deprecated command → warning → alias → remove только в MAJOR |
| M6 | **Junction grace** — legacy paths через junction **12 месяцев** после Phase 2 |

---

## 2. Какие изменения допускаются

### Без migration guide (PATCH)

- Bugfix без изменения контракта команд
- Locale / docs / release process
- SelfCheck / doctor checks **additive** (новые проверки, не ломающие старые)
- Performance без изменения output shape

### С migration note в CHANGELOG (MINOR)

- Новые команды
- Новые optional JSON fields (`SchemaVersion` bump additive)
- Deprecation **announcement** (warning, не removal)
- Path config **parallel** (новый config + junction на старые пути)

### С полным migration guide (MAJOR)

- Удаление команд
- Breaking JSON schema (required field removed/renamed)
- Module rename (`KGreen.Workstation` → `HomeBase`)
- Removal of junction compatibility
- Profile structure breaking change

---

## 3. Что считается breaking

| Change | Breaking? | When |
|--------|-----------|------|
| Command removed | ✅ | MAJOR only |
| Command renamed without alias | ✅ | MAJOR |
| Default path changes without junction | ✅ | MINOR max with junction; MAJOR without |
| JSON required field renamed | ✅ | MAJOR |
| JSON optional field added | ❌ | MINOR/PATCH |
| Profile adds lazy import | ❌ | PATCH if behavior same |
| Profile removes command alias | ✅ | MINOR + deprecation |
| Doctor check stricter (new fail) | ⚠️ | MINOR if documented |
| UI panel format change | ❌ | MINOR (visual only) |
| Trust score formula change | ⚠️ | MINOR + CHANGELOG |

**Rule:** если пользовательский скрипт или habit ломается без правки — это breaking.

---

## 4. Rollback

### Level 1 — Config / runtime

```powershell
restoreconfig -Force          # из последнего backupconfig
# или явная папка:
restoreconfig -BackupPath 'C:\Backups\Workstation\{timestamp}'
```

### Level 2 — Git product baseline

```powershell
git checkout v2.0.0
fixprofile                      # redeploy profile from repo at tag
reloadprofile
doctor
trustcheck
```

### Level 3 — Phase 2 path rollback

1. Restore `homebase.defaults.json` from backup
2. Remove junctions created by `Fix-WorkstationPath.ps1` v2
3. Revert code to pre-Phase-2 commit
4. `restoreconfig`

**Guarantee:** tag **`v2.0.0`** остаётся permanent rollback anchor до завершения Phase 5 (v3 GA).

---

## 5. Aliases — срок поддержки

| Phase | Behavior |
|-------|----------|
| Deprecation announced (MINOR N) | Old command works + `Write-Warning` once/session |
| MINOR N+1 | Old command = thin alias → new command |
| MINOR N+2 / MAJOR | Removed; stub throws with replacement hint |

**Minimum duration:** **2 minor releases** between announcement and removal.

### Current deprecated (remove v3.0)

| Alias | Replacement |
|-------|-------------|
| `poriadok` | `revise` |
| `healthcheck` | `doctor` |
| `jarvis`, `dashboard`, `hack` | `home` |
| `menu`, `palette`, `nav` | `go` |
| `privacy` | `sec` |
| `cleanlogs` | `cleanup` |

---

## 6. Junction — срок поддержки

**Phase 2 introduces** `Config/homebase.defaults.json` + `Get-HomeBasePath`.

| Legacy path | Junction target | Supported until |
|-------------|-----------------|-----------------|
| `C:\Logs\Workstation` | `{RuntimeRoot}\Logs` | +12 months from Phase 2 GA |
| `C:\Backups\Workstation` | `{RuntimeRoot}\Backups` | +12 months |
| `C:\Configs\Workstation` | `{RuntimeRoot}\Configs` | +12 months |

**During grace:**

- Hardcoded scripts continue working via junction
- New code **must** use `Get-HomeBasePath`
- Doctor check warns when junction missing (target Phase 2)

**After grace (MAJOR v3.0):**

- Junctions optional; documented manual migration
- Hardcoded paths in user scripts — user responsibility

---

## 7. Migration paths (Phase 2)

### Step 0 — Before any change

```powershell
backupconfig
git checkout v2.0.0          # verify rollback works (optional drill)
doctor; trustcheck
```

### Step 1 — Deploy config (non-breaking)

1. Add `Config/homebase.defaults.json` with **current** paths (no move)
2. `Get-HomeBasePath` returns same values as hardcoded
3. Doctor PASS — behavior identical

### Step 2 — Opt-in new layout

1. Set `RuntimeRoot` in config (or `HOMEBASE_RUNTIME` env)
2. Run `Fix-WorkstationPath.ps1 -ApplyJunctions`
3. Verify junctions: `doctor`, `revise`

### Step 3 — Migrate writers

Replace hardcoded paths in code incrementally; one subsystem per PR.

### Step 4 — Verify

```powershell
Test-ReleaseVersion.ps1
doctor
revise
trustcheck
```

---

## 8. JSON migration

### SchemaVersion policy

| Version | Meaning |
|---------|---------|
| *(missing)* | v1 implicit — readers accept |
| `1` | Pre-charter reports |
| `2` | Charter era — additive fields |

**Rules:**

- Writers add `SchemaVersion` on next touch
- Readers **must** tolerate missing fields
- Renaming keys → new major SchemaVersion + MAJOR release
- Reports in `C:\Logs\Workstation\` — not in git

### Affected files

`validation-*.json`, `command-health.json`, `trust-report.json`, WOC cache, backup `manifest.json`

---

## 9. Command migration

### Registry-driven (target)

`Get-WorkstationCommandRegistry` fields:

```powershell
Lifecycle    = 'Deprecated'
Replacement  = 'revise'
DeprecatedIn = '2.1.0'
RemovedIn    = '3.0.0'
```

### User action

| Situation | Action |
|-----------|--------|
| Warning on deprecated cmd | Switch to Replacement |
| Script uses old name | Update or wait for alias period |
| Removed in v3 | Update script; read CHANGELOG migration section |

---

## 10. Profile migration

### Deploy path

`profile/Microsoft.PowerShell_profile.ps1` (repo) → `$PROFILE` (live) via `fixprofile`.

### Rules

| Change | Policy |
|--------|--------|
| Module import path | Shim at old path if repo moves (Phase 3) |
| Lazy load flag | PATCH ok if commands still resolve |
| New init step | MINOR — document in QUICKSTART |
| Remove init step | MINOR + deprecation period |

### Rollback profile

```powershell
restoreconfig                   # restores $PROFILE from backup
# or
fixprofile -Force               # redeploy from repo at current checkout
```

---

## 11. Backward compatibility guarantees (v2.x)

| Area | Guarantee |
|------|-----------|
| **Supported commands** | Names stable until deprecated per LIFECYCLE |
| **Deprecated commands** | Work until v3.0 MAJOR |
| **Hardcoded paths** | Work until junction grace ends |
| **JSON consumers** | Additive fields only in MINOR/PATCH |
| **Profile commands** | Available after `reloadprofile` |
| **Trust / doctor** | Stricter checks only with CHANGELOG notice |
| **Module name** | `KGreen.Workstation` until v3 alias period |

**Not guaranteed:**

- Experimental commands (`singularity`, `genesis`, …)
- Undocumented internal functions
- Hardcoded paths after junction grace
- WOC health score numeric parity (trust score is authoritative)

---

## 12. Related

- [ARCHITECTURE-FREEZE.md](./ARCHITECTURE-FREEZE.md)
- [LIFECYCLE.md](./LIFECYCLE.md)
- [VERSIONING.md](./VERSIONING.md)
- [SUPPORT-POLICY.md](./SUPPORT-POLICY.md)
- [RELEASE-CHECKLIST.md](./RELEASE-CHECKLIST.md)
- [adr/ADR-0007-path-configuration.md](./adr/ADR-0007-path-configuration.md)
