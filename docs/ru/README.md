# HOME BASE — справочник команд (RU)

> **Продукт и установка:** главная документация — [README.ru.md](../README.ru.md) (русский) · [README.md](../README.md) (English)

Центр управления рабочей станцией после установки HomeBase DevShell.

## Навигация

| Команда | Что делает |
|---------|------------|
| `go` / **Ctrl+Alt+G** | Двухуровневое меню: **[следующий]** из home → категории → Enter=действие |
| `menu` / `palette` | То же, что `go` |
| `sec` / **Ctrl+Alt+S** | Только Tor + PGP |
| **Ctrl+Alt+K** | `komandy` — справочник |
| **Ctrl+Alt+B** | `home` — обзор |

**Enter** = выполнить · **Esc** = назад · **Ctrl+/** = справка · фильтр: `папки` `порядок` `doctor`

### Категории в `go`

| Категория | Примеры |
|-----------|---------|
| **папки** | projects, downloads, desktop, backups, configs, networking |
| **порядок** | revise, organize, sysaudit, cleanup, backupconfig |
| система | home, doctor, trustcheck, scan |
| разработка / сеть / безопасность / обслуживание / справка | как в komandy |
| **[nav] all** | все команды + `[cmd]` из справочника |

## Быстрый старт (после install)

1. Windows Terminal → PowerShell 7  
2. `devshell doctor` — окружение готово  
3. `home` — обзор  
4. `go` — меню действий  

## Доверие

HOME BASE **не врёт**: score = min(WOC, Trust). Подробнее: [TRUST.md](TRUST.md)

## Безопасность (SHADOW OPS)

| Команда | Назначение |
|---------|------------|
| `sec` | Меню Tor + PGP |
| `tor-check` | Чеклист перед сессией |
| `tor-harden` | Hardening Tor Browser |
| `pgp-fingerprint` | Отпечаток ключа |

Подробнее: [TOR-MAX-SECURITY.md](TOR-MAX-SECURITY.md) · [PGP-TOR-BASICS.md](PGP-TOR-BASICS.md)

## Обслуживание

| Команда | Назначение |
|---------|------------|
| `doctor` | 72+ тестов |
| `trustcheck` | Live integrity |
| `repairterminal` | OMP, профиль, шрифты |

## Команды

Полный список: [COMMANDS.md](COMMANDS.md) · шпаргалка: [QUICKREF.md](QUICKREF.md)
