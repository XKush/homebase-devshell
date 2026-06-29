# ADR-003: Privacy configuration score

## Status

Accepted

## Context

Users want a single number to track improvement. A misleading score erodes trust.

## Decision

Score reflects **weighted Windows/browser policy checks** from `Config/privacy.defaults.json`. It is **not** a measure of network anonymity, VPN safety, or threat model.

Risk labels: **Strong / Moderate / Weak configuration**.

## Consequences

- Configurable weights in JSON
- Reports include `disclaimer` field
- `devshell health` shows score under "Privacy Configuration"
