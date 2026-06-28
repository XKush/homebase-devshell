# HOME BASE — документация (RU)

Центр управления рабочей станцией KGreen.

## Быстрый старт

1. Откройте **Windows Terminal** → PowerShell 7
2. `home` — обзор (режим minimal по умолчанию)
3. `scan` — быстрая проверка за ~2 с
4. `hack` или `menu` — MAX mode / fzf-меню
5. `palette` или **Ctrl+Alt+H** — поиск команды

## Режимы запуска

| Переменная | Значение | Эффект |
|------------|----------|--------|
| `WORKSTATION_STARTUP_MODE` | `minimal` | Trust + telemetry (по умолчанию) |
| | `normal` | + changelog + command matrix |
| | `full` | + inventory + network intel |

## Доверие

HOME BASE **не врёт**: score = min(WOC, Trust). Подробнее: [TRUST.md](TRUST.md)

## Команды

Полный список: [COMMANDS.md](COMMANDS.md) · сгенерированная шпаргалка: [QUICKREF.md](QUICKREF.md)

## Обновление

```powershell
C:\Scripts\Workstation\Invoke-HomeBaseUpgrade.ps1
C:\Scripts\Workstation\Invoke-WindowsTunePass.ps1   # privacy + perf + network
```

## Windows

| Команда | Назначение |
|---------|------------|
| `windowsstatus` | Privacy, firewall, UAC, backups, updates |
| `securitycheck` | UAC, firewall, SMB1 |
| `updateall` | winget upgrades |
