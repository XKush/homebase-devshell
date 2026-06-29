# RFC process

**Request for Comments** — how large ideas enter HomeBase DevShell.

> Goal shift: we are not optimizing for “the biggest PowerShell toolkit.”  
> We are building a project **people trust** — through consistent decisions over time.

## Pipeline (order matters)

```
RFC (proposal, no code)
    ↓
Discussion (GitHub)
    ↓
Feedback (community + maintainers)
    ↓
ADR (if architecture/policy changes)
    ↓
Implementation (PR + tests)
```

**Not the reverse.** No plugin code, no new frozen CLI commands, no JSON schema breaks until an RFC is **Accepted**.

## When you need an RFC

| Need RFC | No RFC needed |
|----------|----------------|
| New plugin (Docker, WSL, VS Code, …) | Doc typo, troubleshooting line |
| New public CLI command | Bug fix in existing command |
| Breaking JSON / API change | Additive JSON field (minor) |
| Core health dashboard behavior change | Smoke test assertion |
| Platform orchestrator change | Internal refactor without behavior change |

Check [MANIFESTO](MANIFESTO.md) and [PROJECT-PRINCIPLES](PROJECT-PRINCIPLES.md) before drafting.

## RFC states

| State | Meaning |
|-------|---------|
| **Proposed** | Open for comment — do not implement |
| **Accepted** | Maintainers approved — implementation may start |
| **Rejected** | Will not pursue (reason documented) |
| **Superseded** | Replaced by a newer RFC |

## How to propose

1. Copy [RFC-0000-template.md](RFC-0000-template.md) → `RFC-NNNN-short-title.md`
2. Open a [Discussion](https://github.com/XKush/homebase-devshell/discussions) (category **Ideas**) linking the RFC
3. PR only the RFC markdown — **no product code** in the same PR
4. After acceptance, maintainer updates status → **Accepted**, then optional ADR, then implementation PRs

## Index

| RFC | Title | Status |
|-----|-------|--------|
| [RFC-0001](RFC-0001-docker-plugin.md) | Docker plugin | Proposed |
| [RFC-0002](RFC-0002-wsl-plugin.md) | WSL plugin | Proposed |

Accepted RFCs may reference ADRs in [../adr/](../adr/).

## Relationship to other docs

| Doc | Role |
|-----|------|
| **RFC** | *Should we?* — design proposal before code |
| **ADR** | *Why we did* — recorded decision after consensus |
| **ROADMAP** | *When we ship* — contract by version |
| **API-STABILITY** | *What we must not break* |
