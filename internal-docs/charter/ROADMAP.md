# HOME BASE — Roadmap

Долгосрочная дорожная карта развития.

---

## v2.0 — NOW ✅ (Production-ready internal)

**Goal:** Stable command center with trust, anon, revise pipeline.

| Done | Item |
|------|------|
| ✅ | Trust VERIFIED 100/100 |
| ✅ | Doctor 75/75 |
| ✅ | Anon kit + audits |
| ✅ | Backup archive rotation |
| ✅ | Module Scope Global fix |
| ✅ | SelfCheck null-safe |
| ✅ | Charter Pack docs |

---

## Phase 0 — Charter (current)

| | |
|---|---|
| **Goal** | Constitution without code changes |
| **Tasks** | docs/charter/* complete |
| **Risk** | none |
| **Done when** | EXECUTIVE-SUMMARY signed off |

---

## Phase 1 — OSS Minimum ✅

| | |
|---|---|
| **Goal** | Public repo ready |
| **Tasks** | LICENSE, README, SECURITY, psd1 2.0.0, tag v2.0.0 |
| **Done** | tag `v2.0.0` |

---

## Phase 1.5 — Release Stabilization ✅

| | |
|---|---|
| **Goal** | Release process before risky Phase 2 |
| **Tasks** | Test-ReleaseVersion, checklist, support/compatibility/matrix |
| **Done when** | version script PASS; docs published |

---

## Phase 2 — Path configuration (in progress)

| | |
|---|---|
| **Goal** | Portable paths; runtime SSOT; documented closeout |
| **Done (so far)** | SSOT core, command queue 7/7, Integration Rehearsal PASS |
| **Remaining** | Waves A–E → Final Release Review → Step 2.5 → Final Integration Rehearsal |
| **Risk** | medium — wrong path breaks runtime |
| **Done when** | Runtime-Code = 0; junctions per Step 2.5; tag **v2.1.0** |

**Authoritative closeout:** [STEP-2-5-DECISION.md](./STEP-2-5-DECISION.md) · **Progress:** [PATH-MIGRATION-PROGRESS.md](./PATH-MIGRATION-PROGRESS.md)

**Freeze:** no new user commands until Phase 2 closeout ([ARCHITECTURE-FREEZE.md](./ARCHITECTURE-FREEZE.md)).

---

## v2.1 — Path migration release

MINOR: path SSOT complete, LegacyJunctions, psd1 ModuleVersion 2.1.0, release review signed off.

---

## v3 — Architecture vision (design only)

Post–v2.1.0 direction: [V3-ARCHITECTURE-VISION.md](./V3-ARCHITECTURE-VISION.md) — presentation, locale, declarative commands, plugins, CI/CD, module publication. **Not active work** during Phase 2.

---

## Phase 3 — Repository restructure

| | |
|---|---|
| **Goal** | Scripts/, Core/, Tests/ taxonomy |
| **Tasks** | move 50 root scripts, shim warnings at old paths |
| **Risk** | medium — broken relative paths |
| **Done when** | all entrypoints work; Validate pass |

---

## v2.2 — Structure release

MINOR: folder layout, path config stable.

---

## Phase 4 — Presentation layer

| | |
|---|---|
| **Goal** | Unified UI panel all commands |
| **Tasks** | Presentation.ps1, migrate home/revise/doctor/trust, RU Validate labels |
| **Risk** | low-medium — visual regressions |
| **Done when** | UI-STYLE-GUIDE compliance audit pass |

---

## v2.3 — UX release

MINOR: unified panels, locale SSOT start.

---

## Phase 5 / v3.0 — HOME BASE rename

| | |
|---|---|
| **Goal** | KGreen → HomeBase module, remove deprecated |
| **Tasks** | alias module, remove poriadok/jarvis after 2 minors warning |
| **Risk** | high if rushed |
| **Done when** | migration guide complete; 0 deprecated in Recommended |

---

## v3.5 — Plugin API preview

| | |
|---|---|
| **Goal** | Register-HomeBaseCommand extension |
| **Tasks** | plugin manifest schema, sample plugin |
| **Risk** | medium — security review plugins |

---

## v4.0 — Quality release

| | |
|---|---|
| **Goal** | Pester suite, split Core/Security modules |
| **Tasks** | unit tests, CI GitHub Actions |
| **Risk** | low |

---

## v5.0 — Platform

| | |
|---|---|
| **Goal** | Multi-machine sync, optional cloud backup adapter |
| **Tasks** | TBD |
| **Risk** | high — scope creep |

---

## Related

- [EXECUTION-PLAN.md](./EXECUTION-PLAN.md)
- [VERSIONING.md](./VERSIONING.md)
