# RFC-0001: Docker plugin

**Status:** Proposed  
**Author:** HomeBase DevShell maintainers  
**Created:** 2026-06-29  
**Discussion:** *(open an Ideas discussion when ready)*

---

## Summary

Optional **Docker** plugin under `plugins/Docker/` that adds container-runtime readiness checks to `devshell health` — without new frozen CLI commands.

## Motivation

Developers on Windows often have broken Docker Desktop, WSL2 backend, or stale context while the rest of the workstation passes `devshell health`. Today that gap is invisible.

Aligns with trust goal: **report what we can verify**, disclaim what we cannot (no image vulnerability scanning in v1).

## User experience

```powershell
devshell health          # includes Docker section when plugin installed
devshell health -Json    # plugin section in machine report
```

No `devshell docker` top-level command in v1 — health aggregation only.

## Design

### Scope

**In**

- Detect `docker` CLI on PATH
- Docker Desktop / engine reachable (`docker info` timeout-bounded)
- Optional: context name, WSL2 backend hint

**Out**

- Image CVE scanning
- Kubernetes / compose stack validation
- Auto-install Docker Desktop

### Integration

- `plugins/Docker/manifest.json` per [plugins/README.md](../../plugins/README.md)
- `doctor.ps1` invoked by health merger (post-acceptance design)
- JSON: new **optional** `sections.docker` object — additive only; schema minor bump if accepted

### Security & trust

- Read-only checks by default
- Any `repair.ps1` must be idempotent and documented; never pull arbitrary images
- Must pass MANIFESTO “no unverified software” rule

## Alternatives considered

| Option | Why not |
|--------|---------|
| Core built-in Docker checks | Violates v3.x “no core bloat”; Docker not universal |
| `devshell docker` command | Frozen API expansion — prefer health section |
| Ignore Docker | Leaves common dev pain unaddressed |

## Drawbacks

- Maintenance across Docker Desktop versions
- CI needs careful mocking (no Docker required on every runner)

## Unresolved questions

- [ ] Should plugin ship in main repo or separate repo first?
- [ ] Minimum checks for “PASS” vs “WARN”?
- [ ] Windows Home without Hyper-V — graceful INFO?

## Implementation plan (after acceptance only)

1. ADR: plugin manifest contract  
2. RFC acceptance → `plugins/Docker/` skeleton + manifest only  
3. Health merger + smoke test (mocked `docker`)  
4. No release until [RELEASE-CRITERIA](../RELEASE-CRITERIA.md) green  

**Status: Proposed — no implementation code until Accepted.**
