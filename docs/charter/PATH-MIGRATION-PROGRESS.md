# HOME BASE — Phase 2 Path Migration Progress

**Baseline compare:** [phase2-step1-stable.json](../baselines/phase2-step1-stable.json)  
**Product tag:** v2.0.0 · **LegacyJunctions:** disabled (Step 2.5)

---

## KPI (interim — after Commit 4)

| Metric | Current | Target | Notes |
|--------|--------:|-------:|-------|
| **Functional progress** | **43%** (3 / 7) | 100% | Command scripts in Step 2 queue (rows 1–7) on SSOT |
| **Technical progress** | **~48 files · ~110 literals** | 0 in runtime code | Grep: `C:\Logs\Workstation` \| `C:\Backups\Workstation` \| `C:\Configs\Workstation` in `*.ps1`; count drops as rows migrate |

*Functional* = share of queued command scripts migrated. *Technical* = remaining hardcoded runtime path literals (tests, baselines, SSOT fallbacks counted until removed in later passes).

---

## SSOT Progress

| # | Component | SSOT | Legacy Path | Gate Verified | Commit |
|---|-----------|------|-------------|---------------|--------|
| 1 | `Validate-Workstation.ps1` | ✅ | ❌ | ✅ | `55d0f8c` |
| 2 | `Invoke-SystemDiscovery.ps1` | ✅ | ❌ | ✅ | `1756617` |
| 3 | `Invoke-WorkstationRevision.ps1` | ✅ | ❌ | ✅ | `dcfd189` |
| 4 | `Invoke-Housekeeping.ps1` | ⏳ | ⏳ | — | — |
| 5 | `Invoke-TerminalRecovery.ps1` | ⏳ | ⏳ | — | — |
| 6 | `Sync-WorkstationDocs.ps1` | ⏳ | ⏳ | — | — |
| 7 | `Invoke-WorkstationOrganization.ps1` | ⏳ | ⏳ | — | — |
| 8 | Profile hints / `$PROFILE` refs | ⏳ | ⏳ | — | — |
| 9 | Install/configure scripts | ⏳ | ⏳ | — | — |

**Legend:** SSOT = uses `Get-HomeBasePath` / accessors · Legacy Path = no hardcoded runtime paths · Gate = full commit pipeline PASS

---

## Quality passports

Runtime: `C:\Logs\Workstation\Phase2\Commit\{hash}/`

| Commit | Component | Folder |
|--------|-----------|--------|
| `55d0f8c` | Validate-Workstation | *(pre-passport)* |
| `1756617` | Invoke-SystemDiscovery | `Phase2/Commit/1756617/` |
| `dcfd189` | Invoke-WorkstationRevision | `Phase2/Commit/dcfd189/` |

---

## Rules (active)

- **One Responsibility Per Commit**
- **Green Tree** — Phase 2 *commits* touch one migration file; WIP may stay on disk for doctor gate (see [PATH-MIGRATION-REVIEW.md](PATH-MIGRATION-REVIEW.md))
- **Stash:** `phase2-isolation` — WIP outside migration (see [PATH-MIGRATION-REVIEW.md](PATH-MIGRATION-REVIEW.md))
- **Commit forbidden** if `Invoke-Phase2CommitGate.ps1` FAIL
- **No LegacyJunctions** until Step 2.5

---

## Exit criteria (Phase 2 complete)

- [ ] 100% runtime path access via SSOT
- [ ] No new hardcoded `C:\Logs\Workstation` / `C:\Backups\Workstation` in working code
- [ ] All rows Gate Verified
- [ ] Legacy equivalence vs Step1-Stable (or updated stable)
- [ ] doctor 75/75 · trust VERIFIED
- [ ] Architecture docs updated
- [ ] Tag candidate **v2.1.0**
