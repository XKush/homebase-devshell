# ADR-0002: Single Module with Global Scope

| | |
|---|---|
| **Status** | Accepted |
| **Date** | 2026-06-29 |

## Context

HOME BASE exposes 144 commands via `KGreen.Workstation.psm1`. Profile lazy-loads module. Child scripts (`Sync-WorkstationDocs`, `Invoke-WorkstationRevision`) also import module.

## Problem

`Import-Module -Force` from child script scope **unloaded** session module, causing:
- `Write-WorkstationStep` not found
- `Test-ShowCommandHelp` not found
- Trust UNTRUSTED «модуль не загружен»

## Decision

1. **Single module** `KGreen.Workstation` (rename to HomeBase in v3)
2. All imports via `Ensure-WorkstationModuleLoaded` with **`-Scope Global`**
3. Profile `Initialize-WorkstationModule` uses `-Scope Global`
4. Child scripts **never** raw `Import-Module -Force` without Ensure

## Consequences

**Positive:** Stable session commands, revise/trustcheck reliable

**Negative:** Module stays in session until removed (acceptable)

**Alternative rejected:** Multi-module split — deferred to v4
