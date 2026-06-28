# HOME BASE — Quickstart

Пошаговая инструкция: от установки до ежедневной работы.

---

## 1. Требования

| Компонент | Минимум | Рекомендуется |
|-----------|---------|---------------|
| ОС | Windows 10/11 x64 | Windows 11 25H2+ |
| Shell | PowerShell 7.0+ | PowerShell 7.6+ |
| Terminal | Windows Terminal | WT + default profile PS7 |
| Шрифт | Nerd Font | CaskaydiaCove NF |
| Менеджер пакетов | winget | winget |
| Git | 2.40+ | latest |
| Python | 3.12+ | для venv/dev |

**Политика:** Microsoft Defender AV остаётся отключённым по design (см. SECURITY-POLICY).

**Пути (runtime):**

```
C:\Tools          C:\Scripts\Workstation (repo)
C:\Projects       C:\Logs\Workstation
C:\Backups\Workstation   C:\Configs\Workstation
C:\Security       C:\Temp\Scratch
```

---

## 2. Установка

### 2.1. Первичная установка

```powershell
# User-level
pwsh -File C:\Scripts\Workstation\Install-Workstation.ps1

# Полная (admin): hardening, privacy, firewall
Start-Process pwsh -Verb RunAs -ArgumentList `
  '-File C:\Scripts\Workstation\Install-Workstation.ps1 -Force'
```

### 2.2. Deploy профиля и терминала

```powershell
fixprofile          # = repairterminal: шрифты, OMP, WT, profile
```

**Обязательно:** закрыть **все** терминалы → открыть **Windows Terminal** (`wt.exe`).

Legacy ConsoleHost даёт audit warning и некорректный fastfetch.

### 2.3. Первый запуск

```powershell
reloadprofile
home
```

Ожидаемо:

- trust **VERIFIED** (или STALE → `trustcheck`)
- doctor при необходимости: `doctor`
- `pwd` → `C:\Projects` (после Initialize-WorkstationSession)

---

## 3. Проверка состояния

```powershell
doctor              # 75/75 PASS
trustcheck          # live probe
revise              # полный revision pass
go                  # menu audit implicit
```

Отчёты:

```
C:\Logs\Workstation\validation-*.json
C:\Logs\Workstation\trust-report.json
C:\Logs\Workstation\command-health.json
```

---

## 4. Ежедневная работа

| Когда | Команда |
|-------|---------|
| Утро | `devstart` или `home` |
| Навигация | `go` (Ctrl+Alt+G) |
| Security session | `anon` (Ctrl+Alt+S) |
| Перед экспериментами | `backupconfig` |
| Конец недели | `revise -Backup` |

---

## 5. Обслуживание

```powershell
# Безопасная очистка — ВСЕГДА сначала:
cleanup -WhatIf
cleanup

# Порядок в папках:
organize -WhatIf
organize

# Housekeeping (ротация logs/backups):
# через Invoke-Housekeeping.ps1 или revise
```

---

## 6. Обновление

```powershell
updateall           # winget + PS modules
reloadprofile
doctor
revise -Quick
```

После изменений в canonical profile:

```powershell
fixprofile
reloadprofile
```

---

## 7. Восстановление

```powershell
backupconfig                              # создать снимок
restoreconfig                             # admin, последний backup
# или
restoreconfig -BackupFolder 'C:\Backups\Workstation\20260629-003901'
```

См. [BACKUP-POLICY.md](./BACKUP-POLICY.md)

---

## 8. Troubleshooting

| Симптом | Действие |
|---------|----------|
| trust UNTRUSTED | `trustcheck` → `doctor` → `repairterminal` |
| revise падает | `reloadprofile` → `revise -Quick` |
| Модуль не загружен | `reloadprofile` или `Ensure-WorkstationModuleLoaded` |
| health 88%, trust 100% | WOC warnings — см. `home -Full` |
| pwd System32 | перезапуск WT, не ConsoleHost |
| OMP/шрифт сломан | `fixprofile` |

---

## 9. Следующие шаги

- [ARCHITECTURE.md](./ARCHITECTURE.md) — как устроено
- [COMMAND-STANDARD.md](./COMMAND-STANDARD.md) — как добавлять команды
- [docs/ru/COMMANDS.md](../ru/COMMANDS.md) — полный каталог
