# HOME BASE — документация (RU)

Центр управления рабочей станцией KGreen.

## Быстрый старт

1. Откройте **Windows Terminal** → PowerShell 7
2. `home` — обзор (режим minimal по умолчанию)
3. `revise` или `poriadok` — навести порядок (doctor + trust + sec)
4. `sec` — Tor + PGP (SHADOW OPS)
5. `menu` / `hack` — hacker-меню · `palette` / **Ctrl+Alt+H**

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
| `tor-lock` | Kill switch (UAC admin) |
| `pgp-fingerprint` | Отпечаток ключа |

Подробнее: [TOR-MAX-SECURITY.md](TOR-MAX-SECURITY.md) · [PGP-TOR-BASICS.md](PGP-TOR-BASICS.md)

## Обслуживание

| Команда | Назначение |
|---------|------------|
| `revise` / `poriadok` | Полный прогон порядка |
| `doctor` | 68+ тестов |
| `trustcheck` | Live integrity |
| `backupconfig` | Бэкап настроек |

## Команды

Полный список: [COMMANDS.md](COMMANDS.md) · шпаргалка: [QUICKREF.md](QUICKREF.md)

Обновить docs из каталога: `Sync-WorkstationDocs.ps1`

## Обновление стека

```powershell
revise -Backup
C:\Scripts\Workstation\Invoke-HomeBaseUpgrade.ps1
```

Справка по любой команде: `имя -help`
