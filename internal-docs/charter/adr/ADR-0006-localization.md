# ADR-0006: Localization — RU-First, EN Secondary

| | |
|---|---|
| **Status** | Accepted |
| **Date** | 2026-06-29 |

## Context

Primary user RU. Code identifiers English. JSON reports English keys.

## Problem

Inline Russian in Private/*.ps1, English Validate output, EN README — inconsistent.

## Decision

1. **RU-first** all user-visible strings via locale files
2. **Never translate** command names, JSON keys, paths, API
3. Target API: `Get-HomeBaseString -Key …`
4. Sync help catalog → docs/ru/COMMANDS.md
5. EN docs mirror in Phase 1+ (`docs/en/`)

## Consequences

**Positive:** Coherent UX, OSS-ready i18n architecture

**Negative:** Migration of inline strings — Phase 4 workload

**Fallback:** key → en → literal key (dev warning)
