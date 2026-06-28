# ADR-0005: Backup Strategy — Archive, Never Delete

| | |
|---|---|
| **Status** | Accepted |
| **Date** | 2026-06-29 |

## Context

`cleanlogs` historically deleted backup folders including `_Archive`. User lost pre-reboot snapshot.

## Problem

Destructive cleanup incompatible with «любое изменение можно откатить».

## Decision

1. Keep **8** active snapshots by `LastWriteTime`
2. Overflow → **Move** to `_Archive\`, never `Remove-Item`
3. `_Archive` excluded from rotation delete
4. `cleanup -WhatIf` mandatory in docs before real run
5. Align `Maintenance.ps1` with `Invoke-Housekeeping.ps1`

## Consequences

**Positive:** Recoverability, trust in cleanup command

**Negative:** Disk usage grows — user manages cold archive manually

**Related:** [BACKUP-POLICY.md](../BACKUP-POLICY.md)
