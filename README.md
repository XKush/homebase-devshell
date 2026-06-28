# HOME BASE

**Персональная операционная среда инженера на Windows + PowerShell 7**

| | |
|---|---|
| **Модуль** | `KGreen.Workstation` |
| **Версия** | 2.0.0 |
| **Лицензия** | [MIT](LICENSE) |
| **Язык UI** | RU-first |
| **Статус** | Production-ready |

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

Полный текст: [docs/charter/PHILOSOPHY.md](docs/charter/PHILOSOPHY.md)

---

## Быстрый старт

```powershell
# Установка
pwsh -File C:\Scripts\Workstation\Install-Workstation.ps1

# После установки
fixprofile                    # deploy profile + terminal
# Закрыть все терминалы → открыть Windows Terminal (wt.exe)
reloadprofile
home                          # cockpit
go                            # меню действий
revise                        # полный цикл (doctor + trust)
trustcheck                    # spot-check доверия
```

Подробно: [docs/charter/QUICKSTART.md](docs/charter/QUICKSTART.md)

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

Справка: `имя -help` · `komandy` · [docs/ru/COMMANDS.md](docs/ru/COMMANDS.md)

---

## Политика и безопасность

| Документ | Назначение |
|----------|------------|
| [LICENSE](LICENSE) | MIT License |
| [SECURITY.md](SECURITY.md) | Responsible disclosure |
| [docs/charter/SECURITY-POLICY.md](docs/charter/SECURITY-POLICY.md) | Цепочка безопасных операций |

> HOME BASE включает security-автоматизацию для **авторизованного lab use**.
> Пользователь отвечает за соблюдение местного законодательства.
> Microsoft Defender AV **намеренно не включается** этим проектом.

---

## Charter Pack — официальная «Конституция»

| # | Документ | Назначение |
|---|----------|------------|
| 1 | [docs/charter/README.md](docs/charter/README.md) | Обзор charter |
| 2 | [QUICKSTART.md](docs/charter/QUICKSTART.md) | Установка и ежедневная работа |
| 3 | [ARCHITECTURE.md](docs/charter/ARCHITECTURE.md) | Архитектура системы |
| 4 | [PHILOSOPHY.md](docs/charter/PHILOSOPHY.md) | Миссия и принципы |
| 5 | [CODING-STANDARD.md](docs/charter/CODING-STANDARD.md) | Стандарт разработки |
| 6 | [UI-STYLE-GUIDE.md](docs/charter/UI-STYLE-GUIDE.md) | Единый интерфейс |
| 7 | [LANGUAGE-POLICY.md](docs/charter/LANGUAGE-POLICY.md) | Локализация RU/EN |
| 8 | [SECURITY-POLICY.md](docs/charter/SECURITY-POLICY.md) | Безопасность операций |
| 9 | [BACKUP-POLICY.md](docs/charter/BACKUP-POLICY.md) | Backup / restore / archive |
| 10 | [LOGGING-STANDARD.md](docs/charter/LOGGING-STANDARD.md) | Логирование |
| 11 | [COMMAND-STANDARD.md](docs/charter/COMMAND-STANDARD.md) | Стандарт команд |
| 12 | [TESTING-STANDARD.md](docs/charter/TESTING-STANDARD.md) | Тестирование |
| 13 | [VERSIONING.md](docs/charter/VERSIONING.md) | Semver |
| 14 | [LIFECYCLE.md](docs/charter/LIFECYCLE.md) | Жизненный цикл команд |
| 15 | [ROADMAP.md](docs/charter/ROADMAP.md) | Дорожная карта |
| 16 | [CONTRIBUTING.md](docs/charter/CONTRIBUTING.md) | Участие в проекте |
| 17 | [CHANGELOG.md](docs/charter/CHANGELOG.md) | История изменений |
| 18 | [adr/](docs/charter/adr/) | Architecture Decision Records |
| 19 | [EXECUTION-PLAN.md](docs/charter/EXECUTION-PLAN.md) | План модернизации |
| 20 | [EXECUTIVE-SUMMARY.md](docs/charter/EXECUTIVE-SUMMARY.md) | Итоговый отчёт |

### Release (Phase 1.5)

| Документ | Назначение |
|----------|------------|
| [RELEASE-CHECKLIST.md](docs/charter/RELEASE-CHECKLIST.md) | Чек-лист перед tag |
| [RELEASE-REQUIREMENTS.md](docs/charter/RELEASE-REQUIREMENTS.md) | PATCH / MINOR / MAJOR |
| [SUPPORT-POLICY.md](docs/charter/SUPPORT-POLICY.md) | Supported / Deprecated |
| [COMPATIBILITY.md](docs/charter/COMPATIBILITY.md) | PowerShell / Windows |
| [ENVIRONMENT-MATRIX.md](docs/charter/ENVIRONMENT-MATRIX.md) | Протестированные окружения |

```powershell
pwsh -File C:\Scripts\Workstation\Test-ReleaseVersion.ps1
```

**Rollback anchor:** `git checkout v2.0.0` (product) · docs commits без tag

| Документ | Назначение |
|----------|------------|
| [MIGRATION.md](docs/charter/MIGRATION.md) | Migration policy — контракт Phase 2 |
| [ARCHITECTURE-FREEZE.md](docs/charter/ARCHITECTURE-FREEZE.md) | Freeze до завершения Phase 2 |

---

## Связанная документация

| Путь | Содержание |
|------|------------|
| [docs/ru/QUICKREF.md](docs/ru/QUICKREF.md) | Быстрая справка (auto-sync) |
| [docs/ru/COMMANDS.md](docs/ru/COMMANDS.md) | Каталог команд |
| [docs/ru/TRUST.md](docs/ru/TRUST.md) | Trust system |
| [docs/ru/PGP-TOR-BASICS.md](docs/ru/PGP-TOR-BASICS.md) | Tor + PGP |

---

*HOME BASE v2.0.0 · MIT License · See [SECURITY.md](SECURITY.md) for vulnerability reporting*
