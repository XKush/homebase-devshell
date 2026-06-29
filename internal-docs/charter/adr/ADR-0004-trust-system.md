# ADR-0004: Trust System Design

| | |
|---|---|
| **Status** | Accepted |
| **Date** | 2026-06-29 |

## Context

`home` dashboard shows health/trust. Users must know if UI is truthful after profile drift, broken commands, or stale caches.

## Problem

Without live verification, dashboard becomes cosmetic.

## Decision

1. `Get-SystemTrustReport -Live -Save` on strict mode startup
2. `CanTrustDashboard = false` when broken selfcheck or module missing
3. Score formula: penalties for broken commands, stale health cache, validation fails
4. `honestScore = min(wocScore, trustScore)` on home
5. `Save-CommandHealthCache` before trust probe in revise

## Consequences

**Positive:** «HOME BASE не врёт» principle enforced

**Negative:** STALE/WOC confusion (health 88%, trust 100%) — document in UI

**Modes:** `WORKSTATION_TRUST_MODE=strict|normal|fast`
