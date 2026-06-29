# ADR-001: PowerShell 7 only

## Status

Accepted

## Context

Windows dev tooling (winget, modern .NET, UTF-8 defaults) assumes PowerShell 7+. Supporting 5.1 doubles test matrix and blocks `#Requires -Version 7.0` features.

## Decision

HomeBase DevShell **requires PowerShell 7+**. Windows PowerShell 5.1 is not supported for product CLI (`devshell`, `install`, `doctor`).

## Consequences

- Smaller CI matrix
- Clear install message on PS5
- No `Invoke-Expression` workarounds for older syntax
