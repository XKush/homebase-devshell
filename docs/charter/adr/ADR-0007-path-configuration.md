# ADR-0007: Path Configuration

| | |
|---|---|
| **Status** | Proposed (Phase 2) |
| **Date** | 2026-06-29 |

## Context

Paths hardcoded: `C:\Logs\Workstation`, `C:\Backups\Workstation`, `$script:WSRoot`, etc.

## Problem

Blocks portable install and OSS adoption.

## Decision

1. Create `Config/homebase.defaults.json`:

```json
{
  "SchemaVersion": 1,
  "RuntimeRoot": "C:\\HomeBase",
  "Logs": "{RuntimeRoot}\\Logs",
  "Backups": "{RuntimeRoot}\\Backups",
  "Projects": "C:\\Projects"
}
```

2. `Get-HomeBasePath -Name Logs` — single accessor
3. Env override: `HOMEBASE_RUNTIME`
4. Junctions: legacy paths → new paths for 12 months
5. `Fix-WorkstationPath.ps1` v2 applies junctions

## Consequences

**Positive:** Fork-friendly, testable, documented

**Negative:** Every hardcoded path must migrate — high touch count

**Risk mitigation:** Phase 2 only; no behavior change until junctions verified
