# ADR-002: No anonymous mode

## Status

Accepted

## Context

Users may expect "privacy tools" to guarantee anonymity. That is impossible to verify on a general-purpose Windows desktop.

## Decision

We **do not** ship one-click anonymous mode, automatic Tor routing for all traffic, or marketing that implies invisibility.

Privacy features audit **OS and browser configuration** only, with explicit disclaimers.

## Consequences

- Labels use "Privacy Configuration" and "Strong/Moderate/Weak configuration"
- Tor/PGP remain optional advanced modules
- Honest positioning for security professionals
