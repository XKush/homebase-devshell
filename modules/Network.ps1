# Network — сетевая панель и инструменты
. (Join-Path $script:WSRoot 'lib\WorkstationCommon.ps1')

$script:NetworkingHome = if ($env:NETWORKING_HOME) { $env:NETWORKING_HOME } else { 'C:\Networking' }

function Get-WorkstationToolInventory {
    Initialize-OpenSslPath | Out-Null
    $tools = @(
        @{ Group = 'Сеть'; Name = 'Nmap';       Cmd = 'nmap';       VersionArg = '--version' }
        @{ Group = 'Сеть'; Name = 'Wireshark';   Cmd = 'wireshark';  VersionArg = '--version' }
        @{ Group = 'Сеть'; Name = 'TShark';      Cmd = 'tshark';     VersionArg = '-v' }
        @{ Group = 'Сеть'; Name = 'OpenSSH';     Cmd = 'ssh';        VersionArg = '-V' }
        @{ Group = 'Сеть'; Name = 'OpenSSL';     Cmd = 'openssl';    VersionArg = 'version' }
        @{ Group = 'Сеть'; Name = 'PuTTY';       Cmd = 'putty';      VersionArg = $null }
        @{ Group = 'Система'; Name = 'Process Explorer'; Cmd = 'procexp64'; File = 'procexp64.exe' }
        @{ Group = 'Система'; Name = 'Process Monitor';  Cmd = 'procmon64'; File = 'procmon64.exe' }
        @{ Group = 'Система'; Name = 'TCPView';          Cmd = 'tcpview64'; File = 'tcpview64.exe' }
        @{ Group = 'Поиск'; Name = 'Everything';  Cmd = 'everything'; VersionArg = $null }
        @{ Group = 'Разработка'; Name = 'Git';          Cmd = 'git';        VersionArg = '--version' }
        @{ Group = 'Разработка'; Name = 'GitHub CLI';   Cmd = 'gh';         VersionArg = '--version' }
        @{ Group = 'Разработка'; Name = 'ripgrep';      Cmd = 'rg';         VersionArg = '--version'; Optional = $true }
        @{ Group = 'Разработка'; Name = 'fd';           Cmd = 'fd';         VersionArg = '--version'; Optional = $true }
        @{ Group = 'Разработка'; Name = 'jq';           Cmd = 'jq';         VersionArg = '--version'; Optional = $true }
        @{ Group = 'Оболочка'; Name = 'PowerShell';   Cmd = 'pwsh';       VersionArg = '--version' }
        @{ Group = 'Оболочка'; Name = 'fzf';          Cmd = 'fzf';        VersionArg = '--version' }
        @{ Group = 'Оболочка'; Name = 'bat';          Cmd = 'bat';        VersionArg = '--version' }
        @{ Group = 'Оболочка'; Name = 'eza';          Cmd = 'eza';        VersionArg = '--version' }
        @{ Group = 'Оболочка'; Name = 'fastfetch';    Cmd = 'fastfetch';  VersionArg = '--version'; Optional = $true }
    )
    $sysDir = @('C:\Tools\Sysinternals', 'C:\Program Files\Sysinternals') | Where-Object { Test-Path $_ } | Select-Object -First 1
    foreach ($t in $tools) {
        $cmd = Get-Command $t.Cmd -ErrorAction SilentlyContinue
        if (-not $cmd -and $t.File -and $sysDir) {
            $fp = Join-Path $sysDir $t.File
            if (Test-Path $fp) { $cmd = [PSCustomObject]@{ Source = $fp } }
        }
        $ver = '-'
        if ($cmd -and $t.VersionArg) {
            try {
                if ($t.VersionArg -eq 'version') { $ver = (& $t.Cmd version 2>&1 | Select-Object -First 1).ToString().Trim() }
                else { $ver = (& $t.Cmd $t.VersionArg 2>&1 | Select-Object -First 1).ToString().Trim() }
            } catch { $ver = 'установлен' }
        } elseif ($cmd) { $ver = 'установлен' }
        [PSCustomObject]@{
            Group = $t.Group; Name = $t.Name; Command = $t.Cmd
            Status = if ($cmd) { 'OK' } elseif ($t.Optional) { 'optional' } else { 'MISSING' }
            Version = $ver; Path = if ($cmd) { $cmd.Source } else { $null }
        }
    }
}

function Invoke-ToolCheck {
    Write-Host "`n  Проверка инструментов — HOME BASE" -ForegroundColor Cyan
    Write-Host ('  ' + ('─' * 70)) -ForegroundColor DarkGray
    $inv = Get-WorkstationToolInventory
    $missing = @($inv | Where-Object { $_.Status -eq 'MISSING' })
    $inv | Group-Object Group | ForEach-Object {
        Write-Host "`n  [$($_.Name)]" -ForegroundColor Yellow
        foreach ($item in $_.Group) {
            $icon = switch ($item.Status) { 'OK' { '+' } 'optional' { '~' } default { '!' } }
            $col  = switch ($item.Status) { 'OK' { 'Green' } 'optional' { 'DarkGray' } default { 'Red' } }
            Write-Host ("  [{0}] {1,-18} {2}" -f $icon, $item.Name, $item.Version) -ForegroundColor $col
        }
    }
    Write-Host ""
    if ($missing.Count) {
        Write-Host "  Не хватает $($missing.Count) обязательных инструментов — Install-NetworkToolkit.ps1" -ForegroundColor Yellow
    } else {
        Write-Host "  Все обязательные инструменты на месте." -ForegroundColor Green
    }
    Write-Host "  Подробнее: instrumenty`n" -ForegroundColor DarkGray
}

function Show-NetTools {
    Write-Host "`n  Сетевая панель — HOME BASE" -ForegroundColor Cyan
    Write-Host @"

  Диагностика     networkstatus · nmap · tshark · Test-NetConnection
  GUI             wireshark · procexp · procmon · tcpview · putty · everything
  CLI             ssh · gh · rg
  Проверка        toolcheck · instrumenty · Install-NetworkToolkit.ps1

"@ -ForegroundColor Green
    Invoke-ToolCheck
}

function Show-Toolbox {
    Write-Host "`n  Обзор команд — HOME BASE" -ForegroundColor Cyan
    Write-Host @"
  [Система]        doctor · sysinfo · securitycheck
  [Сеть]           nettools · networkstatus · toolcheck
  [Разработка]     devstart · projects · workspace
  [Обслуживание]   cleanup · backupconfig · logs
  [Восстановление] repairterminal · fixprofile
  [Обучение]       helpme · learn · komandy · home
"@ -ForegroundColor Green
    Invoke-ToolCheck
}

function Invoke-SysAudit {
    param([switch]$Help)
    if (Test-ShowCommandHelp -Name 'sysaudit' -Help:$Help) { return }
    Invoke-WorkstationCmd 'sysaudit' {
        Write-Host "`n  Аудит организации файлов" -ForegroundColor Cyan
        $script = Join-Path $script:WSRoot 'Invoke-OrganizationAudit.ps1'
        if (Test-Path $script) { & $script } else { & (Join-Path $script:WSRoot 'Invoke-SystemDiscovery.ps1') }
        Write-Host "`n  Отчёты: C:\Logs\Workstation\" -ForegroundColor DarkGray
    }
}

function Find-SysinternalsTool([string]$Exe) {
    $paths = @(
        (Get-Command $Exe -EA SilentlyContinue).Source
        (Join-Path 'C:\Tools\Sysinternals' $Exe)
        (Join-Path 'C:\Program Files\Sysinternals' $Exe)
    ) | Where-Object { $_ -and (Test-Path $_) } | Select-Object -First 1
    if (-not $paths) { throw "Sysinternals $Exe не найден — Install-NetworkToolkit.ps1" }
    return $paths
}

function portscan {
    param([Parameter(Mandatory)][string]$HostName, [int[]]$Ports = @(22, 80, 443, 3389, 8080), [switch]$Help)
    if (Test-ShowCommandHelp -Name 'portscan' -Help:$Help) { return }
    Write-Host "`n  Сканирование портов: $HostName" -ForegroundColor Cyan
    foreach ($p in $Ports) {
        $r = Test-NetConnection -ComputerName $HostName -Port $p -WarningAction SilentlyContinue
        $st = if ($r.TcpTestSucceeded) { 'ОТКРЫТ' } else { 'закрыт' }
        Write-Host ("  {0,-6} {1}" -f $p, $st) -ForegroundColor $(if ($r.TcpTestSucceeded) { 'Green' } else { 'DarkGray' })
    }
    Write-Host ''
}

function toolcheck {
    param([switch]$Help)
    if (Test-ShowCommandHelp -Name 'toolcheck' -Help:$Help) { return }
    Invoke-WorkstationCmd 'toolcheck' { Invoke-ToolCheck }
}

function nettools {
    param([switch]$Help)
    if (Test-ShowCommandHelp -Name 'nettools' -Help:$Help) { return }
    Invoke-WorkstationCmd 'nettools' { Show-NetTools }
}

function toolbox {
    param([switch]$Help)
    if (Test-ShowCommandHelp -Name 'toolbox' -Help:$Help) { return }
    Invoke-WorkstationCmd 'toolbox' { Show-Toolbox }
}

function sysaudit {
    param([switch]$Help)
    Invoke-SysAudit -Help:$Help
}

function procexp { & (Find-SysinternalsTool 'procexp64.exe') @args }
function procmon { & (Find-SysinternalsTool 'procmon64.exe') @args }
function tcpview { & (Find-SysinternalsTool 'tcpview64.exe') @args }

function cap {
    param([int]$Seconds = 30, [string]$OutDir = "$script:NetworkingHome\Captures")
    if (-not (Test-Path $OutDir)) { New-Item -ItemType Directory -Force -Path $OutDir | Out-Null }
    $out = Join-Path $OutDir ("capture-{0}.pcapng" -f (Get-Date -Format 'yyyyMMdd-HHmmss'))
    Write-Host "  Захват $Seconds с -> $out" -ForegroundColor Cyan
    tshark -i 1 -a "duration:$Seconds" -w $out
    Write-Host "  Сохранено: $out" -ForegroundColor Green
}

function networkstatus {
    param([switch]$Help)
    if (Test-ShowCommandHelp -Name 'networkstatus' -Help:$Help) { return }
    Invoke-WorkstationCmd 'networkstatus' {
        Write-Host "`n  Состояние сети" -ForegroundColor Cyan
        Get-NetAdapter | Where-Object Status -eq 'Up' | Format-Table Name, InterfaceDescription, LinkSpeed -AutoSize
        Write-Host "  Адреса:" -ForegroundColor Yellow
        Get-NetIPAddress -AddressFamily IPv4 -EA SilentlyContinue |
            Where-Object { $_.IPAddress -notlike '127.*' -and $_.PrefixOrigin -ne 'WellKnown' } |
            Select-Object InterfaceAlias, IPAddress | Format-Table -AutoSize
        try {
            $ip = (Invoke-RestMethod -Uri 'https://api.ipify.org?format=json' -TimeoutSec 5).ip
            Write-Host "  Публичный IP: $ip" -ForegroundColor White
        } catch { Write-Host "  Публичный IP: недоступен (нет интернета?)" -ForegroundColor DarkGray }
        Write-Host "  DNS:" -ForegroundColor Yellow
        Get-DnsClientServerAddress -AddressFamily IPv4 -EA SilentlyContinue |
            Where-Object { $_.ServerAddresses } | Select-Object -First 3 InterfaceAlias, ServerAddresses | Format-List
        Write-Host "  Firewall (брандмауэр — защита сети):" -ForegroundColor Yellow
        Get-NetFirewallProfile | Format-Table Name, Enabled, DefaultInboundAction -AutoSize
        Write-Host "  Команды: nettools | portscan hostname | toolcheck`n" -ForegroundColor DarkGray
    }
}
