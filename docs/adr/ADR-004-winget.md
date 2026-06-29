# ADR-004: Winget for optional packages

## Status

Accepted

## Context

Install and repair need a safe, official package source on Windows without bundling installers.

## Decision

Use **winget** with a **whitelist** of package IDs for `doctor -Fix` and `install -WithTools`. Core install does not require winget.

## Consequences

- No chocolatey/scoop in core path (templates exist for community)
- winget absence degrades gracefully with hints
- Repair never installs unsigned arbitrary URLs
