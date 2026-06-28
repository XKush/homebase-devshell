# HOME BASE — Architecture

Архитектурная спецификация HOME BASE v2.0.

---

## 1. Обзор

HOME BASE — **layered command center** на PowerShell 7:

```
┌─────────────────────────────────────────────────────────┐
│                        User                              │
│              home · go · doctor · anon · …               │
└─────────────────────────┬───────────────────────────────┘
                          │
┌─────────────────────────▼───────────────────────────────┐
│                   Presentation Layer                       │
│         HackerUI · panels · locale/ru · errors            │
└─────────────────────────┬───────────────────────────────┘
                          │
┌─────────────────────────▼───────────────────────────────┐
│              KGreen.Workstation (Module)                   │
│   Public: Shell, Maintenance, Diagnostics, HomeBase…      │
│   Private: Menu, Trust, SelfCheck, Security…             │
└───────────┬─────────────────────────────┬───────────────┘
            │                             │
┌───────────▼──────────┐      ┌───────────▼───────────────┐
│        Core/lib       │      │   Root Scripts           │
│ WorkstationCommon     │      │ Validate, Backup, Install│
│ WorkstationFolders    │      │ Housekeeping, Revision…    │
│ WOC, AnonymityKit     │      └──────────────────────────┘
└───────────┬──────────┘
            │
┌───────────▼──────────────────────────────────────────────┐
│                      Runtime                              │
│  Logs · Backups · Cache · Configs · Registry · FS         │
└──────────────────────────────────────────────────────────┘
```

---

## 2. Repository vs Runtime

### Repository (git)

| Путь | Содержимое |
|------|------------|
| `C:\Scripts\Workstation\` | Исходный код, module, profile canonical |
| `modules/` | KGreen.Workstation + components |
| `lib/` | Shared libraries |
| `profile/` | Canonical Microsoft.PowerShell_profile.ps1 |
| `terminal/` | OMP themes, WT template |
| `docs/` | Документация + charter |

**Не хранится в git:** logs, backups, validation JSON, user secrets.

### Runtime (machine state)

| Путь | Назначение |
|------|------------|
| `C:\Logs\Workstation\` | Logs, validation, trust, WOC cache |
| `C:\Backups\Workstation\` | Config snapshots, `_Archive`, `pgp/` |
| `C:\Configs\Workstation\` | fastfetch, exported configs |
| `$PROFILE` (live) | Deployed profile |
| `%LOCALAPPDATA%\...\settings.json` | Windows Terminal live |

**Целевое состояние (v2.2):** `Config/homebase.defaults.json` + env `HOMEBASE_RUNTIME`.

**Миграция:** junctions со старых путей, 12 месяцев совместимости (ADR-0007).

---

## 3. Модульная архитектура

### Единственный модуль: `KGreen.Workstation.psm1`

```
Preload: lib/WorkstationFolders.ps1, lib/AnonymityKit.ps1

Load order (33 components):
  Private/Common → locale → HackerUI → Help → SelfCheck →
  BootCheck → MenuSystem → Security → Shell → Diagnostics →
  Maintenance → HomeBase → …
```

**Exports:** 144 functions + `WSRoot`, `WSLog`, `WSOwner`.

### Слои ответственности

| Слой | Файлы | Ответственность |
|------|-------|-----------------|
| **Infrastructure** | Private/Common, SelfCheck, TrustSystem | Cmd wrapper, logging, trust |
| **Presentation** | HackerUI, locale/ru | UI output |
| **Domain** | Shell, Maintenance, Diagnostics, Network | User commands |
| **Security** | Pgp, TorSecurity, PrivacyMenu, AnonymityKit | SHADOW OPS |
| **Orchestration (root)** | Validate, Revision, Backup scripts | Batch pipelines |

---

## 4. Загрузка профиля

```
Profile start (~240ms)
    │
    ├─ Encoding, env, FASTFETCH_CONFIG
    ├─ Initialize-WorkstationModule (lazy, first prompt)
    │       └─ Import-Module KGreen.Workstation -Scope Global
    │
    └─ Prompt hook:
           ├─ Show-HomeBase (if JARVIS enabled)
           ├─ Initialize-WorkstationSession (OMP, zoxide, hotkeys)
           └─ cd C:\Projects if started in System32
```

**Правила:**

- Lazy load — быстрый cold start
- **Global scope** — child scripts не ломают module (ADR-0002)
- `reloadprofile` → `. $PROFILE` + Ensure-Module

---

## 5. Жизненный цикл команды

```
Draft → Experimental → Stable → Recommended → Deprecated → Removed
```

| Фаза | Registry | Menu | Tests |
|------|----------|------|-------|
| Draft | internal | hidden | none |
| Experimental | yes | optional | smoke |
| Stable | yes | category | integration |
| Recommended | yes | [следующий] | full |
| Deprecated | yes + warning | hidden | maintained |
| Removed | alias only | no | n/a |

См. [LIFECYCLE.md](./LIFECYCLE.md)

---

## 6. Потоки данных

### home

```
Show-HomeBase
  → Get-SystemTrustReport (-Live -Save)
  → Build-WocReport
  → honestScore = min(woc, trust)
  → recommendations
```

### revise

```
Invoke-WorkstationRevision.ps1
  → Fix-WorkstationPath
  → Sync-WorkstationDocs (Ensure-Module!)
  → Validate-Workstation (doctor)
  → Save-CommandHealthCache
  → Get-SystemTrustReport
  → Show-SecurityStatusPanel
  → next actions
```

### trust

```
Get-SystemTrustReport -Live
  → module check
  → Invoke-AllCommandSelfChecks
  → Get-WorkstationCommandHealth
  → profile hash
  → command-health.json age
  → validation JSON
  → score + level → trust-report.json
```

---

## 7. Dependency graph (упрощённо)

```
profile ──► KGreen.Workstation
                ├── Private/Common ──► Invoke-WorkstationCmd
                ├── TrustSystem ──► SelfCheck, command-health.json
                ├── MenuSystem ──► HelpSystem, AnonymityKit
                └── HomeBase ──► WOC (lib/WorkstationOperationsCenter.ps1)

Validate-Workstation.ps1 ──► WorkstationCommon (subprocess probes)
Invoke-WorkstationRevision ──► Sync-WorkstationDocs ──► Ensure-Module
```

**SPOF:** module load failure → `repairterminal`  
**No circular deps detected.**

---

## 8. Target structure (v2.2+)

```
HomeBase/
├── Core/
├── Modules/HomeBase/
├── Scripts/{Install,Configure,Maintenance,Audit}/
├── Tests/
├── Assets/Terminal/
├── Profiles/
├── Config/homebase.defaults.json
└── Docs/charter/
```

Текущая flat structure — **technical debt**, migration Phase 3.

---

## 9. ADR index

| ADR | Topic |
|-----|-------|
| [ADR-0001](./adr/ADR-0001-repository-vs-runtime.md) | Repository vs Runtime |
| [ADR-0002](./adr/ADR-0002-single-module-global-scope.md) | Single Module |
| [ADR-0003](./adr/ADR-0003-presentation-layer.md) | Presentation Layer |
| [ADR-0004](./adr/ADR-0004-trust-system.md) | Trust System |
| [ADR-0005](./adr/ADR-0005-backup-strategy.md) | Backup Strategy |
| [ADR-0006](./adr/ADR-0006-localization.md) | Localization |
| [ADR-0007](./adr/ADR-0007-path-configuration.md) | Path Configuration |
| [ADR-0008](./adr/ADR-0008-security-model.md) | Security Model |

---

## 10. Связанные документы

- [PHILOSOPHY.md](./PHILOSOPHY.md)
- [EXECUTION-PLAN.md](./EXECUTION-PLAN.md)
- [docs/ru/TRUST.md](../ru/TRUST.md)
