# Phase 2 Step 2 — Interim Architectural Review

**After Commit 4** (`dcfd189` — `Invoke-WorkstationRevision.ps1`)  
**Date:** 2026-06-29 · **Baseline:** Phase2-Step1-Stable · **Product:** v2.0.0

---

## Summary

Four migration commits are complete for **top-level command scripts** (3 path refactors + 1 gate infra). Runtime path access in those files now goes through `Get-WorkstationLogsRoot` / `Get-WorkstationBackupsRoot` (backed by `Get-HomeBasePath`). Legacy equivalence, doctor **75/75**, and trust **VERIFIED 100** held through Commit 4.

Quality passport: `C:\Logs\Workstation\Phase2\Commit\dcfd189\`

---

## SSOT coverage (command scripts)

| Status | Count | Files |
|--------|------:|-------|
| ✅ Migrated | 3 | `Validate-Workstation.ps1`, `Invoke-SystemDiscovery.ps1`, `Invoke-WorkstationRevision.ps1` |
| ⏳ Queued | 4 | `Invoke-Housekeeping.ps1`, `Invoke-TerminalRecovery.ps1`, `Sync-WorkstationDocs.ps1`, `Invoke-WorkstationOrganization.ps1` |
| ⏳ Later | 2+ | Profile hints, install/configure scripts |

**Approx. command-script progress:** 3 / 7 ≈ **43%** (excluding profile/install wave).

---

## Remaining hardcoded runtime paths (grep snapshot)

Roughly **~45** `.ps1` files still contain `C:\Logs\Workstation`, `C:\Backups\Workstation`, or `C:\Configs\Workstation`. Many are expected:

| Category | Examples | Notes |
|----------|----------|-------|
| SSOT / tests / baselines | `HomeBasePaths.ps1`, `Test-HomeBasePaths.ps1`, `Test-LegacyEquivalence.ps1`, `WorkstationFolders.ps1` | Expected literals or compare targets |
| Fallback defaults | `Common.ps1`, `WorkstationCommon.ps1`, `WorkstationOperationsCenter.ps1` | `if (Get-Command Get-HomeBasePath)` pattern — keep until Step 2.5 |
| **Migration queue** | Housekeeping, TerminalRecovery, Sync-WorkstationDocs, Organization | Next commits |
| Module / lib depth | `MenuSystem.ps1`, `Network.ps1`, `BootCheck.ps1`, … | After command scripts or batched by area |
| Install / audit / terminal | `Install-*.ps1`, `Invoke-*Audit.ps1`, `omp-*.ps1` | Last wave per charter |

---

## Repeated migration pattern (stable)

Every successful command-script commit followed the same template:

```powershell
. "$PSScriptRoot\lib\WorkstationCommon.ps1"

$logsRoot    = Get-WorkstationLogsRoot
$backupsRoot = Get-WorkstationBackupsRoot   # when backups referenced
# … replace 'C:\Logs\Workstation\…' / 'C:\Backups\Workstation' with $logsRoot / $backupsRoot
```

**No new helper required yet** — `Get-WorkstationLogsRoot` / `Get-WorkstationBackupsRoot` already wrap SSOT and match doctor expectations.

Optional future doc-only addition: a one-line comment block in `PATH-MIGRATION-PROGRESS.md` pointing to this template (not a new function).

---

## Process lessons (Commit 4)

1. **Green tree vs doctor gate:** Stashing unrelated WIP removed runtime dependencies (`MenuSystem.ps1`, stashed `Shell.ps1` / `CommandPalette.ps1`) required for **75/75**. For gate runs, either keep a **gate sandbox** (full WIP on disk, zero staged) or document **pre-gate restore** of stash — without mixing into the migration commit.
2. **Stale validation JSON:** `Test-LegacyEquivalence` reads the latest `validation-*.json`. A failed doctor run blocks the gate until a fresh **75/75** report exists.
3. **Profile sync:** `Install-ShellProfile.ps1` was needed once to flip “live profile drift” WARN → PASS (+1 doctor check).

---

## Recommendation before Commit 5

1. **Do not** start `Invoke-Housekeeping.ps1` until WIP isolation strategy is explicit for the next gate (stash pop → gate → commit one file → re-stash).
2. Keep **one file per commit** for the four queued command scripts.
3. After command scripts, plan a **module/lib batch review** — many files share the same fallback pattern; consider a single “remove redundant fallback literals” pass only after 100% SSOT wiring (Step 2.5 still separate).
4. Commit **separately** (not mixed with path migrations): enriched `Invoke-Phase2CommitGate.ps1` manifest, this review, `PATH-MIGRATION-PROGRESS.md`.

---

## Next commit candidate

**Commit 5:** `Invoke-Housekeeping.ps1` — same infra-only rules as Commits 1–4.
