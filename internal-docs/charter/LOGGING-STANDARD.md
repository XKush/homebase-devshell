# HOME BASE — Logging Standard

Стандарт логирования событий HOME BASE.

---

## 1. Log locations

| File | Path | Writer |
|------|------|--------|
| Commands | `C:\Logs\Workstation\commands.log` | `Write-CommandLog` |
| Workstation | `C:\Logs\Workstation\workstation.log` | `Write-WorkstationLog` |
| Validation | `C:\Logs\Workstation\validation-*.json` | Validate-Workstation |
| Trust | `C:\Logs\Workstation\trust-report.json` | TrustSystem |
| Command health | `C:\Logs\Workstation\command-health.json` | Test-WorkstationCommands / Save-CommandHealthCache |
| WOC | `woc-cache.json`, `woc-last-session.json` | WOC |
| Menu | `menu-recent.json` | MenuSystem |

**Target (v2.2):** `%HOMEBASE_RUNTIME%\Logs\`

---

## 2. Format — commands.log

```
[{yyyy-MM-dd HH:mm:ss}] {command} -> {OK|FAIL|WARN} {detail}
```

Example:

```
[2026-06-29 00:53:02] revise -> OK
[2026-06-29 00:53:45] pgp-repair -> OK
```

---

## 3. Format — workstation.log

```
[{yyyy-MM-dd HH:mm:ss}] [{LEVEL}] {message}
```

| LEVEL | Color (console) | Usage |
|-------|-----------------|-------|
| INFO | Gray | step titles |
| OK | Green | success |
| WARN | Yellow | non-fatal |
| ERROR | Red | failure |

---

## 4. JSON reports

Required fields (target schema v2):

```json
{
  "SchemaVersion": 2,
  "Timestamp": "ISO8601",
  "Host": "COMPUTERNAME",
  "ModuleVersion": "2.0.0"
}
```

Existing reports: add `SchemaVersion` on next touch (non-breaking).

---

## 5. Correlation

| ID | Source |
|----|--------|
| Validation run | filename `validation-{yyyyMMdd-HHmmss}.json` |
| Backup snapshot | folder `yyyyMMdd-HHmmss` |
| Revision pass | workstation.log timestamp cluster |
| Trust probe | `trust-report.json` Timestamp |

**Target:** `OperationId` GUID per `Invoke-WorkstationCmd` invocation.

---

## 6. Rotation

| Log | Policy |
|-----|--------|
| workstation.log | truncate >3–5 MB, keep 1500–2000 lines |
| validation-*.json | keep 10–20 newest |
| commands.log | append-only; rotate via housekeeping |
| trust-report.json | single file, overwritten |

---

## 7. What to log

| Event | Log |
|-------|-----|
| Command start/end | commands.log |
| PATH repair | workstation.log OK |
| Backup destination | workstation.log OK |
| Destructive op (WhatIf) | workstation.log INFO |
| Trust level change | trust-report.json |
| SelfCheck fail | trust-report.json Issues |

**Never log:** passwords, key material, full env dumps.

---

## 8. Verbose stream

`-Verbose` → Write-Verbose (not log file by default).

Target: `-Verbose` duplicates key steps to console only.

---

## 9. Related

- [SECURITY-POLICY.md](./SECURITY-POLICY.md)
- [COMMAND-STANDARD.md](./COMMAND-STANDARD.md)
