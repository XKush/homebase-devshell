# HOME BASE — Security Policy

Политика безопасности операций и threat model для HOME BASE.

---

## 1. Scope

- Filesystem mutations (delete, move, archive)
- Registry mutations
- Profile / terminal deployment
- PGP key operations
- Firewall / privacy scripts (admin)
- Backup / restore

**Out of scope:** Tor network anonymity guarantees (user operational security).

---

## 2. Mandatory chain (destructive ops)

```
Validation
    ↓
Backup
    ↓
Confirmation (-WhatIf / -Confirm / -Force admin)
    ↓
Execution
    ↓
Logging
    ↓
Rollback path documented
```

**No step may be skipped** except Confirmation when `-WhatIf` preview only.

---

## 3. Operation matrix

| Operation | Scripts / commands | Guards required |
|-----------|-------------------|-----------------|
| `Remove-Item` file | cleanlogs, housekeeping | extension whitelist, age cutoff, `-WhatIf` |
| `Remove-Item -Recurse` dir | ~~cleanlogs~~ fixed | **archive only**, never delete backups |
| `Move-Item` | organize, housekeeping | `-WhatIf` default doc, backup first |
| `Copy-Item` | Backup-Configuration | manifest.json |
| Registry set | Harden, Privacy | `Backup-RegistryKey` |
| Profile overwrite | Install-ShellProfile | timestamp backup |
| PGP operations | pgp-repair | `Backups/pgp/` |
| Restore | restoreconfig | admin + `-Force` + latest backup verify |

---

## 4. Remove-Item rules

### Allowed directories

```
C:\Logs\Workstation\validation-*.json  (rotation)
C:\Temp\Scratch, %TEMP%               (.tmp, .log, .cache, age > KeepDays)
C:\Logs\Workstation\*.json patterns   (housekeeping whitelist)
```

### Forbidden targets

```
C:\Backups\Workstation\_Archive       (never delete)
C:\Backups\Workstation\* snapshots    (archive only, keep 8)
C:\Projects\                           (never auto-clean)
C:\Security\                           (never auto-clean)
User profile without backup           (never)
```

### Code pattern

```powershell
if ($WhatIf) { Write-Host "  Будет удалено: …" ; return }
# else remove with -ErrorAction SilentlyContinue only for temp
```

---

## 5. Force / Recurse policy

| Flag | When allowed |
|------|--------------|
| `-Force` | temp files, stale logs, admin restore with backup |
| `-Recurse` | **only** empty dir cleanup in `C:\Temp\Scratch` |
| Both | never on `C:\Backups` |

---

## 6. Module import security

- Always `Ensure-WorkstationModuleLoaded` or `-Scope Global`
- Never `Import-Module -Force` in child script without Ensure
- Subprocess probes (`pwsh -NoProfile`) for validation isolation

---

## 7. Defender / AV policy

| Rule | Status |
|------|--------|
| Enable WinDefend | **Forbidden** by project policy |
| Windows Update patches | **Enabled** |
| Exploit Protection | Enabled (independent of AV) |
| Firewall | Enabled, inbound Block |

Documented in Validate as PASS: «WinDefend not running (per user policy)».

---

## 8. SHADOW OPS

- Tor: hardened profile, `tor-check` preflight
- PGP: key in `%APPDATA%\gnupg`, revocation cert in `Backups/pgp/`
- Audits: `Test-AnonymityKitAudit`, Validate SHADOW OPS section

---

## 9. Incident response

| Event | Action |
|-------|--------|
| Accidental cleanup | `restoreconfig` from latest `backupconfig` |
| Profile drift | `fixprofile` |
| Trust UNTRUSTED | `doctor` → `repairterminal` |
| PGP compromise | revoke + `pgp-repair` |

---

## 10. Related

- [BACKUP-POLICY.md](./BACKUP-POLICY.md)
- [adr/ADR-0008-security-model.md](./adr/ADR-0008-security-model.md)
- [docs/ru/TOR-MAX-SECURITY.md](../ru/TOR-MAX-SECURITY.md)
