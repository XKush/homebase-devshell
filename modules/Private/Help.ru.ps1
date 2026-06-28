# Каталог справки HOME BASE — все команды и инструменты на русском

function Get-WorkstationHelpCatalog {
    $groups = @{
        'Система' = 'Проверка здоровья, отчёты и информация о компьютере'
        'Сеть' = 'Диагностика сети, инструменты и сканирование'
        'Разработка' = 'Проекты, рабочая область и среда разработки'
        'Обслуживание' = 'Очистка, резервные копии и обновления'
        'Восстановление' = 'Починка терминала, профиля и откат настроек'
        'Обучение' = 'Справка, шпаргалки и обучающие материалы'
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
            Related = @('securitycheck', 'doctor', 'updateall')
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
            Description = 'Главное меню: cockpit, scan, trust, network, dev, palette.'
            Does = 'Show-HackerMenu; без fzf → full cockpit.'
            When = 'hack или guided выбор действия.'
            How = 'menu · hack'
            Examples = @('menu', 'hack', 'menu -help')
            Related = @('hack', 'palette', 'home')
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
            Description = 'Создаёт подробный текстовый отчёт и сохраняет его в C:\Logs\Workstation.'
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
            Does = 'Set-Location C:\Projects + показ HOME BASE.'
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
            Group = 'Разработка'; Title = 'projects — перейти в C:\Projects'
            Description = 'Быстрый переход в папку со всеми проектами.'
            Does = 'Set-Location C:\Projects'
            When = 'Нужно открыть или создать проект.'
            How = 'projects'
            Examples = @('projects')
            Related = @('devstart', 'new-project', 'tools')
        }
        'new-project' = @{
            Group = 'Разработка'; Title = 'new-project — создать новый проект'
            Description = 'Создаёт папку проекта с git init и .gitignore.'
            Does = 'Новая папка в C:\Projects, инициализация git, опционально Python venv.'
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
            Description = 'Сохраняет профиль PowerShell и конфиги в C:\Backups\Workstation.'
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
            Description = 'Показывает последние файлы в C:\Logs\Workstation.'
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
            Description = 'Откатывает настройки из папки C:\Backups\Workstation (нужен admin).'
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
            Description = 'Краткие уроки по git, python, PowerShell и VS Code.'
            Does = 'Выводит текстовые подсказки по выбранной теме.'
            When = 'Изучаете новую технологию или забыли синтаксис.'
            How = 'learn -Topic git|python|powershell|vscode|all'
            Examples = @('learn -Topic git', 'learn -Topic python')
            Related = @('helpme', 'cheatsheet', 'quickstart')
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
            Group = 'Навигация'; Title = 'tools — перейти в C:\Tools'
            Description = 'Переход в папку с установленными утилитами.'
            Does = 'Set-Location C:\Tools'
            When = 'Ищете исполняемый файл утилиты.'
            How = 'tools'; Examples = @('tools'); Related = @('scripts', 'projects')
        }
        scripts = @{
            Group = 'Навигация'; Title = 'scripts — перейти в C:\Scripts'
            Description = 'Переход в папку со скриптами рабочей станции.'
            Does = 'Set-Location C:\Scripts'
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
           Why = 'найти строку в коде или логах'; Example = 'rg pattern C:\Projects' }
    )
}
