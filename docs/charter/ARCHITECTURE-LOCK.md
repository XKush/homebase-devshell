# HOME BASE — Architecture Lock (Wave A–D)

**Status:** **LOCKED** · **Spec:** [`PLATFORM-SPEC-SIGNOFF.md`](./PLATFORM-SPEC-SIGNOFF.md) v`1.0.0` · **Signed:** 2026-06-29

Quick reference. Authoritative spec: **Platform Spec Sign-off**.

---

## 1. Layer stack (frozen order)

```
ENTRYPOINT (profile loader — dot-source only)
  → Wave A  Profile / SSOT / Environment / Diagnostics read-only
  → Wave B  Orchestrator → Registry → Router
  → Wave C  Capability observability → Event Core → Platform Contract → Trace
  → Wave D  Extension Registry → Event Bridge → Extension Runtime
  → HANDLERS (registry EntryPoints + module exports)
```

**Rule:** lower layers never depend on Wave D. Extensions never control Waves A–C.

---

## 2. SSOT registries (do not duplicate)

| Registry | Variable | Purpose |
|----------|----------|---------|
| **Core commands** | `$script:WorkstationCommandRegistry` | Wave B dispatch (`Invoke-WorkstationCommand`) |
| **Extensions** | `$script:WorkstationExtensions` | Wave D plugins (`Invoke-WorkstationExtension`) |
| **Events** | `$script:WorkstationEventBuffer` | Wave C append-only timeline |

**Not the same:** `KGreen.Workstation` module `Get-WorkstationCommandRegistry` — legacy/module command catalog. Core router **must** read `$script:WorkstationCommandRegistry` only.

Programmatic contract: `Get-WorkstationPlatformContract`

---

## 3. Event lifecycle contract (unified)

One `start` + one terminal (`success` | `fail`) per invocation:

| Layer | Actions |
|-------|---------|
| Router | `command.execute.{start\|success\|fail}` |
| Orchestrator | `profile.init.{start\|success\|fail}` |
| Extension | `extension.execute.{start\|success\|fail}` |

Emit via `New-WorkstationLifecycleEvent` or `New-WorkstationExtensionEvent` (bridge).  
**Forbidden:** duplicate actions, ad-hoc action names, file persistence from Event Core.

---

## 4. Trace model (read-only join)

`Get-WorkstationExecutionTrace` → `Time`, `Command`, `Layer`, `Capability`, `Status`  
Assign directly: `$trace = Get-WorkstationExecutionTrace` (not `@(...)`).

---

## 5. Layer boundaries (hard)

| Layer | May | Must not |
|-------|-----|----------|
| **Orchestrator** | Coordinate C1→C5, aggregate context | Repair, install, mutate diagnostics |
| **Registry** | Define commands + metadata | Execute, filter, emit events |
| **Router** | Dispatch by name | Capability enforcement, extension calls |
| **Observability** | Read registry structure | Route, permission, mutate |
| **Event Core** | Append in-memory events | Analyze, persist, change flow |
| **Trace** | Join events + metadata | Emit, execute, score |
| **Extensions** | Register + run via sandbox | Router, orchestrator, direct events, env mutation |

---

## 6. Verification (sign-off gate)

```powershell
Get-WorkstationPlatformContract
pwsh -NoProfile -File C:\Scripts\Workstation\Test-WorkstationPlatformHardening.ps1 -SaveReport
```

Baseline: [`docs/baselines/platform-spec-wave-abcd-lock.json`](../baselines/platform-spec-wave-abcd-lock.json)

---

## 7. Unlock

See [PLATFORM-SPEC-SIGNOFF.md §8](./PLATFORM-SPEC-SIGNOFF.md) — contract version bump + hardening PASS + explicit approval.

---

## 8. Related docs

- [PLATFORM-SPEC-SIGNOFF.md](./PLATFORM-SPEC-SIGNOFF.md) — **authoritative platform spec**
- [EXTENSION-GUIDELINES.md](./EXTENSION-GUIDELINES.md) — safe Wave D usage
- [OPERATIONAL-HARDENING.md](./OPERATIONAL-HARDENING.md) — scenario runner
- [ARCHITECTURE-FREEZE.md](./ARCHITECTURE-FREEZE.md) — product freeze (broader Phase 2)
