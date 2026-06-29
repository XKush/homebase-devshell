# Команды HOME BASE

Generated: 2026-06-28 23:39

Справка: ``имя -help`` · меню: ``sec`` · ``menu``

## Система

_

| Команда | Описание |
|---------|----------|
| `dna` | SHA256 отпечаток: MachineGuid + profile + module + git + trust. |
| `doctor` | Запускает полную автоматическую проверку рабочей станции (74+ тестов). |
| `genesis` | Обновляет OP-DNA, append Trust Chain, экспорт C:\\Security\\exports\\genesis-certificate.txt |
| `healthcheck` | Синоним команды doctor — полная проверка системы. |
| `instrumenty` | Показывает все установленные программы с объяснением на русском. |
| `scan` | Мини-скан: trust score + self-check ключевых команд за ~2 с. |
| `securitycheck` | Показывает состояние UAC, firewall (брандмауэр), SMB1 и телеметрии. |
| `singularity` | Полный probe + Operator DNA + Trust Chain + Genesis Certificate. Уникальный отпечаток оператора. |
| `sysinfo` | Показывает красивую сводку: ОС, процессор, память, диск (через fastfetch). |
| `sysreport` | Создаёт подробный текстовый отчёт и сохраняет его в C:\Logs\Workstation. |
| `trustchain` | Каждый trustcheck/singularity добавляет блок с hash предыдущего. |
| `trustcheck` | Live-проверка: самопроверки команд, сломанные backend, синхронизация профиля. |
| `windowsstatus` | Privacy, performance, firewall, UAC, backups, pending updates. |
| `workstationstatus` | Открывает HOME BASE (домашнюю панель) в выбранном режиме. |

## Безопасность

_

| Команда | Описание |
|---------|----------|
| `pgp-decrypt` | Расшифровка .gpg локально (нужен приватный ключ + passphrase). |
| `pgp-encrypt` | Шифрует файл для получателя (публичный ключ или ID). |
| `pgp-export` | Экспорт .asc для контактов (не приватный ключ!). |
| `pgp-fingerprint` | Fingerprint для проверки личности out-of-band. |
| `pgp-help` | Основы OpenPGP для Tor-контекста. |
| `pgp-repair` | Экспорт публичного ключа и backup revocation, если ключ есть, но setup не завершился. |
| `pgp-setup` | Guided Ed25519 ключ (псевдоним, passphrase). |
| `pgp-status` | Список secret keys + fingerprint из метаданных. |
| `privacy` | То же, что sec — меню Tor + PGP. |
| `sec` | Меню: статус, порядок сессии, все действия через fzf. |
| `sec-help` | Команды, порядок сессии, правила «никогда». |
| `tor-check` | Tor Browser, PGP, user.js hardening, политика Defender. |
| `tor-harden` | user.js hardening + правила сессии. |
| `tor-help` | Краткая шпаргалка Tor-команд. |
| `tor-setup` | Официальный Tor Browser через winget. |
| `tor-status` | Tor Browser, hardening, user.js. |

## Сеть

_

| Команда | Описание |
|---------|----------|
| `nettools` | Справочник по сетевым инструментам и их проверка. |
| `networkstatus` | Показывает адаптеры, IP-адреса, DNS и firewall (брандмауэр). |
| `portscan` | Проверяет, открыты ли указанные порты на удалённом компьютере. |
| `sysaudit` | Проверяет структуру папок и порядок на рабочей станции. |
| `toolbox` | Показывает все группы команд и проверяет инструменты. |
| `toolcheck` | Проверяет, какие программы установлены и какие отсутствуют. |

## Разработка

_

| Команда | Описание |
|---------|----------|
| `devinfo` | Показывает версии pwsh, git, python, node и настройки git. |
| `devstart` | Переходит в папку проектов и открывает домашнюю панель. |
| `new-project` | Создаёт папку проекта с git init и .gitignore. |
| `projects` | Быстрый переход в папку со всеми проектами. |
| `workspace` | Показывает, где вы находитесь, статус git и наличие .venv. |

## Обслуживание

_

| Команда | Описание |
|---------|----------|
| `backupconfig` | Сохраняет профиль PowerShell и конфиги в C:\Backups\Workstation. |
| `cleanup` | Удаляет старые логи, лишние бэкапы и временные файлы. |
| `logs` | Показывает последние файлы в C:\Logs\Workstation. |
| `organize` | Создаёт стандартные папки, README, архивирует installers из Downloads (с бэкапом). |
| `poriadok` | То же, что revise — «навести порядок». |
| `revise` | Полный прогон: PATH, docs sync, doctor, trust, sec, next actions. |
| `updateall` | Обновляет пакеты через winget и модули PowerShell. |

## Восстановление

_

| Команда | Описание |
|---------|----------|
| `fixprofile` | То же, что repairterminal — починка профиля и терминала. |
| `reloadprofile` | Перечитывает $PROFILE без перезапуска терминала. |
| `repairterminal` | Восстанавливает шрифты, Oh My Posh, Windows Terminal и fastfetch. |
| `restoreconfig` | Откатывает настройки из папки C:\Backups\Workstation (нужен admin). |

## Обучение

_

| Команда | Описание |
|---------|----------|
| `cheatsheet` | Открывает файл CHEATSHEET.md с кратким справочником. |
| `dashboard` | Расширенный обзор HOME BASE. |
| `go` | [следующий] из home + категории (папки, порядок, система…) + все команды. Enter=выполнить. |
| `hack` | То же, что menu — запуск частых действий через fzf. |
| `help` | То же, что helpme — справочник по командам оболочки. |
| `helpme` | Интерактивная справка по группам: git, python, nav, tools. |
| `home` | Компактная панель: trust, telemetry, подсказки. По умолчанию minimal. |
| `jarvis` | Расширенный обзор HOME BASE (режим full). |
| `komandy` | Показывает все команды, сгруппированные по категориям. |
| `learn` | Квесты 1–6 и темы: git, python, security, HOME BASE. |
| `menu` | То же, что go. |
| `nav` | nav -Start sec — только безопасность. |
| `palette` | То же, что go. |
| `quickstart` | 5 шагов для нового пользователя системы. |

## Навигация

_

| Команда | Описание |
|---------|----------|
| `backups` | C:\Backups\Workstation — снимки backupconfig и organize. |
| `configs` | C:\Configs\Workstation — экспортированные настройки. |
| `desktop` | Переход на рабочий стол пользователя. |
| `downloads` | Переход в Downloads; -Archive — C:\Downloads\Archive\Installers. |
| `networking` | C:\Networking — captures, docs, scripts. |
| `scripts` | Переход в папку со скриптами рабочей станции. |
| `tools` | Переход в папку с установленными утилитами. |

