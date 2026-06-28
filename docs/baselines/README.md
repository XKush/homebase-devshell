# Phase 2 baselines

Canonical stable snapshots for regression comparison during Path Abstraction.

| File | Label | Purpose |
|------|-------|---------|
| [phase2-step1-stable.json](./phase2-step1-stable.json) | **Phase2-Step1-Stable** | SSOT paths wired; legacy layout unchanged |

## Capture

```powershell
pwsh -File C:\Scripts\Workstation\Invoke-Phase2Step1Baseline.ps1
```

Or manually after `reloadprofile` + `doctor` + `trustcheck`:

```powershell
pwsh -File Save-Phase2Baseline.ps1 -StableLabel Phase2-Step1-Stable
```

## Compare (Step 2+)

```powershell
pwsh -File Test-LegacyEquivalence.ps1
```

Runtime copy: `C:\Logs\Workstation\phase2-step1-stable.json`
