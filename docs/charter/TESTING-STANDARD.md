# HOME BASE — Testing Standard

Test pyramid и критерии качества HOME BASE.

---

## 1. Test pyramid

```
                    ┌─────────────┐
                    │   Release   │  Invoke-AcceptanceTest
                    │   Gate      │  tag + manual smoke
                    └──────┬──────┘
               ┌───────────┴───────────┐
               │  Trust + Doctor       │  trustcheck -Live
               │  Integration          │  revise full
               └───────────┬───────────┘
          ┌────────────────┴────────────────┐
          │  Validation Layer               │
          │  Validate-Workstation (75)        │
          │  Test-WorkstationCommands         │
          │  Test-MenuDeepAudit               │
          └────────────────┬────────────────┘
     ┌───────────────────────┴───────────────────────┐
     │  Smoke / SelfCheck                            │
     │  Invoke-AllCommandSelfChecks (72/72)          │
     │  Module load, help param exists               │
     └───────────────────────────────────────────────┘
```

**Gap (planned):** Pester unit tests for pure functions.

---

## 2. Layers

### 2.1 Smoke

| Test | Script | Pass criteria |
|------|--------|---------------|
| Module load | profile + Import-Module | no error |
| SelfCheck | Invoke-AllCommandSelfChecks | 72/72 OK |
| Core commands exist | Validate aliases section | all found |

### 2.2 Unit (target v4)

| Target | Examples |
|--------|----------|
| Scoring | Get-SystemTrustReport score math |
| Paths | Get-WorkstationStandardFolders |
| Panel format | Format-HomeBasePanel output |

Framework: **Pester 5+**

### 2.3 Integration

| Test | Pass |
|------|------|
| `revise -Quick` | completes, trust logged |
| `revise` full | doctor 75/75, trust VERIFIED |
| Menu audit | Test-MenuAudit.ps1 exit 0 |
| Anon audit | Test-AnonymityKitAudit exit 0 |

### 2.4 Validation

| Test | Pass |
|------|------|
| Validate-Workstation | FailCount = 0 |
| Profile load | ≤600ms headless |
| Command center render | ≤1000ms |

### 2.5 Doctor

Invoked via `doctor` or inside `revise`.

**Pass:** 75/75, JSON report written.

### 2.6 Trust

**Pass:**

- `Level = VERIFIED`
- `Score = 100`
- `CanTrustDashboard = true`
- `SelfChecksPassed = SelfChecksTotal`

**Acceptable transient:** STALE 94+ → run `Save-CommandHealthCache` / `trustcheck`.

### 2.7 Release gate

Before tag `vX.Y.Z` — full procedure: [RELEASE-CHECKLIST.md](./RELEASE-CHECKLIST.md).

```powershell
# 1. Version sync (Phase 1.5)
pwsh -File Test-ReleaseVersion.ps1

# 2. Runtime gate
doctor
trustcheck
Test-MenuDeepAudit.ps1
Test-WorkstationCommands.ps1    # or -Quick for PATCH
revise -Quick                     # or full revise for MINOR+
```

All exit 0 / VERIFIED. Requirements by release type: [RELEASE-REQUIREMENTS.md](./RELEASE-REQUIREMENTS.md).

---

## 3. CI entry (target)

`Invoke-HomeBaseCI.ps1`:

1. Test-MenuAudit
2. Validate-Workstation -StartupBudgetMs 600
3. Test-WorkstationCommands -Quick
4. trustcheck (headless)

---

## 4. Test data

- Use `$env:CI='1'`, `WORKSTATION_JARVIS='0'` in subprocess probes
- Never run destructive tests against real backups
- Use `-WhatIf` in command health safe exec where applicable

---

## 5. Reporting

| Output | Path |
|--------|------|
| Validation | `validation-*.json` |
| Command health | `command-health.json` |
| Trust | `trust-report.json` |
| Menu audit | exit code + console |

---

## 6. Related

- [COMMAND-STANDARD.md](./COMMAND-STANDARD.md)
- [VERSIONING.md](./VERSIONING.md)
