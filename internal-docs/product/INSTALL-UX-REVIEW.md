# Installation UX Review — `install.ps1`

**Scope:** Product layer only · **Platform spec:** unchanged (LOCKED v1.0.0)

---

## Summary

| Criterion | Status | Notes |
|-----------|--------|-------|
| Single-command safe | ✅ | Clear FAIL messages, non-zero exit codes |
| Idempotent re-run | ✅ | Existing checkout reused; `-Force` on installer |
| PowerShell 7 guard | ✅ | Fails before any mutation |
| User-readable failures | ✅ | Actionable hints per failure class |
| Doctor gate at end | ✅ | Fail closed if validation fails |

---

## Flow (user perspective)

```
install.ps1
  ├─ Check PS 7+
  ├─ Resolve repo (local / env / clone)
  ├─ Install-Workstation (-Force -SkipSoftware -SkipAdmin)
  └─ devshell doctor → SUCCESS or FAIL + log path
```

---

## Idempotent behavior

| Scenario | Behavior |
|----------|----------|
| Re-run from repo root | Uses `$PSScriptRoot`, skips clone |
| Re-run with existing `~\.homebase\devshell` | Skips clone if valid repo |
| Re-run install | `Install-Workstation -Force` redeploys profile safely |
| `$env:HOMEBASE_DEVSHELL_ROOT` set | Preferred root on subsequent runs |

**Safe to re-run:** Yes — intended for repair/bootstrap refresh.

---

## Failure modes (user-readable)

| Exit | Message | User action |
|------|---------|-------------|
| 1 | PowerShell 7+ required | Install pwsh 7 |
| 1 | git not found | Install Git or clone manually + `-SkipClone` |
| 1 | git clone failed | Check URL/network; clone manually |
| 1 | Repository not found | Clone repo or set `HOMEBASE_DEVSHELL_ROOT` |
| 1 | Install-Workstation errors | Read console + `C:\Logs\Workstation\` |
| 1 | devshell doctor failed | Open `validation-*.json`, fix reported checks |

---

## `irm | iex` considerations

- `$PSScriptRoot` is a temp path when streamed — clone path logic required ✅
- User must trust script source (document in README) ✅
- Recommend GitHub `main` pin or tagged raw URL for production:

```powershell
irm https://raw.githubusercontent.com/<org>/homebase-devshell/v2.0.0/install.ps1 | iex
```

---

## Improvements applied (product layer)

- Pre-flight `git` availability check before clone
- Idempotent message when checkout already exists
- Structured step headers (`==>`) and SUCCESS/FAIL banner
- Consistent exit codes propagated from doctor

---

## Out of scope (by design)

- Non-Windows support
- Silent / unattended enterprise MSI
- Auto-update channel (future product decision)
- Modifying `Install-Workstation` admin/privacy scripts in this review

---

## Verification commands

```powershell
pwsh -NoProfile -File install.ps1          # from checkout
pwsh -NoProfile -File devshell.ps1 status
pwsh -NoProfile -File Test-WorkstationPlatformHardening.ps1
```
