# HOME BASE — Charter overview (archived)

> Superseded by [README.md](../../README.md) · Active charter index: [../charter/README.md](../charter/README.md)

---

# HOME BASE

**Персональная операционная среда инженера на Windows + PowerShell 7**

| | |
|---|---|
| **Модуль** | `KGreen.Workstation` |
| **Версия charter** | 2.0.0 |
| **Репозиторий** | `C:\Scripts\Workstation` |
| **Язык UI** | RU-first |
| **Статус** | Production-ready (internal) |

---

## Что такое HOME BASE?

HOME BASE — это не «папка со скриптами», а **command center**: единая точка входа для разработки, диагностики, обслуживания, резервного копирования, проверки доверия к системе и security/anonymity workflow (Tor + OpenPGP).

HOME BASE отвечает на вопросы:

- **Можно ли верить панели `home`?** → Trust system (live-probe)
- **Всё ли установлено и работает?** → `doctor` (75 проверок)
- **Что делать дальше?** → `go` / `[следующий]`
- **Как навести порядок?** → `revise`
- **Как работать анонимно?** → `anon` (Tor + PGP)

---

## Возможности

| Область | Команды / компоненты |
|---------|----------------------|
| **Cockpit** | `home`, `go`, `devstart` |
| **Диагностика** | `doctor`, `trustcheck`, `scan`, `windowsstatus` |
| **Обслуживание** | `revise`, `organize`, `cleanup`, `housekeeping` |
| **Backup** | `backupconfig`, `restoreconfig`, `_Archive` |
| **Безопасность** | `sec`, `anon`, `tor-*`, `pgp-*` |
| **Сеть / tools** | `nettools`, `toolcheck`, `sysaudit` |
| **Восстановление** | `repairterminal`, `fixprofile`, `reloadprofile` |

**Hotkeys:** Ctrl+Alt+G (`go`) · Ctrl+Alt+S (`anon`) · Ctrl+Alt+B (`home`) · Ctrl+Alt+K (`komandy`)

---

## Принципы (кратко)

1. HOME BASE **не врёт** — при проблемах trust показывает UNTRUSTED/STALE.
2. Любое изменение **можно откатить** — backup-before-mutate.
3. **Один источник истины** — registry, locale, paths (целевое состояние v2.2+).
4. **Repository ≠ Runtime** — код в git, состояние на диске отдельно.
5. **Обратная совместимость** — deprecate → alias → remove (мин. 2 minor).

Полный текст: [PHILOSOPHY.md](./PHILOSOPHY.md)

---

## Быстрый старт

```powershell
# После установки (Install-Workstation.ps1)
fixprofile                    # deploy profile + terminal
# Закрыть все терминалы → открыть Windows Terminal (wt.exe)
reloadprofile
home                          # cockpit
go                            # меню действий
revise                        # полный цикл (doctor + trust)
trustcheck                      # spot-check доверия
```

Подробно: [QUICKSTART.md](./QUICKSTART.md)

---

## Основные команды

| Команда | Назначение |
|---------|------------|
| `home` | Neural cockpit — health, trust, next steps |
| `go` | Двухуровневое меню: [anon] + [следующий] + категории |
| `doctor` | Validate-Workstation — 75 проверок |
| `trustcheck` | Live integrity probe |
| `revise` | PATH + sync + doctor + trust + next actions |
| `backupconfig` | Снимок профиля и конфигов |
| `cleanup -WhatIf` | Безопасная очистка (сначала preview) |
| `anon` | Швейцарский нож Tor + PGP |

Справка: `имя -help` · `komandy` · [docs/ru/COMMANDS.md](../ru/COMMANDS.md)

---

## Charter Pack — официальная «Конституция»

| # | Документ | Назначение |
|---|----------|------------|
| 1 | [README.md](./README.md) | Этот документ |
| 2 | [QUICKSTART.md](./QUICKSTART.md) | Установка и ежедневная работа |
| 3 | [ARCHITECTURE.md](./ARCHITECTURE.md) | Архитектура системы |
| 4 | [PHILOSOPHY.md](./PHILOSOPHY.md) | Миссия и принципы |
| 5 | [CODING-STANDARD.md](./CODING-STANDARD.md) | Стандарт разработки |
| 6 | [UI-STYLE-GUIDE.md](./UI-STYLE-GUIDE.md) | Единый интерфейс |
| 7 | [LANGUAGE-POLICY.md](./LANGUAGE-POLICY.md) | Локализация RU/EN |
| 8 | [SECURITY-POLICY.md](./SECURITY-POLICY.md) | Безопасность операций |
| 9 | [BACKUP-POLICY.md](./BACKUP-POLICY.md) | Backup / restore / archive |
| 10 | [LOGGING-STANDARD.md](./LOGGING-STANDARD.md) | Логирование |
| 11 | [COMMAND-STANDARD.md](./COMMAND-STANDARD.md) | Стандарт команд |
| 12 | [TESTING-STANDARD.md](./TESTING-STANDARD.md) | Тестирование |
| 13 | [VERSIONING.md](./VERSIONING.md) | Semver |
| 14 | [LIFECYCLE.md](./LIFECYCLE.md) | Жизненный цикл команд |
| 15 | [ROADMAP.md](./ROADMAP.md) | Дорожная карта |
| 16 | [CONTRIBUTING.md](./CONTRIBUTING.md) | Участие в проекте |
| 17 | [CHANGELOG.md](./CHANGELOG.md) | История изменений |
| 18 | [LICENSE-RECOMMENDATION.md](./LICENSE-RECOMMENDATION.md) | Выбор лицензии |
| 19 | [adr/](./adr/) | Architecture Decision Records |
| 20 | [EXECUTION-PLAN.md](./EXECUTION-PLAN.md) | План модернизации |
| — | [EXECUTIVE-SUMMARY.md](./EXECUTIVE-SUMMARY.md) | Итоговый отчёт |

### Release stabilization (Phase 1.5)

| # | Документ | Назначение |
|---|----------|------------|
| — | [RELEASE-CHECKLIST.md](./RELEASE-CHECKLIST.md) | Единый чек-лист релиза |
| — | [RELEASE-REQUIREMENTS.md](./RELEASE-REQUIREMENTS.md) | Минимум PATCH / MINOR / MAJOR |
| — | [SUPPORT-POLICY.md](./SUPPORT-POLICY.md) | Supported / Deprecated / Experimental |
| — | [COMPATIBILITY.md](./COMPATIBILITY.md) | PowerShell + Windows |
| — | [ENVIRONMENT-MATRIX.md](./ENVIRONMENT-MATRIX.md) | Матрица окружений |
| — | [../../Test-ReleaseVersion.ps1](../../Test-ReleaseVersion.ps1) | Автопроверка версии |
| — | [MIGRATION.md](./MIGRATION.md) | Migration policy (Phase 2 контракт) |
| — | [ARCHITECTURE-FREEZE.md](./ARCHITECTURE-FREEZE.md) | Freeze до Phase 2 |

**Product baseline tag:** `v2.0.0` · Process docs = commit без tag

---

## Связанная документация (операционная)

| Путь | Содержание |
|------|------------|
| [docs/ru/QUICKREF.md](../ru/QUICKREF.md) | Быстрая справка (auto-sync) |
| [docs/ru/COMMANDS.md](../ru/COMMANDS.md) | Каталог команд |
| [docs/ru/TRUST.md](../ru/TRUST.md) | Trust system |
| [docs/ru/PGP-TOR-BASICS.md](../ru/PGP-TOR-BASICS.md) | Tor + PGP |

---

## Политика проекта

- **Product baseline:** Git tag **`v2.0.0`** — единственная официальная точка продукта.
- **Architecture Freeze** активен до Phase 2 — [ARCHITECTURE-FREEZE.md](docs/charter/ARCHITECTURE-FREEZE.md).
- **Migration contract:** [MIGRATION.md](docs/charter/MIGRATION.md).
- **Код не меняется** без Charter Pack, MIGRATION.md и EXECUTION-PLAN.
- **Breaking changes** — только с migration guide и мин. 2 minor releases warning.
- **Tags** — только при изменении продукта (не docs/process).

---

*HOME BASE Charter Pack v2.0.0 · Generated 2026-06-29*
