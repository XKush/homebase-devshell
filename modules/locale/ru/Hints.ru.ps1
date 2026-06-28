# Подсказки после успешного выполнения команд (ru)

function Get-CommandHints {
    return @{
        doctor          = 'Следующий шаг: при ошибках — repairterminal · при OK — devstart'
        nettools        = 'Попробуйте: networkstatus · portscan 192.168.1.1 · instrumenty'
        toolcheck       = 'Установка недостающего: Install-NetworkToolkit.ps1'
        home            = 'MAX: hack · menu · scan · trustcheck · palette (Ctrl+Alt+H)'
        hack            = 'fzf menu или full cockpit — scan · trustcheck · palette'
        scan            = 'быстрый probe → trustcheck или doctor при [!!]'
        palette         = 'fzf по всем командам · Ctrl+Alt+H'
        menu            = 'hacker menu — то же что hack с fzf'
        trustcheck      = 'integrity OK → hack или home'
        devstart        = 'Создать проект: new-project MyApp -Type python'
        backupconfig    = 'Откат: restoreconfig (нужен admin)'
        cleanup         = 'Без удаления: cleanup -WhatIf'
        repairterminal  = 'После починки: reloadprofile · doctor'
        projects        = 'Новый проект: new-project имя · workspace'
        komandy         = 'Подробная справка: nettools -help · doctor -help'
        instrumenty     = 'Быстрая проверка: toolcheck'
        workspace       = 'Git: gs · Python: Enter-Venv · VS Code: code .'
        networkstatus   = 'Скан портов: portscan hostname'
        learn           = 'Темы: learn -Topic git|python|powershell'
        logs            = 'Открыть папку: logs -Open'
        sysreport       = 'Отчёт в C:\Logs\Workstation\'
        default         = 'Справка: ``{0} -help`` · Обзор: komandy · Доверие: trustcheck'
    }
}

function Write-CommandHint {
    param([Parameter(Mandatory)][string]$Name)
    $hints = Get-CommandHints
    $text = if ($hints.ContainsKey($Name)) { $hints[$Name] } else { $hints.default -f $Name }
    Write-Host "  💡 $text" -ForegroundColor DarkCyan
}
