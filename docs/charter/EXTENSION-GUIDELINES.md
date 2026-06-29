# Safe Extension Guidelines (Wave D)

How to add plugins without breaking the A–C core or turning Wave D into chaos.

---

## 1. Mental model

| Concept | Meaning |
|---------|---------|
| **Core (A–C)** | Kernel — orchestration, routing, events, trace |
| **Extension (D)** | Side capability — optional, sandboxed, observable |
| **Bridge (D3)** | Wiring only — maps extension lifecycle to Event Core |

**Extensions can RUN. Extensions cannot DECIDE.**

---

## 2. Registration (D1)

```powershell
Register-WorkstationExtension `
    -Name 'git.extensions' `
    -Version '1.0.0' `
    -Capability 'system.tools.git' `
    -EntryPoint { param($ctx) ... } `
    -Dependencies @()
```

**Do**

- One extension = one bounded capability string
- Idempotent registration at module/feature load time (guard with `Get-WorkstationExtension`)
- Keep `EntryPoint` small — delegate to module functions

**Don't**

- Register inside Router or Orchestrator
- Re-register the same `Name` (throws by design)
- Use extension registry as command registry (`profile.reload` stays Wave B)

---

## 3. Execution (D2)

```powershell
Invoke-WorkstationExtension -Name 'git.extensions' -Command 'status' -Arguments @{ dry = $true }
```

**Context snapshot (`$ctx`) — read-only contract**

| Field | Source |
|-------|--------|
| `Command` | Caller-supplied label (not router dispatch) |
| `Arguments` | Caller hashtable |
| `Capabilities` | `Get-WorkstationCommandCapabilities` snapshot |
| `Environment` | Copy of `$global:WorkstationExecutionContext` |

**Do**

- Treat `$ctx` as read-only
- Return structured data / side effects limited to extension domain
- Let failures throw — runtime emits `extension.execute.fail` and rethrows

**Don't**

- Call `Invoke-WorkstationCommand`, `Invoke-WorkstationProfile`
- Call `New-WorkstationEvent` directly — use bridge via runtime only
- Mutate `$env:`, `$script:WorkstationCommandRegistry`, `$global:WorkstationExecutionContext`
- Invoke another extension from inside `EntryPoint` without explicit caller design (no hidden orchestration)

---

## 4. Observability (D3 + C)

Extension runs produce:

```
extension.execute.start → extension.execute.success | extension.execute.fail
```

Inspect:

```powershell
$script:WorkstationEventBuffer | Where-Object Action -like 'extension.execute.*'
Get-WorkstationExecutionTrace | Where-Object Command -eq 'git.extensions'
```

**Don't**

- Build analytics, dashboards, or file logs in extension layer
- Add custom event action names — use lifecycle contract only

---

## 5. Capability naming

Use dotted namespaces — **not** Wave B command names:

| Good | Avoid |
|------|-------|
| `system.tools.git` | `env.show` (reserved command) |
| `diagnostics.extra` | `system.lifecycle` (core capability) |

Wave C `Get-WorkstationCapabilityMatrix` covers **commands**. Extension capabilities live in `$script:WorkstationExtensions` — joined in trace by extension name.

---

## 6. Checklist before merging an extension

- [ ] Registered only via `Register-WorkstationExtension`
- [ ] Invoked only via `Invoke-WorkstationExtension`
- [ ] No core router/orchestrator calls
- [ ] No direct event emission
- [ ] No registry/env mutation
- [ ] Events visible in buffer with contract action names
- [ ] Trace shows extension name + capability when registered

---

## 7. Future (not in Wave D yet)

These require **separate** tasks with their own boundaries:

- Enable/disable extension flags
- Version compatibility policy
- Dependency resolution

Do not implement ad-hoc in `EntryPoint` — that becomes a shadow orchestrator.

---

**See also:** [ARCHITECTURE-LOCK.md](./ARCHITECTURE-LOCK.md)
