# ADR-0001: Repository vs Runtime Separation

| | |
|---|---|
| **Status** | Accepted |
| **Date** | 2026-06-29 |
| **Deciders** | HOME BASE Architecture |

## Context

HOME BASE code lives in `C:\Scripts\Workstation` but runtime state (logs, backups, validation JSON) lives in `C:\Logs\Workstation`, `C:\Backups\Workstation`, etc. ~80 files hardcode these paths.

## Problem

- Cannot fork/reinstall to different drive
- Open Source clone breaks without manual path edit
- Git repo polluted if logs accidentally committed

## Decision

1. **Repository** = source code, canonical profile, docs, assets only
2. **Runtime** = logs, backups, cache, live configs — **never in git**
3. Introduce `Config/homebase.defaults.json` + `Get-HomeBasePath` (Phase 2)
4. 12-month junction compatibility from legacy paths

## Consequences

**Positive:** Portable installs, clean OSS repo, clear backup scope

**Negative:** Migration effort, dual-path support during transition

**Compliance:** `.gitignore` must exclude all runtime roots
