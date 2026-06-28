# Learning — обучение и справка

function help {
    param(
        [ValidateSet('git','python','nav','tools','maintenance','security','all')][string]$Topic = 'all',
        [switch]$Help
    )
    if ($Help -and $Topic -eq 'all') { Show-WorkstationCommandHelp -Name 'help'; return }

    $sections = @{
        nav = @'
[Навигация]
  projects     Перейти в C:\Projects
  tools        Перейти в C:\Tools
  scripts      Перейти в C:\Scripts
  logs         Перейти в C:\Logs
  z <путь>     Быстрый переход (zoxide)
  mkcd <папка> Создать папку и войти
'@
        git = @'
[Git — контроль версий (история изменений кода)]
  gs           git status — что изменилось
  ga .         добавить все файлы
  gc -m "msg"  сохранить версию (commit)
  gp / gl      отправить / получить с сервера
  gd           показать изменения (diff)
  glog         история коммитов
'@
        python = @'
[Python]
  py           запуск python
  New-Venv     создать виртуальное окружение .venv
  Enter-Venv   активировать .venv
  pip install  установить библиотеку
'@
        tools = @'
[Инструменты оболочки]
  ll / ls      список файлов с иконками (eza)
  lt           дерево папок
  cat <файл>   просмотр с подсветкой (bat)
  Ctrl+R       поиск по истории (fzf)
  sysinfo      сводка о системе (fastfetch)
'@
        maintenance = @'
[Обслуживание и HOME BASE]
  doctor           полная проверка здоровья
  home / jarvis    домашняя панель управления
  nettools         сетевая панель
  toolcheck        проверка инструментов
  komandy          все команды по группам
  instrumenty      описание всех программ
  cleanup          безопасная очистка
  backupconfig     резервная копия настроек
  repairterminal   починка терминала
  learn -Topic git обучение
'@
        security = @'
[SHADOW OPS — Tor + PGP]
  sec              меню: статус + все действия
  sec -Guide       playbook безопасной сессии
  tor-check        чеклист перед Tor
  tor-harden       hardening Tor Browser
  tor-lock         kill switch (admin, перед .onion)
  tor-unlock       после сессии (admin)
  pgp-fingerprint  отпечаток для контактов
  pgp-export       публичный ключ (.asc)
  sec-help         полная шпаргалка

[Windows hardening]
  securitycheck    UAC, firewall, SMB1
  windowsstatus    privacy + performance score
'@
    }

    Write-Host "`n  Справка HOME BASE — $script:WSOwner" -ForegroundColor Cyan
    Write-Host "  Темы: help -Topic git | python | nav | tools | maintenance | security`n" -ForegroundColor DarkGray

    if ($Topic -eq 'all') {
        foreach ($key in @('nav','git','python','tools','maintenance','security')) {
            Write-Host $sections[$key] -ForegroundColor Green
        }
    } else {
        Write-Host $sections[$Topic] -ForegroundColor Green
    }
    Write-Host "  Подробнее: komandy · cheatsheet · home`n" -ForegroundColor DarkGray
}

function helpme {
    param([switch]$Help, [string]$Topic)
    if ($Help) { Show-WorkstationCommandHelp -Name 'helpme'; return }
    if ($Topic) { help -Topic $Topic } else { help -Topic all }
}

function cheatsheet {
    param([switch]$Help)
    if (Test-ShowCommandHelp -Name 'cheatsheet' -Help:$Help) { return }
    Invoke-WorkstationCmd 'cheatsheet' {
        $paths = @(
            Join-Path $script:WSRoot 'docs\ru\QUICKREF.md'
            Join-Path $script:WSRoot 'docs\CHEATSHEET.md'
        )
        $path = @($paths | Where-Object { Test-Path $_ } | Select-Object -First 1)[0]
        if ($path) {
            if (Get-Command bat -ErrorAction SilentlyContinue) { bat $path }
            else { Get-Content $path }
        } else { help -Topic all }
    }
}

function quickstart {
    param([switch]$Help)
    if (Test-ShowCommandHelp -Name 'quickstart' -Help:$Help) { return }
    Invoke-WorkstationCmd 'quickstart' {
        Write-Host "`n  Быстрый старт — HOME BASE" -ForegroundColor Cyan
        Write-Host "  1. home / devstart     Домашняя панель и папка проектов"
        Write-Host "  2. new-project MyApp   Новый проект с git"
        Write-Host "  3. komandy / helpme    Все команды с объяснениями"
        Write-Host "  4. doctor              Проверка здоровья"
        Write-Host "  5. instrumenty         Что установлено и зачем"
        Write-Host "  6. repairterminal      Если что-то сломалось`n" -ForegroundColor DarkGray
    }
}

function learn {
    param(
        [ValidateSet('git','python','powershell','vscode','debug','venv','pip','homebase','security','all')][string]$Topic = 'all',
        [ValidateSet('1','2','3','4','5','6')][string]$Quest,
        [switch]$Help
    )
    if ($Help) { Show-WorkstationCommandHelp -Name 'learn'; return }

    $quests = @{
        '1' = @(
            'Квест 1: Первый запуск HOME BASE'
            '  1. home          — обзор системы'
            '  2. scan           — быстрая проверка'
            '  3. trustcheck     — live integrity'
            '  4. komandy        — каталог команд'
        )
        '2' = @(
            'Квест 2: Сеть и инструменты'
            '  1. nettools       — сетевая панель'
            '  2. toolcheck      — проверка утилит'
            '  3. instrumenty    — что установлено'
            '  4. networkstatus  — статус сети'
        )
        '3' = @(
            'Квест 3: Разработка'
            '  1. devstart       — папка проектов'
            '  2. new-project X  — новый проект'
            '  3. gs / gc / gp   — git workflow'
            '  4. Enter-Venv     — Python окружение'
        )
        '4' = @(
            'Квест 4: Обслуживание'
            '  1. doctor         — полная диагностика'
            '  2. backupconfig   — бэкап настроек'
            '  3. cleanup        — очистка (сначала -WhatIf)'
            '  4. repairterminal — если сломался терминал'
        )
        '5' = @(
            'Квест 5: MAX mode'
            '  1. hack / menu    — hacker menu'
            '  2. sec            — SHADOW OPS (Tor + PGP)'
            '  3. palette        — fzf палитра (Ctrl+Alt+H)'
            '  4. sec -Guide     — playbook безопасной сессии'
        )
        '6' = @(
            'Квест 6: SHADOW OPS (Tor + PGP)'
            '  1. sec            — главное меню безопасности'
            '  2. tor-check      — чеклист перед сессией'
            '  3. tor-harden     — hardening Tor Browser'
            '  4. pgp-fingerprint — отпечаток для контактов'
            '  5. tor-lock       — kill switch (admin, перед .onion)'
            '  6. tor-unlock     — после сессии (admin)'
        )
    }

    if ($Quest) {
        Invoke-WorkstationCmd 'learn' {
            Write-Host ''
            $quests[$Quest] | ForEach-Object { Write-Host $_ -ForegroundColor $(if ($_ -match '^Квест') { 'Cyan' } else { 'Green' }) }
            Write-Host "  Другие квесты: learn -Quest 1|2|3|4|5|6`n" -ForegroundColor DarkGray
        }
        return
    }

    $topics = @{
        git = @'
[Git — сохранение версий кода]
  git init -b main     начать отслеживание
  gs                   посмотреть изменения
  ga .                 добавить все файлы
  gc -m "сообщение"    сохранить снимок
  gp / gl              отправить / получить
'@
        python = @'
[Python — скрипты и программы]
  python file.py       запустить скрипт
  New-Venv             создать изолированное окружение
  Enter-Venv           активировать его
  pip install requests установить библиотеку
'@
        powershell = @'
[PowerShell — автоматизация Windows]
  Get-Help Get-Process встроенная справка
  ll                   список файлов
  doctor               проверка системы
  home                 домашняя панель
'@
        vscode = @'
[VS Code — редактор]
  code .               открыть текущую папку
  Ctrl+Shift+P         палитра команд
  Ctrl+`               встроенный терминал
'@
        venv = @'
[Виртуальные окружения Python]
  New-Venv             создаёт .venv/
  Enter-Venv           активирует (меняется prompt)
  deactivate           выход из venv
'@
        pip = @'
[pip — менеджер пакетов Python]
  pip install package  установить
  pip list             что установлено
  pip freeze > req.txt сохранить зависимости
'@
        debug = @'
[Отладка]
  python -m pdb script.py   отладчик Python
  Write-Host "x=$x"          вывод в PowerShell
  doctor                    здоровье системы
'@
        homebase = @'
[HOME BASE — центр управления]
  home / hack / menu    панель и hacker menu
  sec / sec -Guide      Tor + PGP (SHADOW OPS)
  scan / trustcheck     быстрая и live проверка
  palette               fzf палитра команд
  learn -Quest 1        guided квесты 1–6
  explain <cmd>         справка по команде
'@
        security = @'
[SHADOW OPS — Tor + PGP]
  sec                   меню: статус + все действия
  sec -Guide            playbook безопасной сессии
  tor-check             чеклист перед Tor
  tor-lock / tor-unlock kill switch (admin)
  pgp-fingerprint       сверка отпечатка out-of-band
  sec-help              полная шпаргалка
'@
    }
    Invoke-WorkstationCmd 'learn' {
        Write-Host "`n  Обучение — $Topic" -ForegroundColor Cyan
        if ($Topic -eq 'all') {
            Write-Host "  Квесты: learn -Quest 1|2|3|4|5|6`n" -ForegroundColor Yellow
            $topics.Values | ForEach-Object { Write-Host $_ -ForegroundColor Green }
        }
        else { Write-Host $topics[$Topic] -ForegroundColor Green }
        Write-Host ""
    }
}

function komandy {
    param([switch]$Help)
    if (Test-ShowCommandHelp -Name 'komandy' -Help:$Help) { return }
    Invoke-WorkstationCmd 'komandy' { Show-CommandGroupsRu }
}
