# HOME BASE — Backup Policy

Официальная политика резервного копирования и восстановления.

---

## 1. Цели

- Любое изменение конфигурации **откатываемо**
- Snapshots **верифицируемы** (manifest)
- Rotation **не destructive** (archive, not delete)

---

## 2. Структура

```
C:\Backups\Workstation\
├── {yyyyMMdd-HHmmss}\          # backupconfig snapshots
│   ├── manifest.json
│   ├── Microsoft.PowerShell_profile.ps1
│   ├── settings.json (WT)
│   ├── active-theme.omp.json
│   └── registry exports…
├── _Archive\                   # rotated old snapshots
│   └── {folder name}\
├── housekeeping-{stamp}\         # pre-clean copies
├── organization-{stamp}\         # organize moves
├── terminal-recovery-{stamp}\
├── pgp\                          # revocation certs, exports
│   └── revocation-cert-*.asc
└── registry\                     # per-key .reg backups
    └── {stamp}-{label}.reg
```

---

## 3. Команды

| Command | Script | When |
|---------|--------|------|
| `backupconfig` | Backup-Configuration.ps1 | before changes, weekly |
| `restoreconfig` | Rollback-Workstation.ps1 | disaster recovery (admin) |
| `revise -Backup` | Invoke-WorkstationRevision.ps1 | if backup >7 days |
| `fixprofile` | Invoke-TerminalRecovery.ps1 | auto backup pre-repair |

---

## 4. Ротация

| Rule | Value |
|------|-------|
| Active snapshots kept | **8** (by LastWriteTime) |
| Overflow | **Move** to `_Archive\` |
| `_Archive` folder | **Never deleted** by cleanup |
| Validation JSON | keep 10–20 per pattern (housekeeping) |
| Log truncate | keep 1500–2000 lines workstation.log |

**Implemented in:** `Invoke-Housekeeping.ps1`, `modules/Maintenance.ps1` (cleanlogs).

**Always run:** `cleanup -WhatIf` before `cleanup`.

---

## 5. Archive policy

```
Active (8 latest) → _Archive → manual cold storage (optional)
```

Archive folders are **moved**, not copied, to save disk.

Collision: if `_Archive\{name}` exists, skip move (no overwrite).

---

## 6. Restore procedure

```powershell
# 1. Identify snapshot
Get-ChildItem C:\Backups\Workstation -Directory |
  Where-Object Name -ne '_Archive' |
  Sort-Object LastWriteTime -Descending | Select -First 5

# 2. Restore (admin)
restoreconfig -BackupFolder 'C:\Backups\Workstation\{stamp}'

# 3. Verify
reloadprofile
doctor
trustcheck
```

---

## 7. Retention

| Type | Retention |
|------|-----------|
| Config snapshots | 8 active + archive indefinite |
| PGP revocation | permanent |
| Registry backups | 90 days (manual cleanup OK) |
| terminal-recovery | until next successful fixprofile |
| housekeeping reports | 20 JSON per pattern |

---

## 8. Integrity verification

`manifest.json` in each snapshot:

- timestamp
- file list + hashes (target: explicit SHA256 all files)
- HOME BASE version (target: ModuleVersion)

**Pre-restore:** verify manifest exists and profile file present.

---

## 9. Related

- [SECURITY-POLICY.md](./SECURITY-POLICY.md)
- [adr/ADR-0005-backup-strategy.md](./adr/ADR-0005-backup-strategy.md)
- [QUICKSTART.md](./QUICKSTART.md) §7
