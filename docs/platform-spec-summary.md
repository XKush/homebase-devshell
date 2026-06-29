# Platform Spec — Summary (v1.0.0 LOCKED)

One-page reference for contributors. Full spec: [PLATFORM-SPEC-SIGNOFF.md](../charter/PLATFORM-SPEC-SIGNOFF.md).

---

**HomeBase DevShell** ships a frozen execution platform:

- **Wave A–B:** profile bootstrap, orchestrator, command registry, router  
- **Wave C:** events (in-memory), trace (read-only join), capability observability  
- **Wave D:** extensions (register → sandbox → event bridge)

**Rules:**

- One event lifecycle contract (`*.start` / `*.success` / `*.fail`)
- Three registries: core commands, extensions, events (separate from module catalog)
- Extensions can run; they cannot control routing or orchestration

**Unlock:** explicit spec version bump + hardening PASS — not ordinary product releases.

Product version (`2.0.0`) and platform spec (`1.0.0`) are independent.
