# ADR-0003: Presentation Layer Unification

| | |
|---|---|
| **Status** | Proposed (Phase 4) |
| **Date** | 2026-06-29 |

## Context

Three parallel UI stacks exist:
- `Write-WorkstationStep` (`==>`)
- `HackerUI` (`[HOME BASE]`, `[++]`)
- Validate ASCII box (English)

## Problem

Inconsistent UX, OSS contributors don't know which to use, Russian/English mix.

## Decision

1. Define canonical panel in [UI-STYLE-GUIDE.md](../UI-STYLE-GUIDE.md)
2. Phase 4: implement `Show-HomeBasePanel -Kind …`
3. Migrate commands incrementally; keep HackerUI as implementation detail
4. **No direct Write-Host** in new code

## Consequences

**Positive:** Professional OSS appearance, single maintenance point

**Negative:** Large visual diff; user habituation to old formats

**Migration:** Alias old functions during v2.3
