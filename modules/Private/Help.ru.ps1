# Каталог справки HOME BASE — все команды и инструменты на русском

function Get-WorkstationHelpCatalog {
    $h = @{
        Logs       = (Get-HomeBasePath -Name Logs)
        Projects   = (Get-HomeBasePath -Name Projects)
        Tools      = (Get-HomeBasePath -Name Tools)
        Scripts    = (Get-HomeBasePath -Name Scripts)
        Backups    = (Get-HomeBasePath -Name Backups)
        Security   = (Get-HomeBasePath -Name Security)
    }
    $h.GenesisExport = Join-Path $h.Security 'exports\genesis-certificate.txt'
    $h.PgpDir = Join-Path $h.Security 'pgp'

    $groups = @{
        'Система' = 'Проверка здоровья, отчёты и информация о компьютере'
        'Сеть' = 'Диагностика сети, инструменты и сканирование'
        'Разработка' = 'Проекты, рабочая область и среда разработки'
        'Обслуживание' = 'Очистка, резервные копии и обновления'
        'Восстановление' = 'Починка терминала, профиля и откат настроек'
        'Обучение' = 'Справка, шпаргалки и обучающие материалы'
        'Безопасность' = 'Tor, PGP, анонимные сессии — SHADOW OPS'
        'Навигация' = 'Быстрый переход по папкам и оболочка'
    }

    $commands = @{
        doctor = @{
            Group = 'Система'; Title = 'doctor — проверка здоровья системы'
            Description = 'Запускает полную автоматическую проверку рабочей станции (68+ тестов).'
            Does = 'Проверяет профиль, шрифты, терминал, инструменты, команды и безопасность.'
            When = 'Когда что-то работает не так, после обновлений или раз в неделю.'
            How = 'doctor'
            Examples = @('doctor', 'doctor -help')
            Related = @('trustcheck', 'healthcheck', 'repairterminal')
        }
        trustcheck = @{
            Group = 'Система'; Title = 'trustcheck — режим доверия (live)'
            Description = 'Live-проверка: самопроверки команд, сломанные backend, синхронизация профиля.'
            Does = 'HOME BASE не может врать — эта команда подтверждает правду системы.'
            When = 'При старте, после repairterminal, или если панель показывает проблемы.'
            How = 'trustcheck'
            Examples = @('trustcheck', 'trustcheck -help')
            Related = @('scan', 'doctor', 'home', 'hack')
        }
        scan = @{
            Group = 'Система'; Title = 'scan — быстрый integrity probe'
            Description = 'Мини-скан: trust score + self-check ключевых команд за ~2 с.'
            Does = 'Invoke-QuickScan — без полного doctor.'
            When = 'Быстрая проверка после изменений или перед deploy.'
            How = 'scan'
            Examples = @('scan', 'scan -Quiet', 'scan -help')
            Related = @('trustcheck', 'doctor', 'home')
        }
        windowsstatus = @{
            Group = 'Система'; Title = 'windowsstatus — состояние Windows'
            Description = 'Privacy, performance, firewall, UAC, backups, pending updates.'
            Does = 'Get-WindowsStatusReport — score + warnings.'
            When = 'После tune pass или раз в неделю.'
            How = 'windowsstatus'
            Examples = @('windowsstatus', 'windowsstatus -Quiet', 'windowsstatus -help')
            Related = @('securitycheck', 'doctor', 'singularity')
        }
        singularity = @{
            Group = 'Система'; Title = 'singularity — UNIQUE MODE (только эта машина)'
            Description = 'Полный probe + Operator DNA + Trust Chain + Genesis Certificate. Уникальный отпечаток оператора.'
            Does = 'Show-SingularityCockpit — криптографический seal привязан к MachineGuid, profile, git, trust.'
            When = 'Когда нужен максимум: доказать целостность и получить Planet ID.'
            How = 'singularity'
            Examples = @('singularity', 'singularity -help')
            Related = @('genesis', 'dna', 'trustchain', 'trustcheck')
        }
        genesis = @{
            Group = 'Система'; Title = 'genesis — Genesis Certificate'
            Description = "Обновляет OP-DNA, append Trust Chain, экспорт $($h.GenesisExport)"
            Does = 'Export-GenesisCertificate — ASCII seal unique to this workstation.'
            When = 'После изменений profile/module/git или раз в месяц.'
            How = 'genesis'
            Examples = @('genesis', 'genesis -help')
            Related = @('singularity', 'dna', 'trustchain')
        }
        dna = @{
            Group = 'Система'; Title = 'dna — Operator DNA / Callsign'
            Description = 'SHA256 отпечаток: MachineGuid + profile + module + git + trust.'
            Does = 'Get-OperatorDna — Callsign (KG-XXXXXX) и Planet ID.'
            When = 'Узнать уникальный код оператора для этой машины.'
            How = 'dna · dna -Refresh'
            Examples = @('dna', 'dna -Refresh', 'dna -help')
            Related = @('singularity', 'genesis')
        }
        trustchain = @{
            Group = 'Система'; Title = 'trustchain — append-only цепочка доверия'
            Description = 'Каждый trustcheck/singularity добавляет блок с hash предыдущего.'
            Does = 'Test-TrustChainIntegrity + Show-TrustChain — blockchain-lite audit trail.'
            When = 'Проверить историю live-проб и целостность chain.'
            How = 'trustchain'
            Examples = @('trustchain', 'trustchain -help')
            Related = @('trustcheck', 'singularity', 'genesis')
        }
        palette = @{
            Group = 'Обучение'; Title = 'palette — fzf палитра команд'
            Description = 'Интерактивный поиск по всем командам HOME BASE.'
            Does = 'Invoke-CommandPalette — fzf → справка и подсказка запуска.'
            When = 'Не помните команду; быстрее komandy.'
            How = 'palette · Ctrl+Alt+H'
            Examples = @('palette', 'palette -help')
            Related = @('menu', 'komandy', 'explain')
        }
        menu = @{
            Group = 'Обучение'; Title = 'menu — hacker menu (fzf)'
            Description = 'Главное меню: cockpit, SHADOW OPS (sec), scan, trust, network.'
            Does = 'Show-HackerMenu; без fzf → full cockpit.'
            When = 'hack или guided выбор действия.'
            How = 'menu · hack · sec'
            Examples = @('menu', 'sec', 'hack', 'menu -help')
            Related = @('sec', 'hack', 'palette', 'home')
        }
        healthcheck = @{
            Group = 'Система'; Title = 'healthcheck — то же, что doctor'
            Description = 'Синоним команды doctor — полная проверка системы.'
            Does = 'Запускает Validate-Workstation.ps1 и показывает результат.'
            When = 'Когда привычнее название healthcheck.'
            How = 'healthcheck'
            Examples = @('healthcheck')
            Related = @('doctor', 'trustcheck', 'sysreport')
        }
        workstationstatus = @{
            Group = 'Система'; Title = 'workstationstatus — панель состояния'
            Description = 'Открывает HOME BASE (домашнюю панель) в выбранном режиме.'
            Does = 'Показывает состояние системы, режим доверия, рекомендации.'
            When = 'Когда нужен обзор без перезапуска терминала.'
            How = 'workstationstatus -Mode minimal|normal|full'
            Examples = @('workstationstatus', 'workstationstatus -Mode minimal')
            Related = @('home', 'trustcheck', 'doctor')
        }
        sysreport = @{
            Group = 'Система'; Title = 'sysreport — полный отчёт о системе'
            Description = "Создаёт подробный текстовый отчёт и сохраняет его в $($h.Logs)."
            Does = 'Собирает информацию о системе и результаты валидации в один файл.'
            When = 'Перед резервным копированием, при диагностике или для архива.'
            How = 'sysreport'
            Examples = @('sysreport')
            Related = @('doctor', 'logs')
        }
        sysinfo = @{
            Group = 'Система'; Title = 'sysinfo — краткая сводка о компьютере'
            Description = 'Показывает красивую сводку: ОС, процессор, память, диск (через fastfetch).'
            Does = 'Выводит основные характеристики системы в терминал.'
            When = 'Чтобы быстро узнать, что за машина перед вами.'
            How = 'sysinfo'
            Examples = @('sysinfo')
            Related = @('devinfo', 'doctor')
        }
        securitycheck = @{
            Group = 'Система'; Title = 'securitycheck — проверка безопасности'
            Description = 'Показывает состояние UAC, firewall (брандмауэр), SMB1 и телеметрии.'
            Does = 'Выводит обзор настроек безопасности без изменения системы.'
            When = 'После изменения настроек или для ежемесячного аудита.'
            How = 'securitycheck'
            Examples = @('securitycheck')
            Related = @('doctor', 'networkstatus')
        }
        nettools = @{
            Group = 'Сеть'; Title = 'nettools — сетевая панель'
            Description = 'Справочник по сетевым инструментам и их проверка.'
            Does = 'Показывает список сетевых утилит и запускает toolcheck.'
            When = 'При работе с сетью, Wi-Fi, портами или диагностике подключения.'
            How = 'nettools'
            Examples = @('nettools', 'nettools -help')
            Related = @('toolcheck', 'networkstatus', 'toolbox')
        }
        toolcheck = @{
            Group = 'Сеть'; Title = 'toolcheck — проверка установленных инструментов'
            Description = 'Проверяет, какие программы установлены и какие отсутствуют.'
            Does = 'Сканирует nmap, Wireshark, git, gh и другие утилиты.'
            When = 'После установки программ или если команда «не найдена».'
            How = 'toolcheck'
            Examples = @('toolcheck')
            Related = @('nettools', 'doctor')
        }
        toolbox = @{
            Group = 'Сеть'; Title = 'toolbox — обзор всех категорий команд'
            Description = 'Показывает все группы команд и проверяет инструменты.'
            Does = 'Сводная «карта» командного центра по категориям.'
            When = 'Когда не помните, какая команда за что отвечает.'
            How = 'toolbox'
            Examples = @('toolbox')
            Related = @('helpme', 'quickstart', 'home')
        }
        networkstatus = @{
            Group = 'Сеть'; Title = 'networkstatus — состояние сети'
            Description = 'Показывает адаптеры, IP-адреса, DNS и firewall (брандмауэр).'
            Does = 'Выводит локальный и публичный IP, настройки сетевых интерфейсов.'
            When = 'Нет интернета, медленная сеть или проверка IP.'
            How = 'networkstatus'
            Examples = @('networkstatus')
            Related = @('nettools', 'portscan')
        }
        sysaudit = @{
            Group = 'Сеть'; Title = 'sysaudit — аудит организации файлов'
            Description = 'Проверяет структуру папок и порядок на рабочей станции.'
            Does = 'Запускает Invoke-OrganizationAudit.ps1 и сохраняет отчёт.'
            When = 'Раз в месяц или после переноса файлов.'
            How = 'sysaudit'
            Examples = @('sysaudit')
            Related = @('doctor', 'cleanup')
        }
        portscan = @{
            Group = 'Сеть'; Title = 'portscan — проверка портов хоста'
            Description = 'Проверяет, открыты ли указанные порты на удалённом компьютере.'
            Does = 'Тестирует порты 22, 80, 443 и другие через Test-NetConnection.'
            When = 'Нужно узнать, доступен ли сервис на хосте.'
            How = 'portscan -HostName 192.168.1.1'
            Examples = @('portscan 192.168.1.1', 'portscan -HostName google.com -Ports 80,443')
            Related = @('networkstatus', 'nettools')
        }
        devstart = @{
            Group = 'Разработка'; Title = 'devstart — начало рабочего дня'
            Description = 'Переходит в папку проектов и открывает домашнюю панель.'
            Does = "Set-Location $($h.Projects) + показ HOME BASE."
            When = 'Каждый раз, когда начинаете писать код.'
            How = 'devstart'
            Examples = @('devstart')
            Related = @('projects', 'new-project', 'workspace')
        }
        workspace = @{
            Group = 'Разработка'; Title = 'workspace — текущая рабочая папка'
            Description = 'Показывает, где вы находитесь, статус git и наличие .venv.'
            Does = 'Выводит путь, ветку git и состояние Python-окружения.'
            When = 'Чтобы понять контекст текущей папки.'
            How = 'workspace'
            Examples = @('workspace')
            Related = @('whereami', 'devstart', 'projects')
        }
        projects = @{
            Group = 'Разработка'; Title = "projects — перейти в $($h.Projects)"
            Description = 'Быстрый переход в папку со всеми проектами.'
            Does = "Set-Location $($h.Projects)"
            When = 'Нужно открыть или создать проект.'
            How = 'projects'
            Examples = @('projects')
            Related = @('devstart', 'new-project', 'tools')
        }
        'new-project' = @{
            Group = 'Разработка'; Title = 'new-project — создать новый проект'
            Description = 'Создаёт папку проекта с git init и .gitignore.'
            Does = "Новая папка в $($h.Projects), инициализация git, опционально Python venv."
            When = 'Начинаете новый проект с нуля.'
            How = 'new-project ИмяПроекта -Type python|empty'
            Examples = @('new-project MyApp', 'new-project Bot -Type python')
            Related = @('devstart', 'Enter-Venv', 'projects')
        }
        devinfo = @{
            Group = 'Разработка'; Title = 'devinfo — информация о среде разработки'
            Description = 'Показывает версии pwsh, git, python, node и настройки git.'
            Does = 'Сводка инструментов разработчика на этой машине.'
            When = 'Проверить, что всё установлено перед работой.'
            How = 'devinfo'
            Examples = @('devinfo')
            Related = @('sysinfo', 'toolcheck')
        }
        cleanup = @{
            Group = 'Обслуживание'; Title = 'cleanup — безопасная очистка'
            Description = 'Удаляет старые логи, лишние бэкапы и временные файлы.'
            Does = 'Ротация validation-*.json, обрезка workstation.log, очистка temp.'
            When = 'Мало места на диске или раз в 2–4 недели.'
            How = 'cleanup или cleanup -WhatIf (только просмотр)'
            Examples = @('cleanup', 'cleanup -WhatIf')
            Related = @('backupconfig', 'logs', 'doctor')
        }
        backupconfig = @{
            Group = 'Обслуживание'; Title = 'backupconfig — резервная копия настроек'
            Description = "Сохраняет профиль PowerShell и конфиги в $($h.Backups)."
            Does = 'Создаёт снимок настроек терминала и профиля.'
            When = 'Перед изменением профиля или раз в неделю.'
            How = 'backupconfig'
            Examples = @('backupconfig')
            Related = @('restoreconfig', 'fixprofile')
        }
        updateall = @{
            Group = 'Обслуживание'; Title = 'updateall — обновить все программы'
            Description = 'Обновляет пакеты через winget и модули PowerShell.'
            Does = 'winget upgrade --all + Update-Module PSReadLine, posh-git и др.'
            When = 'Раз в 1–2 недели для актуальных версий.'
            How = 'updateall'
            Examples = @('updateall')
            Related = @('doctor', 'toolcheck')
        }
        logs = @{
            Group = 'Обслуживание'; Title = 'logs — просмотр журналов'
            Description = "Показывает последние файлы в $($h.Logs)."
            Does = 'Список логов с датой и размером; -Open открывает папку.'
            When = 'Нужно найти отчёт валидации или ошибку.'
            How = 'logs или logs -Open'
            Examples = @('logs', 'logs -Open')
            Related = @('sysreport', 'doctor')
        }
        repairterminal = @{
            Group = 'Восстановление'; Title = 'repairterminal — починка терминала'
            Description = 'Восстанавливает шрифты, Oh My Posh, Windows Terminal и fastfetch.'
            Does = 'Запускает Invoke-TerminalRecovery.ps1 — полный цикл восстановления.'
            When = 'Сломались иконки, промпт, шрифт или профиль.'
            How = 'repairterminal'
            Examples = @('repairterminal')
            Related = @('fixprofile', 'doctor', 'reloadprofile')
        }
        fixprofile = @{
            Group = 'Восстановление'; Title = 'fixprofile — синоним repairterminal'
            Description = 'То же, что repairterminal — починка профиля и терминала.'
            Does = 'Восстановление отображения и настроек оболочки.'
            When = 'Профиль не загружается или выглядит неправильно.'
            How = 'fixprofile'
            Examples = @('fixprofile')
            Related = @('repairterminal', 'reloadprofile')
        }
        restoreconfig = @{
            Group = 'Восстановление'; Title = 'restoreconfig — восстановить из бэкапа'
            Description = "Откатывает настройки из папки $($h.Backups) (нужен admin)."
            Does = 'Запускает Rollback-Workstation.ps1 с правами администратора.'
            When = 'После ошибочных изменений, когда backupconfig уже делали.'
            How = 'restoreconfig или restoreconfig -BackupFolder имя_папки'
            Examples = @('restoreconfig')
            Related = @('backupconfig', 'repairterminal')
        }
        reloadprofile = @{
            Group = 'Восстановление'; Title = 'reloadprofile — перезагрузить профиль'
            Description = 'Перечитывает $PROFILE без перезапуска терминала.'
            Does = 'Точечное применение . $PROFILE'
            When = 'После правки profile вручную.'
            How = 'reloadprofile'
            Examples = @('reloadprofile')
            Related = @('fixprofile', 'doctor')
        }
        learn = @{
            Group = 'Обучение'; Title = 'learn — обучающие материалы'
            Description = 'Квесты 1–6 и темы: git, python, security, HOME BASE.'
            Does = 'Guided квесты или текстовые подсказки по теме.'
            When = 'Изучаете систему или Tor/PGP.'
            How = 'learn -Quest 1|2|3|4|5|6 · learn -Topic security'
            Examples = @('learn -Quest 6', 'learn -Topic security', 'learn -Topic git')
            Related = @('sec', 'helpme', 'cheatsheet')
        }
        cheatsheet = @{
            Group = 'Обучение'; Title = 'cheatsheet — шпаргалка команд'
            Description = 'Открывает файл CHEATSHEET.md с кратким справочником.'
            Does = 'Показывает markdown-шпаргалку через bat или Get-Content.'
            When = 'Нужен быстрый список команд под рукой.'
            How = 'cheatsheet'
            Examples = @('cheatsheet')
            Related = @('helpme', 'learn')
        }
        quickstart = @{
            Group = 'Обучение'; Title = 'quickstart — быстрый старт'
            Description = '5 шагов для нового пользователя системы.'
            Does = 'Показывает devstart → new-project → helpme → doctor → repairterminal.'
            When = 'Первый запуск или после долгого перерыва.'
            How = 'quickstart'
            Examples = @('quickstart')
            Related = @('helpme', 'home', 'devstart')
        }
        helpme = @{
            Group = 'Обучение'; Title = 'helpme — справка по командам'
            Description = 'Интерактивная справка по группам: git, python, nav, tools.'
            Does = 'Выводит список команд по категориям.'
            When = 'Не помните команду или хотите обзор возможностей.'
            How = 'helpme или helpme -Topic git'
            Examples = @('helpme', 'help -Topic nav')
            Related = @('quickstart', 'cheatsheet', 'home')
        }
        help = @{
            Group = 'Обучение'; Title = 'help — справка (синоним helpme)'
            Description = 'То же, что helpme — справочник по командам оболочки.'
            Does = 'Текстовая справка по темам.'
            When = 'Нужен список команд по теме.'
            How = 'help -Topic all|git|python|nav|tools|maintenance'
            Examples = @('help', 'help -Topic git')
            Related = @('helpme', 'cheatsheet')
        }
        home = @{
            Group = 'Обучение'; Title = 'home — домашняя панель (normal mode)'
            Description = 'Открывает HOME BASE в режиме normal — trust + telemetry + command matrix.'
            Does = 'Show-HomeBase — hacker cockpit с live trust.'
            When = 'Быстрый обзор без полного скана инструментов.'
            How = 'home'
            Examples = @('home', 'home -help')
            Related = @('hack', 'trustcheck', 'jarvis')
        }
        hack = @{
            Group = 'Обучение'; Title = 'hack — MAX MODE cockpit'
            Description = 'Полный хакерский cockpit или fzf-меню (если установлен fzf).'
            Does = 'Show-HackerMenu или Show-HomeBase -Mode full.'
            When = 'Когда нужен полный контроль и обзор системы.'
            How = 'hack · menu'
            Examples = @('hack', 'menu', 'hack -help')
            Related = @('home', 'scan', 'palette', 'trustcheck', 'instrumenty', 'komandy')
        }
        jarvis = @{ Group = 'Обучение'; Title = 'jarvis — синоним hack (full)'
            Description = 'Открывает HOME BASE — центр управления рабочей станцией.'
            Does = 'Полная домашняя панель на русском языке.'
            When = 'Нужен полный обзор системы.'
            How = 'jarvis'; Examples = @('jarvis'); Related = @('home', 'dashboard')
        }
        dashboard = @{
            Group = 'Обучение'; Title = 'dashboard — синоним home'
            Description = 'То же, что home и jarvis.'
            Does = 'Show-HomeBase в полном режиме.'
            When = 'Привычное название «дашборд».'
            How = 'dashboard'; Examples = @('dashboard'); Related = @('home', 'jarvis')
        }
        tools = @{
            Group = 'Навигация'; Title = "tools — перейти в $($h.Tools)"
            Description = 'Переход в папку с установленными утилитами.'
            Does = "Set-Location $($h.Tools)"
            When = 'Ищете исполняемый файл утилиты.'
            How = 'tools'; Examples = @('tools'); Related = @('scripts', 'projects')
        }
        scripts = @{
            Group = 'Навигация'; Title = "scripts — перейти в $($h.Scripts)"
            Description = 'Переход в папку со скриптами рабочей станции.'
            Does = "Set-Location $($h.Scripts)"
            When = 'Нужно найти или запустить скрипт.'
            How = 'scripts'; Examples = @('scripts'); Related = @('tools', 'doctor')
        }
        instrumenty = @{
            Group = 'Система'; Title = 'instrumenty — панель инструментов системы'
            Description = 'Показывает все установленные программы с объяснением на русском.'
            Does = 'Show-SystemToolsPanel — название, назначение, путь, статус.'
            When = 'Хотите понять, что установлено и зачем.'
            How = 'instrumenty'
            Examples = @('instrumenty')
            Related = @('toolcheck', 'nettools', 'devinfo')
        }
        komandy = @{
            Group = 'Обучение'; Title = 'komandy — все команды по группам'
            Description = 'Показывает все команды, сгруппированные по категориям.'
            Does = 'Show-CommandGroupsRu — полный каталог с примерами.'
            When = 'Ищете команду, не зная точного названия.'
            How = 'komandy'
            Examples = @('komandy')
            Related = @('helpme', 'toolbox', 'home')
        }
        'pgp-repair' = @{
            Group = 'Безопасность'; Title = 'pgp-repair — завершить настройку PGP'
            Description = 'Экспорт публичного ключа и backup revocation, если ключ есть, но setup не завершился.'
            Does = "Repair-PgpIdentity.ps1 → $($h.PgpDir)\"
            When = 'После ошибки Key creation failed при уже созданном ключе.'
            How = 'pgp-repair'
            Examples = @('pgp-repair')
            Related = @('pgp-status', 'pgp-export', 'sec')
        }
        'pgp-setup' = @{
            Group = 'Безопасность'; Title = 'pgp-setup — создать OpenPGP ключ'
            Description = 'Guided Ed25519 ключ (псевдоним, passphrase).'
            Does = 'Configure-PgpIdentity.ps1'
            When = 'Первый ключ для шифрования переписки.'
            How = 'pgp-setup'
            Examples = @('pgp-setup')
            Related = @('pgp-repair', 'pgp-fingerprint', 'sec')
        }
        'pgp-status' = @{
            Group = 'Безопасность'; Title = 'pgp-status — ключи OpenPGP'
            Description = 'Список secret keys + fingerprint из метаданных.'
            Does = 'gpg --list-secret-keys'
            When = 'Проверить что ключ на месте.'
            How = 'pgp-status'
            Examples = @('pgp-status')
            Related = @('pgp-fingerprint', 'sec')
        }
        'pgp-export' = @{
            Group = 'Безопасность'; Title = 'pgp-export — публичный ключ'
            Description = 'Экспорт .asc для контактов (не приватный ключ!).'
            Does = "gpg --armor --export → $($h.PgpDir)\"
            When = 'Дать контакту ключ для шифрования.'
            How = 'pgp-export'
            Examples = @('pgp-export')
            Related = @('pgp-fingerprint', 'pgp-encrypt')
        }
        'pgp-fingerprint' = @{
            Group = 'Безопасность'; Title = 'pgp-fingerprint — отпечаток ключа'
            Description = 'Fingerprint для проверки личности out-of-band.'
            Does = 'Показывает fingerprint из pgp-identity.json или gpg.'
            When = 'Сверка с контактом другим каналом.'
            How = 'pgp-fingerprint'
            Examples = @('pgp-fingerprint')
            Related = @('pgp-export', 'sec')
        }
        'pgp-encrypt' = @{
            Group = 'Безопасность'; Title = 'pgp-encrypt — зашифровать файл'
            Description = 'Шифрует файл для получателя (публичный ключ или ID).'
            Does = 'gpg --encrypt --armor → file.gpg'
            When = 'Отправка файла через Tor-чат.'
            How = 'pgp-encrypt -To KEY -File path'
            Examples = @('pgp-encrypt -To A12238F6 -File secret.txt')
            Related = @('pgp-decrypt', 'pgp-export')
        }
        'pgp-decrypt' = @{
            Group = 'Безопасность'; Title = 'pgp-decrypt — расшифровать файл'
            Description = 'Расшифровка .gpg локально (нужен приватный ключ + passphrase).'
            Does = 'gpg --decrypt'
            When = 'Получил зашифрованный файл.'
            How = 'pgp-decrypt -File secret.txt.gpg'
            Examples = @('pgp-decrypt -File secret.txt.gpg')
            Related = @('pgp-encrypt', 'pgp-status')
        }
        'pgp-help' = @{
            Group = 'Безопасность'; Title = 'pgp-help — шпаргалка PGP'
            Description = 'Основы OpenPGP для Tor-контекста.'
            Does = 'Show-PgpHelpRu'
            When = 'Нужна справка по шифрованию.'
            How = 'pgp-help · sec-help'
            Examples = @('pgp-help')
            Related = @('sec-help', 'pgp-fingerprint')
        }
        'tor-setup' = @{
            Group = 'Безопасность'; Title = 'tor-setup — установить Tor Browser'
            Description = 'Официальный Tor Browser через winget.'
            Does = 'Install-TorBrowser.ps1'
            When = 'Перед работой с .onion / darknet.'
            How = 'tor-setup'
            Examples = @('tor-setup')
            Related = @('tor-harden', 'tor-check', 'sec')
        }
        'tor-status' = @{
            Group = 'Безопасность'; Title = 'tor-status — состояние Tor'
            Description = 'Tor Browser, hardening, kill switch.'
            Does = 'Get-TorSecurityState + Find-TorBrowserExe'
            When = 'Проверить готовность к сессии.'
            How = 'tor-status'
            Examples = @('tor-status')
            Related = @('tor-check', 'sec')
        }
        'tor-harden' = @{
            Group = 'Безопасность'; Title = 'tor-harden — максимальная защита сессии'
            Description = 'user.js hardening + правила сессии. Опция -Lock включает kill switch.'
            Does = 'Configure-TorSecurity.ps1'
            When = 'Перед Tor-сессией.'
            How = 'tor-harden · tor-harden -Lock'
            Examples = @('tor-harden', 'tor-harden -Lock')
            Related = @('tor-lock', 'tor-check', 'pgp-help')
        }
        'tor-check' = @{
            Group = 'Безопасность'; Title = 'tor-check — чеклист перед сессией'
            Description = 'Tor Browser, PGP, kill switch, политика Defender.'
            Does = 'Invoke-TorPreflightCheck'
            When = 'Перед каждым заходом в Tor.'
            How = 'tor-check'
            Examples = @('tor-check')
            Related = @('tor-lock', 'tor-status')
        }
        'tor-lock' = @{
            Group = 'Безопасность'; Title = 'tor-lock — kill switch (admin)'
            Description = 'Firewall: блок outbound Chrome/Edge/Firefox/Brave. Tor Browser разрешён.'
            Does = 'Configure-TorSecurity.ps1 -LockSwitch'
            When = 'Начало Tor-сессии (закрой clearnet-браузеры).'
            How = 'tor-lock (от администратора)'
            Examples = @('tor-lock')
            Related = @('tor-unlock', 'tor-harden')
        }
        'tor-unlock' = @{
            Group = 'Безопасность'; Title = 'tor-unlock — снять kill switch (admin)'
            Description = 'Удаляет правила KGreen-Tor-Lock.'
            Does = 'Configure-TorSecurity.ps1 -UnlockSwitch'
            When = 'После Tor-сессии.'
            How = 'tor-unlock (от администратора)'
            Examples = @('tor-unlock')
            Related = @('tor-lock', 'tor-status')
        }
        'tor-help' = @{
            Group = 'Безопасность'; Title = 'tor-help — справка Tor'
            Description = 'Краткая шпаргалка Tor-команд.'
            Does = 'Show-TorHelpRu'
            When = 'Нужна справка по Tor.'
            How = 'tor-help · sec-help'
            Examples = @('tor-help')
            Related = @('sec-help', 'tor-check')
        }
        sec = @{
            Group = 'Безопасность'; Title = 'sec — SHADOW OPS (главное меню)'
            Description = 'Единое меню Tor + PGP: статус, playbook, все действия через fzf.'
            Does = 'Show-SecurityMenu — панель readiness + интерактивное меню.'
            When = 'Перед Tor-сессией или настройка PGP.'
            How = 'sec · sec -Guide · sec -Status'
            Examples = @('sec', 'sec -Guide', 'sec -Status', 'privacy')
            Related = @('tor-check', 'sec-help', 'menu')
        }
        'sec-help' = @{
            Group = 'Безопасность'; Title = 'sec-help — полная шпаргалка'
            Description = 'Tor + PGP + playbook + правила NEVER.'
            Does = 'Show-SecurityHelpRu'
            When = 'Нужны инструкции без fzf-меню.'
            How = 'sec-help'
            Examples = @('sec-help')
            Related = @('sec', 'pgp-help', 'tor-help')
        }
        privacy = @{
            Group = 'Безопасность'; Title = 'privacy — синоним sec'
            Description = 'То же, что sec — меню SHADOW OPS.'
            Does = 'sec'
            When = 'Привычнее название privacy.'
            How = 'privacy · privacy -Status'
            Examples = @('privacy', 'privacy -Status')
            Related = @('sec', 'sec-help')
        }
        revise = @{
            Group = 'Обслуживание'; Title = 'revise — навести порядок'
            Description = 'Полный прогон: PATH, docs sync, doctor, trust, SHADOW OPS, next actions.'
            Does = 'Invoke-WorkstationRevision.ps1'
            When = 'Раз в неделю или после больших изменений.'
            How = 'revise · revise -Backup · poriadok'
            Examples = @('revise', 'revise -Quick', 'revise -Backup', 'poriadok')
            Related = @('doctor', 'trustcheck', 'sec', 'backupconfig')
        }
        poriadok = @{
            Group = 'Обслуживание'; Title = 'poriadok — синоним revise (RU)'
            Description = 'То же, что revise — «навести порядок».'
            Does = 'revise'
            When = 'Русское название команды.'
            How = 'poriadok · poriadok -Backup'
            Examples = @('poriadok')
            Related = @('revise', 'doctor', 'trustcheck')
        }
    }

    return @{ Groups = $groups; Commands = $commands }
}

function Get-WorkstationToolCatalogRu {
    return @(
        @{ Name = 'Nmap'; Cmd = 'nmap'; What = 'сканер сети — находит устройства и открытые порты'
           Why = 'проверка устройств в локальной сети и диагностика'; Example = 'nmap -sn 192.168.1.0/24' }
        @{ Name = 'Wireshark'; Cmd = 'wireshark'; What = 'анализатор сетевых пакетов (трафика)'
           Why = 'глубокая диагностика сетевых проблем'; Example = 'wireshark' }
        @{ Name = 'TShark'; Cmd = 'tshark'; What = 'консольная версия Wireshark'
           Why = 'захват трафика из терминала'; Example = 'tshark -i 1 -a duration:10' }
        @{ Name = 'OpenSSH'; Cmd = 'ssh'; What = 'клиент для удалённого подключения по SSH'
           Why = 'подключение к серверам и Linux-машинам'; Example = 'ssh user@host' }
        @{ Name = 'OpenSSL'; Cmd = 'openssl'; What = 'криптографические утилиты и проверка TLS'
           Why = 'проверка сертификатов и шифрования'; Example = 'openssl s_client -connect host:443' }
        @{ Name = 'GnuPG'; Cmd = 'gpg'; What = 'OpenPGP — шифрование и подпись сообщений'
           Why = 'PGP для Tor-переписки'; Example = 'pgp-status · pgp-fingerprint' }
        @{ Name = 'Tor Browser'; Cmd = 'firefox'; What = 'анонимный браузер через сеть Tor'
           Why = 'единственный браузер для .onion'; Example = 'sec · tor-check' }
        @{ Name = 'PuTTY'; Cmd = 'putty'; What = 'графический SSH/Telnet клиент'
           Why = 'удобное подключение к серверам через GUI'; Example = 'putty' }
        @{ Name = 'Process Explorer'; Cmd = 'procexp64'; What = 'продвинутый диспетчер процессов'
           Why = 'найти, какая программа нагружает систему'; Example = 'procexp' }
        @{ Name = 'Process Monitor'; Cmd = 'procmon64'; What = 'монитор файлов, реестра и процессов'
           Why = 'отладка — что программа читает/пишет'; Example = 'procmon' }
        @{ Name = 'TCPView'; Cmd = 'tcpview64'; What = 'живой список TCP/UDP соединений'
           Why = 'кто использует сеть прямо сейчас'; Example = 'tcpview' }
        @{ Name = 'Everything'; Cmd = 'everything'; What = 'мгновенный поиск файлов по имени'
           Why = 'найти любой файл за секунды'; Example = 'everything' }
        @{ Name = 'Git'; Cmd = 'git'; What = 'система контроля версий (сохранение истории кода)'
           Why = 'отслеживание изменений в проектах'; Example = 'git status' }
        @{ Name = 'GitHub CLI'; Cmd = 'gh'; What = 'командная строка GitHub'
           Why = 'работа с репозиториями и PR из терминала'; Example = 'gh auth status' }
        @{ Name = 'PowerShell'; Cmd = 'pwsh'; What = 'современная оболочка командной строки Windows'
           Why = 'автоматизация и все команды HOME BASE'; Example = 'pwsh --version' }
        @{ Name = 'fzf'; Cmd = 'fzf'; What = 'нечёткий поиск (fuzzy finder)'
           Why = 'Ctrl+R — поиск по истории команд'; Example = 'fzf --version' }
        @{ Name = 'bat'; Cmd = 'bat'; What = 'cat с подсветкой синтаксиса'
           Why = 'красивый просмотр файлов в терминале'; Example = 'bat file.py' }
        @{ Name = 'eza'; Cmd = 'eza'; What = 'современная замена ls/dir с иконками'
           Why = 'удобный список файлов (ll, ls)'; Example = 'll' }
        @{ Name = 'fastfetch'; Cmd = 'fastfetch'; What = 'красивая сводка о системе'
           Why = 'sysinfo — быстрый обзор железа'; Example = 'sysinfo' }
        @{ Name = 'ripgrep'; Cmd = 'rg'; What = 'быстрый поиск текста в файлах'
           Why = 'найти строку в коде или логах'; Example = "rg pattern $($h.Projects)" }
    )
}
