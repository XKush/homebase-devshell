# Privacy — DevReady v2.3

Read-only audits by default. **No false promises** — scores show *Low / Medium / High privacy*, not anonymity.

## Commands

| Command | What it does |
|---------|----------------|
| `devshell privacy` | System privacy audit + score |
| `devshell privacy -Fix` | Safe repairs only (user confirms) |
| `devshell privacy -Apply` | Apply `Config/privacy.defaults.json` + `-Fix` |
| `devshell audit privacy` | Same as `devshell privacy` |
| `devshell doctor -Privacy` | Privacy readiness (score only) |
| `devshell browser` | Chrome, Edge, Firefox checks |
| `devshell tor` | Tor Browser installed / hardened (does **not** launch Tor) |
| `devshell vpn` | WireGuard, OpenVPN, TUN, VPN active, DNS leak heuristic |
| `devshell opsec` | Combined snapshot (VPN, DoH, OneDrive, sync, telemetry) |
| `devshell metadata <file>` | View EXIF (needs [exiftool](https://exiftool.org/)) |
| `devshell clean-meta <file>` | Strip metadata → `*_clean` copy |

## Safe `-Fix` scope

**Will change (with confirmation):**

- Advertising ID, tailored experiences, suggested content
- Recent files / activity tracking
- Search highlights, clipboard history (user + admin where allowed)
- Telemetry / location policies (admin)
- DNS + DoH (admin, Quad9 by default)

**Will NOT change:**

- Microsoft Defender
- Windows Firewall
- Windows Update

## Privacy profile

Default: `Config/privacy.defaults.json`  
User override: `%USERPROFILE%\.homebase\privacy.json`

```powershell
devshell privacy -Apply -Fix
```

## Risk levels

| Score | Label |
|-------|--------|
| 85–100 | High privacy |
| 65–84 | Medium privacy |
| 0–64 | Low privacy |

Reports: `C:\Logs\Workstation\privacy-*.json`

## JSON report schema (`1.0.0`)

Stable fields for CI and external tools:

```json
{
  "reportSchemaVersion": "1.0.0",
  "productVersion": "3.0.0",
  "scope": "System",
  "elevated": false,
  "offlineCapable": true,
  "limitations": ["HKLM policy checks may be incomplete without elevation"],
  "score": { "value": 85, "max": 100, "riskLevel": "Strong configuration" },
  "summary": { "pass": 6, "warn": 5, "fail": 0, "info": 7 },
  "checks": [
    { "id": "doh", "label": "DNS over HTTPS", "status": "Pass", "weight": 8, "deduction": 0 }
  ]
}
```

Machine output: `devshell privacy -Json`

## Scoring configuration

Edit weights in `Config/privacy.defaults.json` (or `%USERPROFILE%\.homebase\privacy.json`):

```json
"scoring": {
  "maxScore": 100,
  "warnMultiplier": 0.5,
  "riskLevels": { "high": 85, "medium": 65 },
  "weights": { "adid": 6, "doh": 8 }
}
```

## Implemented in v3.0

- `devshell health` — unified dashboard (replaces scattered top-level commands for daily use)
- `devshell baseline` / `verify` — configuration drift vs saved baseline
- `devshell history` — privacy score trends over time
- `devshell health -Export html` — GitHub Security–style HTML report
- `devshell privacy -Json` / `health -Json` — machine-readable reports

## Planned after v3.0 (plugins / v3.1+)
- Richer browser audit (sync, signed-in accounts, extensions count)
- `devshell metadata --Scan <folder>` — list files with EXIF only
- Tor Browser signature check (when reliable offline)

## What we deliberately omit

- One-click “anonymous mode”
- Auto-routing all traffic through Tor
- Circumvention / anti-censorship tools
- Claims that the user is “invisible” online

See [TROUBLESHOOTING.md](TROUBLESHOOTING.md) for install issues.
