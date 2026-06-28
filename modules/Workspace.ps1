# Workspace — разработка и рабочая область

function workspace {
    param([switch]$Help)
    if (Test-ShowCommandHelp -Name 'workspace' -Help:$Help) { return }
    Invoke-WorkstationCmd 'workspace' {
        Write-Host "`n  Рабочая область" -ForegroundColor Cyan
        Write-Host "  Путь:     $PWD" -ForegroundColor White
        Write-Host "  Проекты:  $env:PROJECTS_HOME" -ForegroundColor DarkGray
        if (Test-Path .git) {
            Write-Host "  Git:      $(git branch --show-current 2>$null)" -ForegroundColor Green
            git status -sb 2>$null
        } else {
            Write-Host "  Git:      не репозиторий (git init -b main)" -ForegroundColor DarkGray
        }
        if (Test-Path .venv) { Write-Host "  Python:   .venv есть (Enter-Venv для активации)" -ForegroundColor Green }
        Write-Host ""
    }
}

function devstart {
    param([switch]$Help)
    if (Test-ShowCommandHelp -Name 'devstart' -Help:$Help) { return }
    Invoke-WorkstationCmd 'devstart' {
        Set-Location $env:PROJECTS_HOME
        Show-HomeBase -Force -Mode normal
        Write-Host "  Готово. Попробуйте: new-project myapp -Type python" -ForegroundColor Green
        Write-Host "  Справка: helpme · komandy · nettools`n" -ForegroundColor DarkGray
    }
}

function logs {
    param([switch]$Open, [switch]$Help)
    if (Test-ShowCommandHelp -Name 'logs' -Help:$Help) { return }
    Invoke-WorkstationCmd 'logs' {
        if ($Open) { Set-Location 'C:\Logs\Workstation' }
        Write-Host "`n  Журналы (C:\Logs\Workstation):" -ForegroundColor Cyan
        Get-ChildItem 'C:\Logs\Workstation' -File | Sort-Object LastWriteTime -Descending |
            Select-Object -First 12 Name, Length, LastWriteTime | Format-Table -AutoSize
    }
}

function securitycheck {
    param([switch]$Help)
    if (Test-ShowCommandHelp -Name 'securitycheck' -Help:$Help) { return }
    Invoke-WorkstationCmd 'securitycheck' {
        Write-Host "`n  Проверка безопасности (Defender намеренно отключён)" -ForegroundColor Cyan
        $uac = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' -EA SilentlyContinue
        Write-Host ("  UAC (контроль учётных записей): {0}" -f $(if ($uac.EnableLUA -eq 1) { 'ВКЛ' } else { 'ВЫКЛ — исправить!' })) -ForegroundColor $(if ($uac.EnableLUA -eq 1) { 'Green' } else { 'Red' })
        $smb1 = Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters' -Name SMB1 -EA SilentlyContinue
        Write-Host ("  SMB1 (устаревший протокол):     {0}" -f $(if ($smb1.SMB1 -eq 0) { 'отключён' } else { 'проверить' })) -ForegroundColor Green
        $def = Get-Service WinDefend -EA SilentlyContinue
        Write-Host ("  Defender:                       {0} (политика: держать выкл.)" -f $(if ($def.Status -eq 'Running') { 'ЗАПУЩЕН' } else { 'остановлен' })) -ForegroundColor DarkGray
        Write-Host "`n  Firewall (брандмауэр — защита сетевых подключений):" -ForegroundColor Yellow
        Get-NetFirewallProfile | ForEach-Object {
            $ok = $_.Enabled -and $_.DefaultInboundAction -eq 'Block'
            Write-Host ("    {0,-8} вкл={1} входящие={2}" -f $_.Name, $_.Enabled, $_.DefaultInboundAction) -ForegroundColor $(if ($ok) { 'Green' } else { 'Yellow' })
        }
        Write-Host ""
    }
}

function new-project {
    param(
        [Parameter(Mandatory)][string]$Name,
        [ValidateSet('python','empty')][string]$Type = 'empty',
        [switch]$Help
    )
    if ($Help) { Show-WorkstationCommandHelp -Name 'new-project'; return }
    Invoke-WorkstationCmd 'new-project' {
        $path = Join-Path $env:PROJECTS_HOME $Name
        if (Test-Path $path) { throw "Уже существует: $path" }
        New-Item -ItemType Directory -Path $path -Force | Out-Null
        Set-Location $path
        git init -b main | Out-Null
        @'
# Python
__pycache__/
.venv/
.env
'@ | Set-Content .gitignore -Encoding UTF8
        if ($Type -eq 'python') { New-Venv }
        Write-Host "  Проект создан: $path" -ForegroundColor Green
        Write-Host "  code .   # открыть в VS Code" -ForegroundColor DarkGray
    }
}

function devinfo {
    param([switch]$Help)
    if (Test-ShowCommandHelp -Name 'devinfo' -Help:$Help) { return }
    Invoke-WorkstationCmd 'devinfo' {
        Write-Host "`n=== Среда разработки ===" -ForegroundColor Cyan
        if (Get-Command fastfetch -ErrorAction SilentlyContinue) {
            fastfetch --structure title:separator:os:host:kernel:uptime:shell:de:wm:term:cpu:gpu:memory:disk
        }
        Write-Host "`n--- Инструменты ---" -ForegroundColor Yellow
        foreach ($cmd in @('pwsh','git','python','code','node')) {
            if (Get-Command $cmd -ErrorAction SilentlyContinue) {
                $v = & $cmd --version 2>&1 | Select-Object -First 1
                Write-Host ("  {0,-10} {1}" -f $cmd, $v)
            }
        }
        Write-Host "`n--- Git ---" -ForegroundColor Yellow
        Write-Host "  $(git config --global user.name) <$(git config --global user.email)>"
        Write-Host "  Проекты: $env:PROJECTS_HOME"
        Write-Host ""
    }
}
