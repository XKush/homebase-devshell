# HOME BASE — Philosophy

Официальная философия проекта. Все архитектурные решения должны быть согласованы с этим документом.

---

## 1. Миссия

**Сделать персональную Windows-рабочую станцию инженера предсказуемой, проверяемой, восстанавливаемой и безопасной — через единый command center, а не через хаос скриптов.**

---

## 2. Цели

| # | Цель |
|---|------|
| G1 | Одна команда (`home`) — полная картина состояния |
| G2 | Нулевое доверие к UI без live-probe (`trust`) |
| G3 | Любое изменение откатываемо (`backupconfig` / `restoreconfig`) |
| G4 | Security workflow воспроизводим (`anon`, audits) |
| G5 | Onboarding нового инженера < 1 часа (`QUICKSTART`) |
| G6 | Готовность к Open Source без переписывания ядра |

---

## 3. Принципы (The Twelve)

| ID | Принцип | Практика |
|----|---------|----------|
| P01 | **Verify everything** | doctor, trustcheck, audits |
| P02 | **Never lie in UI** | `CanTrustDashboard`, honest score |
| P03 | **Backup before mutate** | backup-first policy |
| P04 | **Single source of truth** | registry, locale, paths config |
| P05 | **Minimal magic** | explicit module load order |
| P06 | **Security over convenience** | WhatIf, Confirm, scoped deletes |
| P07 | **Documentation is code** | comment-based help, charter |
| P08 | **Predictability over cleverness** | unified panels, stable commands |
| P09 | **Backward compatibility** | deprecate, never break silently |
| P10 | **Repository ≠ Runtime** | git ≠ logs/backups |
| P11 | **Global module scope** | `-Scope Global`, Ensure-Module |
| P12 | **RU UI, EN internals** | locale policy |

---

## 4. Ограничения (Non-Goals)

HOME BASE **не**:

- заменяет Active Directory / Intune / SCCM;
- управляет облачной инфраструктурой;
- включает Microsoft Defender AV (explicit policy);
- поддерживает Linux/macOS как primary platform;
- выполняет нелегитимные действия (lab / authorized use only).

---

## 5. Подход к автоматизации

```
Observe → Validate → Act → Verify → Log
```

- **Observe:** `home`, `scan`, WOC metrics
- **Validate:** `doctor`, selfcheck, `-WhatIf`
- **Act:** через `Invoke-WorkstationCmd` + registry
- **Verify:** post-check trust/doctor
- **Log:** `commands.log`, `workstation.log`, JSON reports

Автоматизация без проверки — **запрещена** для destructive ops.

---

## 6. Подход к безопасности

1. **Defence in depth:** UAC, firewall, Tor hardening, PGP identity
2. **Least destructive:** archive > delete; move > remove
3. **Transparency:** SECURITY-POLICY, audit JSON
4. **SHADOW OPS readiness:** Tor + PGP audits in Validate
5. **No silent elevation:** admin ops явно помечены

Цепочка опасной операции:

```
Validation → Backup → Confirmation → Execution → Logging → Rollback path
```

---

## 7. Подход к качеству

| Уровень | Механизм |
|---------|----------|
| Smoke | SelfCheck 72/72 |
| Integration | Menu audit, command health |
| Validation | Doctor 75 checks |
| Trust | Live probe scoring |
| Release | Acceptance test pipeline |

**Definition of Done** для изменения:

- [ ] doctor pass (or documented exception)
- [ ] trust VERIFIED or explained STALE
- [ ] charter docs updated if policy affected
- [ ] no breaking change without LIFECYCLE entry

---

## 8. Конфликт принципов

При конфликте приоритет:

```
Security (P06) > Truth (P02) > Compatibility (P09) > Convenience > Aesthetics
```

Пример: `cleanup` не удаляет backups — даже если «быстрее удалить».

---

## 9. Связанные документы

- [ARCHITECTURE.md](./ARCHITECTURE.md)
- [SECURITY-POLICY.md](./SECURITY-POLICY.md)
- [LIFECYCLE.md](./LIFECYCLE.md)
