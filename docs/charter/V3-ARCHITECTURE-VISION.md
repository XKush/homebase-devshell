# HOME BASE v3 — Architecture Vision

**Status:** DESIGN ONLY · **Not in scope** until Phase 2 closeout complete  
**Product baseline:** v2.0.0 · **Target era:** post–v2.1.0 (after path migration, release review, LegacyJunctions)

---

## Purpose

This document defines **architectural goals** for a future HOME BASE generation. It is **not an implementation plan** and **must not drive Phase 2 work**. Its role is to preserve direction so decisions after Phase 2 follow a agreed vision instead of ad-hoc choices.

Phase 2 remains the only active engineering track until:

```
Wave A → … → Wave E → Final Release Review → Step 2.5 → Final Integration Rehearsal → v2.1.0
```

See [STEP-2-5-DECISION.md](./STEP-2-5-DECISION.md) and [PATH-MIGRATION-PROGRESS.md](./PATH-MIGRATION-PROGRESS.md).

---

## Vision statement

HOME BASE evolves from a **mature personal workstation platform** (formal change lifecycle, quality gates, documented decisions) into a **portable, extensible PowerShell platform** suitable for broader adoption — without sacrificing the discipline established in Phase 1–2.

---

## Architectural goals (v3 era)

| # | Goal | Intent |
|---|------|--------|
| 1 | **Unified Presentation Layer** | Single UI surface for commands (panels, progress, errors) — consolidates today’s scattered formatting |
| 2 | **Localization (RU/EN)** | User-visible strings via dictionaries; no inline locale mixing in logic |
| 3 | **Declarative commands** | Command metadata (name, category, params, gates) described in data; runtime interprets |
| 4 | **Extensible configuration** | Layered config beyond paths: features, defaults, environment profiles |
| 5 | **Plugin model** | `Register-HomeBaseCommand` (or equivalent) with manifest, sandbox, trust review |
| 6 | **CI/CD + automated gates** | Quality gates (doctor, trust, path report, release version) in pipeline — not manual-only |
| 7 | **Published PowerShell module** | First-class `Install-Module` / gallery-ready packaging, semver, support matrix |

These align with phases already named in [ROADMAP.md](./ROADMAP.md) (Presentation, plugins, quality release) but are **re-framed as one coherent v3 target** rather than isolated minors.

---

## Non-goals (for v3 design phase)

- No commitment to timeline or version numbers beyond “after v2.1.0”
- No API contracts until Phase 2 exit + Final Release Review
- No new user commands during Phase 2 closeout ([ARCHITECTURE-FREEZE.md](./ARCHITECTURE-FREEZE.md))

---

## Relationship to current roadmap

| Era | Focus |
|-----|--------|
| **v2.0.0** ✅ | Stable internal platform, charter, trust/doctor/anon |
| **Phase 2 (in progress)** | Path SSOT, waves A–E, release review, junctions, v2.1.0 |
| **v3 vision (this doc)** | Presentation, locale, declarative commands, plugins, CI, module publication |

Legacy [ROADMAP.md](./ROADMAP.md) phases 3–5 remain valid **directionally**; this vision may supersede their ordering when Phase 2 closes and a formal v3 execution plan is written.

---

## Maturity snapshot (pre–v2.1.0)

Subjective assessment at Integration Rehearsal PASS — for historical context only:

| Dimension | Score | Notes |
|-----------|------:|-------|
| Internal (production) use | **9.8 / 10** | Mature, controlled change lifecycle |
| Open Source readiness | **8.5 / 10** | Phase 1 docs/process strong; runtime migration incomplete |
| Ready for v2.1.0 | **No** | Waves + Final Release Review + Step 2.5 + Final Integration Rehearsal first |

---

## When to activate this vision

After **v2.1.0** tag and updated architecture freeze lift:

1. Draft **v3 Execution Plan** (ADR-style, gated like Phase 2)
2. Reconcile with ROADMAP phases 3–5 or replace with v3 plan
3. Explicit **Architecture Freeze v3** before first v3 feature commit

Until then: **design references only** — no code, no new commands, no scope creep into Phase 2 waves.

---

## Related

- [STEP-2-5-DECISION.md](./STEP-2-5-DECISION.md) — Phase 2 closeout order
- [ARCHITECTURE-FREEZE.md](./ARCHITECTURE-FREEZE.md) — active constraints
- [ROADMAP.md](./ROADMAP.md) — long-term phases
- [Integration-Rehearsal.md](./Integration-Rehearsal.md) — platform integration PASS
