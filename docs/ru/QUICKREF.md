# HOME BASE — Quick Reference (RU)

Generated: 2026-06-28 23:39

## Быстрый доступ

| Команда | Назначение |
|---------|------------|
| `sec` | Tor + PGP |
| `menu` | Главное меню |
| `palette` | Поиск команд (fzf) |
| `trustcheck` | Live integrity |
| `tor-check` | Preflight Tor |


## Система

- **dna** — SHA256 отпечаток: MachineGuid + profile + module + git + trust. → `dna`
- **doctor** — Запускает полную автоматическую проверку рабочей станции (74+ тестов). → `doctor`
- **genesis** — Обновляет OP-DNA, append Trust Chain, экспорт C:\\Security\\exports\\genesis-certificate.txt → `genesis`
- **healthcheck** — Синоним команды doctor — полная проверка системы. → `healthcheck`
- **instrumenty** — Показывает все установленные программы с объяснением на русском. → `instrumenty`
- **scan** — Мини-скан: trust score + self-check ключевых команд за ~2 с. → `scan`
- **securitycheck** — Показывает состояние UAC, firewall (брандмауэр), SMB1 и телеметрии. → `securitycheck`
- **singularity** — Полный probe + Operator DNA + Trust Chain + Genesis Certificate. Уникальный отпечаток оператора. → `singularity`
- **sysinfo** — Показывает красивую сводку: ОС, процессор, память, диск (через fastfetch). → `sysinfo`
- **sysreport** — Создаёт подробный текстовый отчёт и сохраняет его в C:\Logs\Workstation. → `sysreport`
- **trustchain** — Каждый trustcheck/singularity добавляет блок с hash предыдущего. → `trustchain`
- **trustcheck** — Live-проверка: самопроверки команд, сломанные backend, синхронизация профиля. → `trustcheck`
- **windowsstatus** — Privacy, performance, firewall, UAC, backups, pending updates. → `windowsstatus`
- **workstationstatus** — Открывает HOME BASE (домашнюю панель) в выбранном режиме. → `workstationstatus`

## Безопасность

- **pgp-decrypt** — Расшифровка .gpg локально (нужен приватный ключ + passphrase). → `pgp-decrypt -File secret.txt.gpg`
- **pgp-encrypt** — Шифрует файл для получателя (публичный ключ или ID). → `pgp-encrypt -To A12238F6 -File secret.txt`
- **pgp-export** — Экспорт .asc для контактов (не приватный ключ!). → `pgp-export`
- **pgp-fingerprint** — Fingerprint для проверки личности out-of-band. → `pgp-fingerprint`
- **pgp-help** — Основы OpenPGP для Tor-контекста. → `pgp-help`
- **pgp-repair** — Экспорт публичного ключа и backup revocation, если ключ есть, но setup не завершился. → `pgp-repair`
- **pgp-setup** — Guided Ed25519 ключ (псевдоним, passphrase). → `pgp-setup`
- **pgp-status** — Список secret keys + fingerprint из метаданных. → `pgp-status`
- **privacy** — То же, что sec — меню Tor + PGP. → `privacy`
- **sec** — Меню: статус, порядок сессии, все действия через fzf. → `sec`
- **sec-help** — Команды, порядок сессии, правила «никогда». → `sec-help`
- **tor-check** — Tor Browser, PGP, user.js hardening, политика Defender. → `tor-check`
- **tor-harden** — user.js hardening + правила сессии. → `tor-harden`
- **tor-help** — Краткая шпаргалка Tor-команд. → `tor-help`
- **tor-setup** — Официальный Tor Browser через winget. → `tor-setup`
- **tor-status** — Tor Browser, hardening, user.js. → `tor-status`

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
- **organize** — Создаёт стандартные папки, README, архивирует installers из Downloads (с бэкапом). → `organize -WhatIf`
- **poriadok** — То же, что revise — «навести порядок». → `poriadok`
- **revise** — Полный прогон: PATH, docs sync, doctor, trust, sec, next actions. → `revise`
- **updateall** — Обновляет пакеты через winget и модули PowerShell. → `updateall`

## Восстановление

- **fixprofile** — То же, что repairterminal — починка профиля и терминала. → `fixprofile`
- **reloadprofile** — Перечитывает $PROFILE без перезапуска терминала. → `reloadprofile`
- **repairterminal** — Восстанавливает шрифты, Oh My Posh, Windows Terminal и fastfetch. → `repairterminal`
- **restoreconfig** — Откатывает настройки из папки C:\Backups\Workstation (нужен admin). → `restoreconfig`

## Обучение

- **cheatsheet** — Открывает файл CHEATSHEET.md с кратким справочником. → `cheatsheet`
- **dashboard** — Расширенный обзор HOME BASE. → `dashboard`
- **go** — [следующий] из home + категории (папки, порядок, система…) + все команды. Enter=выполнить. → `go`
- **hack** — То же, что menu — запуск частых действий через fzf. → `hack`
- **help** — То же, что helpme — справочник по командам оболочки. → `help`
- **helpme** — Интерактивная справка по группам: git, python, nav, tools. → `helpme`
- **home** — Компактная панель: trust, telemetry, подсказки. По умолчанию minimal. → `home`
- **jarvis** — Расширенный обзор HOME BASE (режим full). → `jarvis`
- **komandy** — Показывает все команды, сгруппированные по категориям. → `komandy`
- **learn** — Квесты 1–6 и темы: git, python, security, HOME BASE. → `learn -Quest 6`
- **menu** — То же, что go. → `menu`
- **nav** — nav -Start sec — только безопасность. → `nav -Start sec`
- **palette** — То же, что go. → `palette`
- **quickstart** — 5 шагов для нового пользователя системы. → `quickstart`

## Навигация

- **backups** — C:\Backups\Workstation — снимки backupconfig и organize. → `backups`
- **configs** — C:\Configs\Workstation — экспортированные настройки. → `configs`
- **desktop** — Переход на рабочий стол пользователя. → `desktop`
- **downloads** — Переход в Downloads; -Archive — C:\Downloads\Archive\Installers. → `downloads`
- **networking** — C:\Networking — captures, docs, scripts. → `networking`
- **scripts** — Переход в папку со скриптами рабочей станции. → `scripts`
- **tools** — Переход в папку с установленными утилитами. → `tools`

## Tor + PGP — порядок

1. `sec` или `tor-check`
2. `tor-harden` (один раз)
3. Tor Browser + `pgp-fingerprint`
4. закрой Tor Browser после сессии

## Переменные

- WORKSTATION_STARTUP_MODE = minimal|normal|full
- WORKSTATION_TRUST_MODE = strict|normal|fast
- WORKSTATION_HACKER_UI = 1

