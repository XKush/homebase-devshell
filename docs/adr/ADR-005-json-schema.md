# ADR-005: JSON report schemas

## Status

Accepted

## Context

CI, Intune, and custom dashboards need machine-readable output.

## Decision

Product commands support `-Json`. Reports include explicit `reportSchemaVersion` or `healthSchemaVersion` (semver for schema, independent of product version).

## Consequences

- `Test-PrivacyAuditSmoke` validates schema
- Breaking schema changes bump schema version, not only product version
- HTML export is derived from same document model
