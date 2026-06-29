# HOME BASE — документация (RU)

Центр управления рабочей станцией KGreen.

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

## Быстрый старт

1. Откройте **Windows Terminal** → PowerShell 7
2. `home` — обзор (режим minimal по умолчанию)
3. `go` — **[следующий]** шаг сверху или категория **порядок**
4. `organize -WhatIf` — проверить структуру папок и Downloads
5. `revise` / `poriadok` — полный порядок (doctor + trust + sec)
6. `sec` — Tor + PGP (SHADOW OPS)

## Режимы запуска

| Переменная | Значение | Эффект |
|------------|----------|--------|
| `WORKSTATION_STARTUP_MODE` | `minimal` | Trust + telemetry (по умолчанию) |
| | `normal` | + changelog + command matrix + SHADOW OPS |
| | `full` | + inventory + network intel |

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

## Порядок на диске

| Команда | Назначение |
|---------|------------|
| `organize` | Структура папок, README, архив installers из Downloads |
| `organize -WhatIf` | Только план, без изменений |
| `sysaudit` | Аудит: что нужно поправить |
| `revise` / `poriadok` | Полный прогон: PATH, docs, doctor, trust, sec |
| `cleanup -WhatIf` | Безопасная очистка (сначала просмотр) |
| `backupconfig` | Бэкап настроек |

Карта папок: `C:\Projects`, `C:\Tools`, `C:\Scripts`, Downloads → `C:\Downloads\Archive`, см. `lib/WorkstationFolders.ps1`.

## Обслуживание

| Команда | Назначение |
|---------|------------|
| `doctor` | 72+ тестов |
| `trustcheck` | Live integrity |
| `repairterminal` | OMP, профиль, шрифты |

## Команды

Полный список: [COMMANDS.md](COMMANDS.md) · шпаргалка: [QUICKREF.md](QUICKREF.md)

Обновить docs из каталога: `Sync-WorkstationDocs.ps1`

## Обновление стека

```powershell
revise -Backup
C:\Scripts\Workstation\Invoke-HomeBaseUpgrade.ps1
```

Справка по любой команде: `имя -help`
