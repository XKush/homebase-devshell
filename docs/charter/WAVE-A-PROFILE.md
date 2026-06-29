# Wave A — Profile Layer Migration

**Phase:** 2 closeout · **Unit of work:** architectural layer (not single file)  
**Baseline tag:** v2.0.0 · **Regression anchor:** `Phase2-WaveA-Pre` → `Phase2-WaveA-Post`  
**Status:** IN PROGRESS

---

## Scope

Profile platform layer only:

| In scope | Examples |
|----------|----------|
| `$PROFILE` deployment | `Install-ShellProfile.ps1`, canonical profile |
| PowerShell profile bootstrap | `profile/Microsoft.PowerShell_profile.ps1` |
| Windows Terminal integration | `terminal/settings.template.json`, WT merge in install |
| Oh My Posh bootstrap | deferred OMP init in profile |
| Auto-cd / navigation | zoxide, `projects`/`tools`/`scripts`/`logs` |
| Module loading | lazy `KGreen.Workstation` import |
| Profile hints | `Hints.ru.ps1`, `Help.ru.ps1`, `Shell.ps1` hint strings |
| Profile diagnostics | `BootCheck.ps1`, `WorkstationOperationsCenter.ps1`, OMP segment scripts |
| Profile-related env | `WORKSTATION_*`, `FASTFETCH_CONFIG`, roots hashtable |

## Out of scope

- Module runtime (Wave B)
- Install/setup/repair scripts beyond profile install (Wave C)
- Legacy fallback removal pass (Wave D)
- Test gate hardcoding (Wave E)
- Junction / Step 2.5
- Docs-only changes (unless required by migration)
- UI / new commands ([ARCHITECTURE-FREEZE.md](./ARCHITECTURE-FREEZE.md))

---

## Pre-wave baseline (before first migration commit)

```powershell
pwsh -File Save-PhaseBaseline.ps1 -Wave Profile -Moment Pre
```

Pipeline:

```
backupconfig
  → Save-Phase2Baseline (-StableLabel Phase2-WaveA-Pre)
  → Get-Phase2LegacyPathReport -SaveJson
  → doctor
  → trustcheck
  → Test-LegacyEquivalence
  → Save-ProfileSnapshot
```

Artifacts:

- `docs/baselines/phase2-wave-a-pre.json`
- `C:\Logs\Workstation\Phase2\legacy-path-report.json`
- `C:\Logs\Workstation\Phase2\profile-snapshot-pre.json`

---

## Migration commits (one responsibility each)

| # | Theme | Primary targets |
|---|-------|-----------------|
| 1 | Profile bootstrap | SSOT bootstrap before module load (`HomeBasePaths.ps1`, `WORKSTATION_ROOT`) |
| 2 | Module loading | Lazy import paths, `WorkstationCommon` defaults |
| 3 | Profile hints | `Shell.ps1`, `Hints.ru.ps1`, `Help.ru.ps1` |
| 4 | Environment | Roots hashtable, OMP/fastfetch/WT template, `Install-ShellProfile` |
| 5 | Diagnostics | `BootCheck`, WOC, OMP segments, `Optimize-Profile` |

Each commit: **baseline unchanged** → edit → `Invoke-Phase2CommitGate.ps1 -SaveArtifacts -Wave Profile -Component …` → commit → `-FinalizePendingArtifacts`.

---

## Wave A passport (per commit)

Extended manifest fields (Profile layer):

```json
{
  "wave": "Profile",
  "profile_loaded": true,
  "module_loaded": true,
  "omp_loaded": true,
  "cwd_restored": true,
  "doctor": "75/75",
  "trust": "VERIFIED"
}
```

Collected by `Invoke-Phase2CommitGate.ps1 -Wave Profile`.

---

## Exit criteria

Wave A complete only when:

- [ ] All profile-layer runtime paths use SSOT (`Get-HomeBasePath` / accessors)
- [ ] Profile loads identically after: new Windows Terminal window, new `pwsh`, `reloadprofile`
- [ ] doctor does not regress (75/75)
- [ ] trustcheck remains VERIFIED 100
- [ ] `Test-LegacyEquivalence` PASS
- [ ] Profile passport PASS on every Wave A commit
- [ ] `Save-PhaseBaseline.ps1 -Wave Profile -Moment Post` saved

**Then:** [Wave A Review](./WAVE-A-REVIEW.md) (one page) before Wave B.

---

## Planning unit change (Phase 2 closeout)

| Era | Unit of work |
|-----|----------------|
| Command queue (done) | One script file |
| Waves A–E | One architectural layer |

---

## Related

- [STEP-2-5-DECISION.md](./STEP-2-5-DECISION.md)
- [PATH-MIGRATION-PROGRESS.md](./PATH-MIGRATION-PROGRESS.md)
- [Save-PhaseBaseline.ps1](../../Save-PhaseBaseline.ps1)
- [Save-ProfileSnapshot.ps1](../../Save-ProfileSnapshot.ps1)
