# HOME BASE — Release Checklist

Единый чек-лист выпуска релиза. Использовать **перед каждым** Git tag `vX.Y.Z`.

**Rollback anchor:** `v2.0.0` (product) · **Phase 2 compare:** [phase2-step1-stable.json](../baselines/phase2-step1-stable.json)

---

## 0. Подготовка

- [ ] Все изменения закоммичены (working tree clean или только release docs)
- [ ] `backupconfig` выполнен
- [ ] Версия выбрана по [VERSIONING.md](./VERSIONING.md) (MAJOR / MINOR / PATCH)

---

## 1. Version sync (автоматически)

```powershell
pwsh -File C:\Scripts\Workstation\Test-ReleaseVersion.ps1 -RequireTagAtHead
```

| Проверка | Источник |
|----------|----------|
| ModuleVersion | `modules/KGreen.Workstation.psd1` |
| README | таблица **Версия** |
| CHANGELOG | `[X.Y.Z]` или `[Unreleased]` |
| Git tag | `vX.Y.Z` существует |

**Pass:** exit code `0`.

Обновить вручную при bump:

1. `KGreen.Workstation.psd1` → `ModuleVersion`
2. `README.md` → **Версия** + footer
3. `docs/charter/CHANGELOG.md` → секция `[X.Y.Z]` + дата
4. `git tag -a vX.Y.Z -m "HOME BASE vX.Y.Z"`

---

## 2. Документация

- [ ] [CHANGELOG.md](./CHANGELOG.md) — все изменения релиза описаны (Keep a Changelog)
- [ ] [LIFECYCLE.md](./LIFECYCLE.md) — новые deprecations / removals
- [ ] [SUPPORT-POLICY.md](./SUPPORT-POLICY.md) — supported line обновлена (если MINOR/MAJOR)
- [ ] [ENVIRONMENT-MATRIX.md](./ENVIRONMENT-MATRIX.md) — новые окружения (если тестировались)
- [ ] [SECURITY.md](../../SECURITY.md) — supported versions table (если MAJOR/EOL)

---

## 3. Runtime gate (обязательно)

```powershell
doctor
trustcheck
revise -Quick
Test-MenuDeepAudit.ps1
Test-WorkstationCommands.ps1 -Quick
Test-LegacyEquivalence.ps1          # Phase 2: behavior unchanged vs step1 baseline
```

| Gate | Pass criteria |
|------|---------------|
| doctor | 75/75, FailCount = 0 |
| trustcheck | VERIFIED, Score = 100 |
| revise -Quick | completes without error |
| MenuDeepAudit | exit 0 |
| Command test | exit 0 |

Полный релиз (MINOR/MAJOR):

```powershell
revise
Test-WorkstationCommands.ps1
Test-AnonymityKitAudit.ps1
```

---

## 4. Release requirements

Минимум по типу релиза — [RELEASE-REQUIREMENTS.md](./RELEASE-REQUIREMENTS.md).

| Type | Version sync | Runtime gate | Full revise | Anon audit |
|------|--------------|--------------|-------------|------------|
| PATCH | ✅ | Quick | optional | optional |
| MINOR | ✅ | Full | ✅ | ✅ |
| MAJOR | ✅ | Full + manual smoke | ✅ | ✅ + migration doc |

---

## 5. Tag и фиксация

```powershell
git add modules/KGreen.Workstation.psd1 README.md docs/charter/CHANGELOG.md
git commit -m "release: HOME BASE vX.Y.Z"
git tag -a vX.Y.Z -m "HOME BASE vX.Y.Z"
pwsh -File Test-ReleaseVersion.ps1 -RequireTagAtHead
```

- [ ] Tag annotated (`git show vX.Y.Z`)
- [ ] `Test-ReleaseVersion.ps1` PASS at HEAD
- [ ] Snapshot backup label noted in CHANGELOG (optional)

---

## 6. Post-release

- [ ] Push tag (when remote exists): `git push origin vX.Y.Z`
- [ ] GitHub Release notes from CHANGELOG section
- [ ] Notify: breaking changes / deprecations in release body

---

## Quick reference — v2.0.0 baseline

```powershell
# Verify rollback point still valid
git checkout v2.0.0
pwsh -File Test-ReleaseVersion.ps1 -RequireTagAtHead
```

---

## Related

- [RELEASE-REQUIREMENTS.md](./RELEASE-REQUIREMENTS.md)
- [TESTING-STANDARD.md](./TESTING-STANDARD.md) §2.7
- [VERSIONING.md](./VERSIONING.md)
- [EXECUTION-PLAN.md](./EXECUTION-PLAN.md) Phase 1.5
