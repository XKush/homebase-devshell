# HOME BASE — Platform Spec Sign-off (Wave A–D)

**Document:** PLATFORM-SPEC-SIGNOFF  
**Spec version:** `1.0.0`  
**Lock status:** **LOCKED**  
**Signed:** 2026-06-29  
**Scope:** Profile orchestration platform (`lib/Workstation*.ps1` + profile loader) — **not** `KGreen.Workstation` module catalog

This document is the authoritative **platform spec**. Implementation must conform; changes require unlock procedure (§8).

---

## Sign-off summary

| Pillar | Locked as |
|--------|-----------|
| **A–D stack** | Fixed loader order, layer dependency rules |
| **Event contract** | Unified lifecycle actions + paired start/terminal |
| **Extension boundary** | Register / sandbox / bridge — no core control |
| **Registry separation** | Core vs extension vs module — three distinct catalogs |
| **Trace model** | Read-only join over events + metadata |

**Hardening evidence:** `Test-WorkstationPlatformHardening.ps1` — 11/11 PASS (2026-06-29)  
**Baseline artifact:** [`docs/baselines/platform-spec-wave-abcd-lock.json`](../baselines/platform-spec-wave-abcd-lock.json)

---

## 1. Platform stack (LOCKED)

```
ENTRYPOINT   profile/Microsoft.PowerShell_profile.ps1  (dot-source loader only)
    │
    ▼ Wave A   SSOT · Environment · Diagnostics read-only
    │          HomeBasePaths · WorkstationCommon · ProfileEnvironment
    ▼ Wave B   Orchestrator → Command Registry → Router
    │          WorkstationOrchestrator · WorkstationCommandRegistry · WorkstationCommandRouter
    ▼ Wave C   Observability → Event Core → Platform Contract → Trace
    │          WorkstationCapabilityObservability · WorkstationEventCore
    │          WorkstationPlatformContract · WorkstationExecutionTrace
    ▼ Wave D   Extension Registry → Event Bridge → Extension Runtime
    │          WorkstationCapabilityExtensions · WorkstationExtensionEventBridge
    │          WorkstationExtensionRuntime
    ▼ HANDLERS registry EntryPoints · KGreen.Workstation module exports
```

**Dependency rule:** A→B→C is the kernel. D attaches below C. D never drives A–C.

---

## 2. Registry separation (LOCKED)

| Catalog | SSOT | Consumer | Must not |
|---------|------|----------|----------|
| **Core commands** | `$script:WorkstationCommandRegistry` | `Invoke-WorkstationCommand` | Merge with module or extension registries |
| **Extensions** | `$script:WorkstationExtensions` | `Invoke-WorkstationExtension` | Act as command router or orchestrator |
| **Events** | `$script:WorkstationEventBuffer` | Trace, validators | Persist, analyze, route |
| **Module commands** | `Get-WorkstationCommandRegistry` (module) | Menu, doctor, WOC | Replace Wave B core SSOT |

**Core commands (v1.0.0):** `profile.reload` · `env.show` · `diag.boot`

---

## 3. Event contract (LOCKED)

**Pattern:** one `.start` + one `.success` OR `.fail` per invocation.

| Emitter | Layer | Actions |
|---------|-------|---------|
| Router | `Router` | `command.execute.start` · `.success` · `.fail` |
| Orchestrator | `Orchestrator` | `profile.init.start` · `.success` · `.fail` |
| Extension runtime | `Handler` | `extension.execute.start` · `.success` · `.fail` |

**Emit API:** `New-WorkstationLifecycleEvent` · `New-WorkstationExtensionEvent` (bridge only)  
**Validate:** `Test-WorkstationEventBufferContract` · `Test-WorkstationEventLifecyclePairs`

**Forbidden:** ad-hoc action names · duplicate same-phase events · Event Core file I/O · analytics in emit path

**Known cascade (by design):** `profile.reload` → Router start → nested Orchestrator init → Router success

---

## 4. Extension boundary (LOCKED)

```
Register-WorkstationExtension          (D1 — metadata only)
        ↓
Invoke-WorkstationExtension            (D2 — sandbox gateway)
        ↓
New-WorkstationExtensionEvent          (D3 — wiring to Event Core)
```

**Extension model:** `Name` · `Version` · `Capability` · `EntryPoint` · `Dependencies`

**Sandbox context (read-only snapshot):** `Command` · `Arguments` · `Capabilities` · `Environment`

**Extensions MUST NOT:** call Router/Orchestrator · mutate core registries/env · emit events directly · filter core commands

**Rule:** Extensions can **RUN**, not **DECIDE**. See [EXTENSION-GUIDELINES.md](./EXTENSION-GUIDELINES.md).

---

## 5. Trace model (LOCKED)

**Input:** `$script:WorkstationEventBuffer` (append-only, in-memory)  
**API:** `Get-WorkstationExecutionTrace`  
**Output row:** `Time` · `Command` · `Layer` · `Capability` · `Status`

**Join rules (read-only, no inference):**

| Event pattern | Command | Capability source |
|---------------|---------|-------------------|
| Target ∈ core registry | Target | `$script:WorkstationCommandRegistry` |
| `command.execute.*` | Target | registry if present, else empty |
| `extension.execute.*` | Target (extension name) | `$script:WorkstationExtensions` |
| `profile.init.*` | empty | empty |

**Usage:** `$trace = Get-WorkstationExecutionTrace` — assign directly; do not wrap in `@(...)`.

**Trace MUST NOT:** emit events · execute commands · mutate buffers · score or rank

---

## 6. Public API surface (v1.0.0)

Programmatic index: `Get-WorkstationPlatformContract`

| Wave | Entry points |
|------|----------------|
| A | `Initialize-WorkstationProfileEnvironment`, `Import-WorkstationProfileModule` |
| B | `Invoke-WorkstationProfile`, `Invoke-WorkstationCommand`, `Get-WorkstationCommandRegistry`, `Get-WorkstationExecutionContext` |
| C | `New-WorkstationLifecycleEvent`, `Get-WorkstationExecutionTrace`, `Get-WorkstationCapabilityMatrix`, validators |
| D | `Register-WorkstationExtension`, `Invoke-WorkstationExtension`, `New-WorkstationExtensionEvent` |

---

## 7. Verification gate (required before unlock)

```powershell
# Contract
Get-WorkstationPlatformContract | Format-List
Get-WorkstationEventLifecycleContract

# Operational hardening (must PASS)
pwsh -NoProfile -File C:\Scripts\Workstation\Test-WorkstationPlatformHardening.ps1 -SaveReport

# Live inspect
$trace = Get-WorkstationExecutionTrace
$trace | Select-Object -Last 10 Command, Layer, Capability, Status
```

---

## 8. Unlock procedure

Lock lifts only when **all** are true:

1. Written rationale (why spec must change)
2. `ContractVersion` bump in `Get-WorkstationPlatformContract`
3. Update this sign-off + `ARCHITECTURE-LOCK.md`
4. Hardening runner PASS on new spec
5. Explicit approval (not drive-by refactor)

**Until unlock:** connect existing layers; do not add new runtime systems.

---

## 9. Related documents

| Doc | Role |
|-----|------|
| [ARCHITECTURE-LOCK.md](./ARCHITECTURE-LOCK.md) | Quick reference lock |
| [EXTENSION-GUIDELINES.md](./EXTENSION-GUIDELINES.md) | Wave D playbook |
| [OPERATIONAL-HARDENING.md](./OPERATIONAL-HARDENING.md) | Scenario runner |
| [ARCHITECTURE-FREEZE.md](./ARCHITECTURE-FREEZE.md) | Product-wide Phase 2 freeze |

---

**Platform spec status: LOCKED at v1.0.0**
