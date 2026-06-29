# RFC-0002: WSL plugin

**Status:** Proposed  
**Author:** HomeBase DevShell maintainers  
**Created:** 2026-06-29  
**Discussion:** *(open an Ideas discussion when ready)*

---

## Summary

Optional **WSL** plugin that reports Windows Subsystem for Linux readiness (distro installed, default version, integration with Docker backend) via `devshell health`.

## Motivation

WSL is a common dependency for Docker, Node, and Linux tooling on Windows. Failures are often silent until a tool fails mid-build.

Supports the product goal: **trust through visible configuration state**, not promises about Linux workload performance.

## User experience

```powershell
devshell health
```

Example section (illustrative):

```
WSL                    WARN
  Default: Ubuntu — WSL2 not default kernel
```

## Design

### Scope

**In**

- `wsl --status` / `wsl -l -v` parsing (offline, local)
- Default distro present
- WSL version (1 vs 2) per distro
- Optional cross-check: Docker Desktop WSL integration flag (if Docker RFC accepted)

**Out**

- Installing distros or running `wsl --install`
- Linux package audits inside guest
- Network tests to external sites

### Integration

- `plugins/WSL/manifest.json`
- Health section `wslConfiguration` (name TBD at acceptance)
- Additive JSON only

### Security & trust

- No elevation required for read-only listing
- `repair.ps1` limited to documented safe actions (e.g. suggest `wsl --set-default-version 2`) — never force reboot

## Alternatives considered

| Option | Why not |
|--------|---------|
| Fold into Docker plugin only | WSL useful without Docker |
| Core doctor checks | Not all DevReady users use WSL — plugin keeps core small |

## Drawbacks

- Output varies by Windows build and locale
- Parsing `wsl` text is fragile — prefer structured flags where available

## Unresolved questions

- [ ] Minimum Windows build support?
- [ ] How to test in CI without WSL enabled on runner?
- [ ] Merge order with RFC-0001 (Docker)?

## Implementation plan (after acceptance only)

1. Accept RFC-0002 (may proceed in parallel with RFC-0001 if both Accepted)
2. Plugin skeleton + mocked unit tests
3. Document limitations in section disclaimer (like Privacy Configuration)

**Status: Proposed — no implementation code until Accepted.**
