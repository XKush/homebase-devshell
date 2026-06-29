# HOME BASE — Environment Matrix

Матрица поддерживаемых и протестированных окружений.

**Legend:** ✅ Certified · ⚠️ Best-effort · ❌ Not supported · 🔬 Planned test

---

## 1. Reference environment (certified)

Primary development and validation machine — **baseline for release gate**.

| Dimension | Value |
|-----------|-------|
| **OS** | Windows 11 / ReviOS |
| **PowerShell** | 7.x (pwsh default) |
| **Terminal** | Windows Terminal (`wt.exe`) |
| **Module** | KGreen.Workstation 2.0.0 |
| **Repository** | `C:\Scripts\Workstation` |
| **Runtime logs** | `C:\Logs\Workstation` |
| **Runtime backups** | `C:\Backups\Workstation` |
| **Projects** | `C:\Projects` |
| **Trust** | VERIFIED 100/100 |
| **Doctor** | 75/75 PASS |

Last certified: **v2.0.0** tag (`84bde27`).

---

## 2. OS × PowerShell matrix

| OS | PS 7.0 | PS 7.4 LTS | PS 7.5+ | PS 5.1 |
|----|--------|------------|---------|--------|
| Windows 11 | ✅ | ✅ | ✅ | ❌ |
| Windows 10 22H2+ | ✅ | ✅ | ✅ | ❌ |
| ReviOS (Win11 base) | ✅ | ✅ | ✅ | ❌ |
| Windows Server 2022 | ⚠️ | ⚠️ | ⚠️ | ❌ |

---

## 3. Terminal matrix

| Terminal | Cockpit UI | Hotkeys | Trust probe | Status |
|----------|------------|---------|-------------|--------|
| Windows Terminal | ✅ | ✅ | ✅ | ✅ Certified |
| ConsoleHost | ⚠️ | ⚠️ | ✅ | ⚠️ Use WT |
| VS Code integrated | ⚠️ | ❌ | ✅ | ⚠️ Dev only |
| SSH remote | ❌ | ❌ | ❌ | ❌ Out of scope |

---

## 4. Install path matrix (current → Phase 2)

| Layout | v2.0.x | v2.2+ (Phase 2) |
|--------|--------|-----------------|
| Default `C:\Scripts\Workstation` | ✅ | ✅ via defaults |
| Custom repo path | ⚠️ manual profile edit | ✅ config |
| Custom runtime paths | ❌ hardcoded | ✅ `homebase.defaults.json` |
| Junction legacy paths | N/A | ✅ 12 mo compatibility |

---

## 5. Feature × environment

| Feature | Reference | Server headless | Custom paths (Phase 2) |
|---------|-----------|-----------------|------------------------|
| `home` / `go` | ✅ | ⚠️ no WT | 🔬 |
| `doctor` | ✅ | ✅ | 🔬 |
| `trustcheck` | ✅ | ✅ | 🔬 |
| `anon` (Tor+PGP) | ✅ | ❌ | 🔬 |
| `backupconfig` | ✅ | ✅ | 🔬 |
| `revise` | ✅ | ⚠️ | 🔬 |

🔬 = must re-certify in [RELEASE-CHECKLIST.md](./RELEASE-CHECKLIST.md) after Phase 2.

---

## 6. Adding a new certified row

1. Complete full [RELEASE-CHECKLIST.md](./RELEASE-CHECKLIST.md) on target environment
2. Record versions: OS build, `pwsh --version`, WT version
3. Append row to §1 or §2 with date and release tag
4. Update [COMPATIBILITY.md](./COMPATIBILITY.md) if policy changes

---

## 7. Related

- [COMPATIBILITY.md](./COMPATIBILITY.md)
- [SUPPORT-POLICY.md](./SUPPORT-POLICY.md)
- [QUICKSTART.md](./QUICKSTART.md)
