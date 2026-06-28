# HOME BASE — Quick Reference (RU)

Generated: 2026-06-28 21:31

## Команды быстрого доступа

| Команда | Назначение |
|---------|------------|

## Система

- **doctor** — Запускает полную автоматическую проверку рабочей станции (68+ тестов). → `doctor`
- **healthcheck** — Синоним команды doctor — полная проверка системы. → `healthcheck`
- **instrumenty** — Показывает все установленные программы с объяснением на русском. → `instrumenty`
- **scan** — Мини-скан: trust score + self-check ключевых команд за ~2 с. → `scan`
- **securitycheck** — Показывает состояние UAC, firewall (брандмауэр), SMB1 и телеметрии. → `securitycheck`
- **sysinfo** — Показывает красивую сводку: ОС, процессор, память, диск (через fastfetch). → `sysinfo`
- **sysreport** — Создаёт подробный текстовый отчёт и сохраняет его в C:\Logs\Workstation. → `sysreport`
- **trustcheck** — Live-проверка: самопроверки команд, сломанные backend, синхронизация профиля. → `trustcheck`
- **workstationstatus** — Открывает HOME BASE (домашнюю панель) в выбранном режиме. → `workstationstatus`

## Сеть

- **nettools** — Справочник по сетевым инструментам и их проверка. → `nettools`
- **networkstatus** — Показывает адаптеры, IP-адреса, DNS и firewall (брандмауэр). → `networkstatus`
- **portscan** — Проверяет, открыты ли указанные порты на удалённом компьютере. → `portscan 192.168.1.1`
- **sysaudit** — Проверяет структуру папок и порядок на рабочей станции. → `sysaudit`
- **toolbox** — Показывает все группы команд и проверяет инструменты. → `toolbox`
- **toolcheck** — Проверяет, какие программы установлены и какие отсутствуют. → `toolcheck`

## Разработка

- **devinfo** — Показывает версии pwsh, git, python, node и настройки git. → `devinfo`
- **devstart** — Переходит в папку проектов и открывает домашнюю панель. → `devstart`
- **new-project** — Создаёт папку проекта с git init и .gitignore. → `new-project MyApp`
- **projects** — Быстрый переход в папку со всеми проектами. → `projects`
- **workspace** — Показывает, где вы находитесь, статус git и наличие .venv. → `workspace`

## Обслуживание

- **backupconfig** — Сохраняет профиль PowerShell и конфиги в C:\Backups\Workstation. → `backupconfig`
- **cleanup** — Удаляет старые логи, лишние бэкапы и временные файлы. → `cleanup`
- **logs** — Показывает последние файлы в C:\Logs\Workstation. → `logs`
- **updateall** — Обновляет пакеты через winget и модули PowerShell. → `updateall`

## Восстановление

- **fixprofile** — То же, что repairterminal — починка профиля и терминала. → `fixprofile`
- **reloadprofile** — Перечитывает $PROFILE без перезапуска терминала. → `reloadprofile`
- **repairterminal** — Восстанавливает шрифты, Oh My Posh, Windows Terminal и fastfetch. → `repairterminal`
- **restoreconfig** — Откатывает настройки из папки C:\Backups\Workstation (нужен admin). → `restoreconfig`

## Обучение

- **cheatsheet** — Открывает файл CHEATSHEET.md с кратким справочником. → `cheatsheet`
- **dashboard** — То же, что home и jarvis. → `dashboard`
- **hack** — Полный хакерский cockpit или fzf-меню (если установлен fzf). → `hack`
- **help** — То же, что helpme — справочник по командам оболочки. → `help`
- **helpme** — Интерактивная справка по группам: git, python, nav, tools. → `helpme`
- **home** — Открывает HOME BASE в режиме normal — trust + telemetry + command matrix. → `home`
- **jarvis** — Открывает HOME BASE — центр управления рабочей станцией. → `jarvis`
- **komandy** — Показывает все команды, сгруппированные по категориям. → `komandy`
- **learn** — Краткие уроки по git, python, PowerShell и VS Code. → `learn -Topic git`
- **menu** — Главное меню: cockpit, scan, trust, network, dev, palette. → `menu`
- **palette** — Интерактивный поиск по всем командам HOME BASE. → `palette`
- **quickstart** — 5 шагов для нового пользователя системы. → `quickstart`

## Режимы

- `hack` / `menu` — max cockpit / fzf menu
- `scan` — быстрый probe
- `palette` — fzf palette (Ctrl+Alt+H)
- `trustcheck` — live integrity

## Env

- WORKSTATION_STARTUP_MODE = minimal|normal|full
- WORKSTATION_TRUST_MODE = strict|normal|fast
- WORKSTATION_HACKER_UI = 1

