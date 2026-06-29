# Operational Hardening Phase (Wave A–D)

Run after platform changes, before commits, or on a schedule.

---

## Runner

```powershell
pwsh -NoProfile -File C:\Scripts\Workstation\Test-WorkstationPlatformHardening.ps1 -LoadIterations 50 -SaveReport
```

**Exit 0** = all scenarios passed · **Exit 1** = failed scenario(s) · **Warnings** = non-blocking (e.g. profile drift)

Report: `C:\Logs\Workstation\platform-hardening-*.json`

---

## Scenarios covered

| Scenario | Validates |
|----------|-----------|
| Profile drift | Canonical vs live `$PROFILE` hash |
| Profile init | Orchestrator lifecycle + contract |
| Idempotent orchestrator | Cached call emits **no** events |
| Core registry | Wave B keys after module import |
| Router dispatch | All core commands, router-layer events only |
| Extension sandbox | Context snapshot + Handler lifecycle |
| Extension NotFound | No events when not registered |
| Trace correlation | Event count = trace rows, capability joins |
| Load repeat | N× `env.show` — paired lifecycle under load |
| profile.reload cascade | Router×2 + nested Orchestrator×2 |

---

## Contract validators (in-session)

```powershell
Test-WorkstationEventBufferContract -FromIndex 0
Test-WorkstationEventLifecyclePairs -FromIndex 0
```

---

## Known edge cases (by design)

| Case | Behavior |
|------|----------|
| `profile.reload` | Router handler triggers nested `profile.init.*` orchestrator events |
| Cached `Invoke-WorkstationProfile` | No events (no lifecycle re-run) |
| Extension NotFound | No events |
| Event buffer | In-memory only, unbounded — not a log store |

---

## Drift remediation

| Warning | Action |
|---------|--------|
| `canonical-live-match` | `pwsh -File Install-ShellProfile.ps1 -Force` |

---

**See also:** [PLATFORM-SPEC-SIGNOFF.md](./PLATFORM-SPEC-SIGNOFF.md) · [ARCHITECTURE-LOCK.md](./ARCHITECTURE-LOCK.md) · [EXTENSION-GUIDELINES.md](./EXTENSION-GUIDELINES.md)
