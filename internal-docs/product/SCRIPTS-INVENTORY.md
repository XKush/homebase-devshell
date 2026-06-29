# Scripts inventory — Test / Invoke / Configure / CHANGELOG

**Scope:** git-tracked root scripts · **Runtime A–D:** unchanged · **Moves:** Phase 2 only (path shims required)

---

## CHANGELOG (2 files — 1 real)

| File | Role | Verdict |
|------|------|---------|
| **`CHANGELOG.md`** (root) | Public product history (Keep a Changelog) | ✅ **Единственный canonical** |
| **`internal-docs/charter/CHANGELOG.md`** | Stub → ссылка на root | ✅ OK (не дублирует контент) |

**Статус:** `Test-ReleaseVersion.ps1` проверяет root `CHANGELOG.md`, pin в `install.ps1`, semver из `KGreen.Workstation.psd1`, и git tag — **PASS** на v2.0.0 (исправлено в `96fa237`).

---

## Test-* (6 в git)

| Script | Кто вызывает | Назначение | Категория |
|--------|--------------|------------|-----------|
| **`Test-WorkstationPlatformHardening.ps1`** | Release plan, platform contract | 11 hardening scenarios Wave A–D | 🔴 **Release gate — оставить в root** |
| **`Test-WorkstationCommands.ps1`** | CI, commit gate, upgrade, Singularity | Smoke module commands | 🟡 Maintainer / CI |
| **`Test-HomeBasePaths.ps1`** | Phase2 gate, integration rehearsal, baseline | SSOT paths vs legacy folders | 🟡 Phase 2 / maintainer |
| **`Test-LegacyEquivalence.ps1`** | Commit gate, baseline save, Step1 baseline | JSON baseline diff | 🟡 Phase 2 / maintainer |
| **`Test-ReleaseVersion.ps1`** | Integration rehearsal, commit gate | Version consistency | 🟡 Release helper (**OK — root CHANGELOG**)
| **`Test-RestoreRehearsal.ps1`** | Integration rehearsal | Backup restore dry-run | 🟡 Phase 2 / maintainer |

**Не в git (WIP, .gitignore):** `Test-MenuAudit.ps1`, `Test-MenuDeepAudit.ps1`, `Test-AnonymityKitAudit.ps1` — sandbox; `Validate-Workstation.ps1` всё ещё **warn** если их нет.

**Публичный пользователь:** только косвенно через `devshell doctor` → `Validate-Workstation.ps1`. Остальные Test-* — **не для README**.

---

## Configure-* (5 в git)

| Script | Install chain | Когда |
|--------|---------------|-------|
| **`Configure-GitIdentity.ps1`** | ✅ `Install-Workstation.ps1` always | Product install (default) |
| **`Configure-Privacy.ps1`** | Admin branch only | `-SkipAdmin` **пропускает** (product default) |
| **`Configure-Network.ps1`** | Admin branch only | То же |
| **`Configure-PgpIdentity.ps1`** | ❌ | Module `pgp` / toolkit |
| **`Configure-TorSecurity.ps1`** | ❌ | Module `sec` / Tor menu |

**OSS landing:** не упоминать Tor/PGP configure в README — advanced / `docs/ru/`.

**Product install path:** только Git identity из configure-семейства.

---

## Invoke-* (23 в git)

### A. Phase 2 / migration (archive mindset)

| Script | Note |
|--------|------|
| `Invoke-Phase2CommitGate.ps1` | Pre-commit pipeline |
| `Invoke-Phase2IntegrationRehearsal.ps1` | One-shot rehearsal |
| `Invoke-Phase2Step1Baseline.ps1` | Baseline capture |
| `Get-Phase2LegacyPathReport.ps1` | *(not Invoke but related)* |

→ **Phase 2:** `scripts/maintainer/phase2/` + root shims.

### B. Audits & reports (operator)

| Script |
|--------|
| `Invoke-CommandCenterAudit.ps1` |
| `Invoke-CommandCenterCI.ps1` |
| `Invoke-OrganizationAudit.ps1` |
| `Invoke-FinalAudit.ps1` |
| `Invoke-PostProductionAudit.ps1` |
| `Invoke-PostProductionValidation.ps1` |
| `Invoke-EnhancementReports.ps1` |
| `Invoke-TerminalAudit.ps1` |
| `Invoke-SystemDiscovery.ps1` |

### C. Daily maintenance (power user, in-shell)

| Script | Module tie-in |
|--------|----------------|
| `Invoke-Maintenance.ps1` | Scheduled task, WOC |
| `Invoke-Housekeeping.ps1` | Called by maintenance |
| `Invoke-WorkstationOrganization.ps1` | `organize` |
| `Invoke-WorkstationRevision.ps1` | `revise` / `poriadok` |
| `Invoke-TerminalRecovery.ps1` | `repairterminal` |
| `Invoke-HomeBaseUpgrade.ps1` | Stack upgrade |

### D. Pass / tune (batch operators)

| Script |
|--------|
| `Invoke-EnhancementPass.ps1` |
| `Invoke-MaxLevelPass.ps1` |
| `Invoke-WindowsTunePass.ps1` |

### E. Scheduled / background

| Script |
|--------|
| `Invoke-ScheduledTrustProbe.ps1` |
| `Invoke-AcceptanceTest.ps1` |

**Публичный DevShell:** **0** Invoke-* в product flow (`install` → `doctor` only).

---

## Сводка: что лишнее для OSS visitor

| Видно на GitHub root | Для stranger | Действие |
|----------------------|--------------|----------|
| 6× Test-* | 1 нужен (hardening) | Index in `scripts/README.md`; move Phase 2 later |
| 23× Invoke-* | 0 | Same |
| 5× Configure-* | 0–1 (git identity) | Document admin vs default |
| 2× CHANGELOG | 1 | Charter stub OK; fix Test-ReleaseVersion |

---

## Рекомендуемый порядок cleanup (без rewrite history)

1. **Fix** `Test-ReleaseVersion.ps1` paths (root CHANGELOG, DevShell README).  
2. **Expand** `scripts/README.md` — таблицы выше (done via this file link).  
3. **Phase 2 move** — `scripts/maintainer/{phase2,audit,maintenance}/` + one-line root stubs.  
4. **Optional archive** — `Invoke-Phase2IntegrationRehearsal.ps1` → `internal-docs/archive/` note only (script stays until shim).  
5. **Validate-Workstation** — убрать warn на WIP Menu tests или оставить .gitignore (local only).

---

## Safe vs unsafe

| Safe now | Unsafe without shims |
|----------|----------------------|
| Docs inventory (this file) | Moving any `.ps1` referenced by `$PSScriptRoot` |
| Fix Test-ReleaseVersion paths | Deleting Phase 2 scripts |
| Charter CHANGELOG stub | Merging root + charter content |
| .gitignore WIP tests | Changing Install-Workstation configure chain |

---

See also: [GIT-CLEANUP-AND-POLISH.md](GIT-CLEANUP-AND-POLISH.md) · [scripts/README.md](../../scripts/README.md)
