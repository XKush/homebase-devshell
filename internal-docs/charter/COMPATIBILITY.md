# HOME BASE — Compatibility Policy

Совместимость PowerShell, Windows и смежных компонентов.

---

## 1. PowerShell

| Component | Requirement | Notes |
|-----------|-------------|-------|
| **Engine** | PowerShell **7.0+** | `#Requires -Version 7.0` in scripts |
| **Default shell** | **pwsh** (Core) | Windows PowerShell 5.1 — **not supported** for module |
| **Module manifest** | `PowerShellVersion = '7.0'` | `modules/KGreen.Workstation.psd1` |
| **Profile** | `$PROFILE` → deployed from `profile/` | Uses `$PSVersionTable.PSVersion.Major -ge 7` |

### Verified behavior

| Feature | PS 7.0 | PS 7.4+ |
|---------|--------|---------|
| Module import Global scope | ✅ | ✅ |
| `Import-PowerShellDataFile` (psd1) | ✅ | ✅ |
| Windows Terminal integration | ✅ | ✅ |
| `-WhatIf` on file ops | ✅ | ✅ |

**Recommendation:** PowerShell **7.4 LTS** or latest stable 7.x.

---

## 2. Windows

| OS | Support | Notes |
|----|---------|-------|
| **Windows 11** | ✅ Supported | Primary target |
| **Windows 10 22H2+** | ✅ Supported | Full feature set expected |
| **Windows Server 2022** | ⚠️ Best-effort | No WT default; headless OK |
| **ReviOS** | ✅ Reference | Defender off by design — see disclaimer |
| **Linux / macOS** | ❌ Out of scope | pwsh cross-platform not tested |

### Windows features used

- Registry (privacy, hardening, profile)
- Scheduled tasks (trust probe — optional)
- Windows Terminal (`wt.exe`, settings.json)
- Junction points (Phase 2 migration)
- UAC elevation (`Start-Process -Verb RunAs`)

---

## 3. Terminal & UI

| Component | Status | Requirement |
|-----------|--------|-------------|
| **Windows Terminal** | ✅ Recommended | Default over ConsoleHost |
| **Oh My Posh** | ✅ Supported | `terminal/*.omp.json` |
| **ConsoleHost** | ⚠️ Degraded | System32 start dir issues — use WT |
| **Font** | Nerd Font | e.g. CaskaydiaMono NFM |

Profile mitigates ConsoleHost `System32` start via `Initialize-WorkstationSession`.

---

## 4. External tools (not bundled)

Installed via winget / manual — versions not pinned in repo:

| Tool | Used by |
|------|---------|
| git | dev workflow |
| node, ripgrep | tooling |
| Tor Browser | `anon`, `tor-*` |
| GnuPG / gpg | `pgp-*` |
| Sysinternals | `nettools` |

Compatibility with specific tool versions: **best-effort**. Doctor validates presence, not exact semver.

---

## 5. Backward compatibility commitments (v2.x)

| Area | v2.0 → v2.x | v3.0 |
|------|-------------|------|
| Command names (Supported) | stable | deprecations removed |
| Hardcoded paths | stable until Phase 2 | junction + config |
| JSON report keys | additive only | breaking only in MAJOR |
| Profile entry | stable | may rename module |

Phase 2 (Path Abstraction) introduces **configurable paths** with **12-month junction** compatibility — not breaking in single PATCH.

---

## 6. Compatibility testing

Before MINOR/MAJOR release:

1. Run [ENVIRONMENT-MATRIX.md](./ENVIRONMENT-MATRIX.md) reference row
2. Optional: clean VM or second user profile
3. Document new OS/PS combo in matrix if tested

---

## 7. Related

- [ENVIRONMENT-MATRIX.md](./ENVIRONMENT-MATRIX.md)
- [QUICKSTART.md](./QUICKSTART.md)
- [ARCHITECTURE.md](./ARCHITECTURE.md) §2 Repository vs Runtime
