# Режим доверия (Trust System)

HOME BASE показывает только **проверенные** данные.

## Принципы

1. **Live probe** — при `home` (режим strict) выполняется `Get-SystemTrustReport -Live`
2. **Self-check** — каждая команда проверяет backend до/после через `Invoke-WorkstationCmd`
3. **Честный score** — `min(WOC Health, Trust Score)`; при компрометации dashboard помечается явно
4. **Кэш** — `C:\Logs\Workstation\trust-report.json` (OMP prompt читает отсюда)

## Команды

| Команда | Назначение |
|---------|------------|
| `trustcheck` | Полный live probe + сохранение отчёта |
| `scan` | Быстрый probe (<2 с) |
| `doctor` | 74+ тестов валидации |

## Уровни

- **VERIFIED** — можно доверять dashboard
- **DEGRADED** — есть предупреждения
- **UNTRUSTED** — сломанные команды / self-check fail

## Env

- `WORKSTATION_TRUST_MODE=strict` — live probe на каждый `home` (default)
- `WORKSTATION_TRUST_MODE=fast` — использовать кэш до 15 мин

## Автоматизация

```powershell
Register-WorkstationTasks.ps1   # daily trust probe 08:00
Invoke-ScheduledTrustProbe.ps1  # ручной запуск (exit 1 если untrusted)
```
