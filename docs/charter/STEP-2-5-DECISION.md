# Phase 2 — Step 2.5 Decision (LegacyJunctions)

**Date:** 2026-06-29 · **Commit HEAD:** `0b442d1` (Integration Rehearsal) · **Baseline:** Phase2-Step1-Stable · **Product:** v2.0.0

---

## Current state

| Check | Status |
|-------|--------|
| Integration Rehearsal | **PASS** |
| Legacy Equivalence | **PASS** |
| Command script queue (7/7) | **Migrated to SSOT** |
| Runtime literals (post-rehearsal) | **114** |
| LegacyJunctions | **NOT ENABLED** |

**Artifacts:** `Phase2-Completion-Passport.json`, `Integration-Rehearsal.md`, `legacy-path-report.json` under `C:\Logs\Workstation\Phase2\`.

---

## Decision

**LegacyJunctions — NOT ENABLED**

### Reason

Remaining **runtime migration waves** must complete first. Junction is a **compatibility mechanism**; it belongs at the end of the path migration, when the new runtime is essentially ready — not while active runtime components still carry hardcoded paths.

Integration Rehearsal PASS confirms platform health and architectural equivalence **today**. It does **not** authorize enabling junctions before the remaining waves.

---

## Phase 2 closeout roadmap (authoritative)

**Policy:** No new user-facing commands until this sequence completes. Feature WIP stays in stash; only path-migration waves and release artifacts ship.

Previous mental model:

```
Phase 2 → Step 2.5 → Remaining literals → v2.1.0
```

**Adopted order:**

```
Phase 2 (command queue + Integration Rehearsal PASS)
    │
    ├── Wave A — Profile
    ├── Wave B — Module
    ├── Wave C — Install
    ├── Wave D — Fallback
    ├── Wave E — Tests
    │
    ├── Final Release Review
    ├── Step 2.5 (LegacyJunctions)
    ├── Final Integration Rehearsal
    └── v2.1.0
```

Future direction (design only, no Phase 2 impact): [V3-ARCHITECTURE-VISION.md](./V3-ARCHITECTURE-VISION.md).

---

## Remaining runtime work — by wave

Do not track progress as a single “114 literals” number. Each wave follows the established discipline: **baseline → migration → gate → passport → review**.

| Wave | Layer | Scope (examples) |
|------|-------|------------------|
| **A** | Profile | Shell profile hints, path literals in profile install/sync |
| **B** | Module | `modules/**` runtime path usage |
| **C** | Install | Install/configure scripts, first-run paths |
| **D** | Fallback | Explicit `Get-HomeBasePath` else branches — dedicated removal pass |
| **E** | Tests | Gate/compare targets only where still hardcoded (not SSOT definitions) |

**Phase 2 exit target (unchanged):** Runtime-Code layer = **0** hardcoded workstation paths in active runtime.

---

## When to enable LegacyJunctions (Step 2.5)

All three conditions must be met:

1. **SSOT everywhere in runtime** — all runtime components resolve paths through `Get-HomeBasePath` / accessors (no new hardcoded paths in active runtime).
2. **Migration report clean for runtime** — `Get-Phase2LegacyPathReport` shows no unexpected literals in the Runtime-Code layer.
3. **Pre–Step 2.5 Integration Rehearsal PASS** — full Stages 0–4 after Wave E (first rehearsal already PASS at command-queue milestone).

**After Step 2.5:** run **Final Integration Rehearsal** (same orchestrator, updated passport) immediately before **v2.1.0** tag.

---

## References

- `docs/charter/Integration-Rehearsal.md` — Integration Rehearsal report (PASS)
- `docs/charter/PATH-MIGRATION-FINAL-REVIEW.md` — command queue complete stop
- `docs/charter/PATH-MIGRATION-PROGRESS.md` — KPI and commit table
- `Invoke-Phase2IntegrationRehearsal.ps1` — orchestrator for repeat runs
- `V3-ARCHITECTURE-VISION.md` — post–v2.1.0 design goals (no Phase 2 impact)
