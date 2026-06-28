# HOME BASE — Phase 2 Path Migration Progress

**Baseline compare:** [phase2-step1-stable.json](../baselines/phase2-step1-stable.json)  
**Product tag:** v2.0.0 · **LegacyJunctions:** disabled (Step 2.5)

---

## KPI (mid-phase — automated)

Run: `Get-Phase2LegacyPathReport.ps1 -SaveJson` · JSON: `Logs/Phase2/legacy-path-report.json`

| Metric | Current | Target | Notes |
|--------|--------:|-------:|-------|
| **Functional progress** | **86%** (6 / 7) | 100% | Command scripts in Step 2 queue (rows 1–7) on SSOT |
| **Runtime literals** | **109** | **0** | Layer `Runtime-Code` from legacy path report |
| **Total literals** | **173** | tests/docs/fallback only | All layers; see [PATH-MIGRATION-MID-REVIEW.md](PATH-MIGRATION-MID-REVIEW.md) |

*Refresh KPI after each migration commit via `Get-Phase2LegacyPathReport.ps1`.*

---

## SSOT Progress

| # | Component | SSOT | Legacy Path | Gate Verified | Commit |
|---|-----------|------|-------------|---------------|--------|
| 1 | `Validate-Workstation.ps1` | ✅ | ❌ | ✅ | `55d0f8c` |
| 2 | `Invoke-SystemDiscovery.ps1` | ✅ | ❌ | ✅ | `1756617` |
| 3 | `Invoke-WorkstationRevision.ps1` | ✅ | ❌ | ✅ | `dcfd189` |
| 4 | `Invoke-Housekeeping.ps1` | ✅ | ❌ | ✅ | `befc920` |
| 5 | `Invoke-TerminalRecovery.ps1` | ✅ | ❌ | ✅ | `10e304b` |
| 6 | `Sync-WorkstationDocs.ps1` | ✅ | ❌ | ✅ | `378abac` |
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
| `befc920` | Invoke-Housekeeping | `Phase2/Commit/befc920/` |
| `10e304b` | Invoke-TerminalRecovery | `Phase2/Commit/10e304b/` |
| `378abac` | Sync-WorkstationDocs | `Phase2/Commit/378abac/` |

---

## Rules (active)

- **One Responsibility Per Commit**
- **Green Tree** — Phase 2 *commits* touch one migration file; WIP may stay on disk for doctor gate (see [PATH-MIGRATION-REVIEW.md](PATH-MIGRATION-REVIEW.md))
- **Stash:** `phase2-isolation` — WIP outside migration (see [PATH-MIGRATION-REVIEW.md](PATH-MIGRATION-REVIEW.md))
- **Commit forbidden** if `Invoke-Phase2CommitGate.ps1` FAIL
- **No LegacyJunctions** until Step 2.5

---

## Exit criteria (Phase 2 complete)

Refined mid-phase — full rationale in [PATH-MIGRATION-MID-REVIEW.md](PATH-MIGRATION-MID-REVIEW.md).

- [ ] **Runtime-Code layer = 0** legacy literals (`Get-Phase2LegacyPathReport.ps1`)
- [ ] Allowed non-zero literals only in Tests-Gates, Documentation, SSOT-Definition, Legacy-Fallback
- [ ] Rows 1–7 SSOT ✅ + Gate Verified
- [ ] Legacy equivalence vs Phase2-Step1-Stable
- [ ] doctor 75/75 · trust VERIFIED · all commit gates PASS
- [ ] **LegacyJunctions disabled** until Step 2.5
- [ ] Architecture docs updated · tag candidate **v2.1.0**
