# ADR-0008: Security Model

| | |
|---|---|
| **Status** | Accepted |
| **Date** | 2026-06-29 |

## Context

HOME BASE performs filesystem, registry, profile, PGP, firewall operations. Defender AV explicitly disabled.

## Problem

Destructive ops without standard chain caused data loss and trust failures.

## Decision

1. Mandatory chain: Validation → Backup → Confirm → Execute → Log → Rollback
2. Whitelist directories for `Remove-Item`
3. Archive-not-delete for backups
4. Admin ops require explicit elevation path
5. SHADOW OPS: Tor hardened + PGP identity audits in Validate
6. Document lab-use disclaimer for OSS

## Consequences

**Positive:** Predictable safety, OSS liability clarity

**Negative:** More verbose UX (-WhatIf, confirmations)

**Non-goal:** HOME BASE is not a SIEM or EDR replacement
