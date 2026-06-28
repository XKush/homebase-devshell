# Professional networking & diagnostic toolkit — command center integration
# C:\Scripts\Workstation\lib\WorkstationToolkit.ps1

$script:ToolkitRoot = 'C:\Scripts\Workstation'
$script:NetworkingHome = if ($env:NETWORKING_HOME) { $env:NETWORKING_HOME } else { 'C:\Networking' }

function Get-WorkstationToolInventory {
    $tools = @(
        @{ Group = 'Network'; Name = 'Nmap';       Cmd = 'nmap';       VersionArg = '--version' }
        @{ Group = 'Network'; Name = 'Wireshark';   Cmd = 'wireshark';  VersionArg = '--version' }
        @{ Group = 'Network'; Name = 'TShark';      Cmd = 'tshark';     VersionArg = '-v' }
        @{ Group = 'Network'; Name = 'OpenSSH';     Cmd = 'ssh';        VersionArg = '-V' }
        @{ Group = 'Network'; Name = 'OpenSSL';     Cmd = 'openssl';    VersionArg = 'version' }
        @{ Group = 'Network'; Name = 'PuTTY';       Cmd = 'putty';      VersionArg = $null }
        @{ Group = 'System';  Name = 'Process Explorer'; Cmd = 'procexp64'; File = 'procexp64.exe' }
        @{ Group = 'System';  Name = 'Process Monitor';  Cmd = 'procmon64'; File = 'procmon64.exe' }
        @{ Group = 'System';  Name = 'TCPView';          Cmd = 'tcpview64'; File = 'tcpview64.exe' }
        @{ Group = 'Search';  Name = 'Everything';  Cmd = 'everything'; VersionArg = $null }
        @{ Group = 'Dev';     Name = 'Git';          Cmd = 'git';        VersionArg = '--version' }
        @{ Group = 'Dev';     Name = 'GitHub CLI';   Cmd = 'gh';         VersionArg = '--version' }
        @{ Group = 'Dev';     Name = 'ripgrep';      Cmd = 'rg';         VersionArg = '--version'; Optional = $true }
        @{ Group = 'Dev';     Name = 'fd';           Cmd = 'fd';         VersionArg = '--version'; Optional = $true }
        @{ Group = 'Dev';     Name = 'jq';           Cmd = 'jq';         VersionArg = '--version'; Optional = $true }
        @{ Group = 'Dev';     Name = 'yq';           Cmd = 'yq';         VersionArg = '--version'; Optional = $true }
        @{ Group = 'Dev';     Name = 'lazygit';      Cmd = 'lazygit';    VersionArg = '--version'; Optional = $true }
        @{ Group = 'Shell';   Name = 'PowerShell';   Cmd = 'pwsh';       VersionArg = '--version' }
        @{ Group = 'Shell';   Name = 'fzf';          Cmd = 'fzf';        VersionArg = '--version' }
        @{ Group = 'Shell';   Name = 'bat';          Cmd = 'bat';        VersionArg = '--version' }
        @{ Group = 'Shell';   Name = 'eza';          Cmd = 'eza';        VersionArg = '--version' }
    )

    $sysDir = @(
        'C:\Tools\Sysinternals',
        'C:\Program Files\Sysinternals',
        (Join-Path $env:USERPROFILE 'Downloads\SysinternalsSuite')
    ) | Where-Object { Test-Path $_ } | Select-Object -First 1

    $result = foreach ($t in $tools) {
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
            } catch { $ver = '?' }
        } elseif ($cmd) { $ver = 'installed' }

        [PSCustomObject]@{
            Group    = $t.Group
            Name     = $t.Name
            Command  = $t.Cmd
            Status   = if ($cmd) { 'OK' } elseif ($t.Optional) { 'optional' } else { 'MISSING' }
            Version  = $ver
            Path     = if ($cmd) { $cmd.Source } else { $null }
        }
    }
    return @($result)
}

function Invoke-ToolCheck {
    Write-Host "`n  Tool Check — KGreen Workstation" -ForegroundColor Cyan
    Write-Host ('  ' + ('─' * 70)) -ForegroundColor DarkGray
    $inv = Get-WorkstationToolInventory
    $missing = @($inv | Where-Object { $_.Status -eq 'MISSING' })
    $inv | Group-Object Group | ForEach-Object {
        Write-Host "`n  [$($_.Name)]" -ForegroundColor Yellow
        $_.Group | ForEach-Object {
            $icon = switch ($_.Status) { 'OK' { '+' } 'optional' { '~' } default { '!' } }
            $col  = switch ($_.Status) { 'OK' { 'Green' } 'optional' { 'DarkGray' } default { 'Red' } }
            $pathShort = if ($_.Path) { $_.Path -replace [regex]::Escape($env:USERPROFILE), '~' } else { '-' }
            Write-Host ("  [{0}] {1,-18} {2}" -f $icon, $_.Name, $_.Version) -ForegroundColor $col
            if ($_.Status -eq 'MISSING') { Write-Host "        $pathShort" -ForegroundColor DarkGray }
        }
    }
    Write-Host ""
    if ($missing.Count) {
        Write-Host "  $($missing.Count) required tool(s) missing — run: Install-NetworkToolkit.ps1" -ForegroundColor Yellow
    } else {
        Write-Host "  All required tools present." -ForegroundColor Green
    }
    Write-Host ""
}

function Show-NetTools {
    Write-Host "`n  Network Toolkit — KGreen" -ForegroundColor Cyan
    Write-Host @"

  Diagnostics
    networkstatus          Adapters, public IP, firewall
    nmap -sn 192.168.1.0/24   Host discovery (adjust subnet)
    tshark -i 1 -a duration:10  Capture 10s (list interfaces: tshark -D)
    Test-NetConnection host -Port 443   PowerShell connectivity test

  GUI tools
    wireshark              Packet analyzer
    procexp64              Process Explorer (Sysinternals)
    procmon64              Process Monitor
    tcpview64              Live TCP/UDP connections
    putty                  SSH/Telnet client
    everything             Instant file search

  CLI utilities
    ssh user@host          OpenSSH client
    openssl s_client -connect host:443   TLS probe
    gh auth status         GitHub CLI
    rg pattern C:\Projects Search code (ripgrep)

  Repair
    Install-NetworkToolkit.ps1   Install/upgrade all tools
    toolcheck                      Verify installations

"@ -ForegroundColor Green
    Invoke-ToolCheck
}

function Show-Toolbox {
    Write-Host "`n  Workstation Toolbox — KGreen" -ForegroundColor Cyan
    Write-Host @"

  Navigation        helpme · quickstart · projects · devstart · whereami
  Health            doctor · healthcheck · sysaudit · toolcheck
  Network           nettools · networkstatus
  Maintenance       cleanup · backupconfig · updateall · repairterminal
  Development       new-project · learn · cheatsheet · lazygit (if installed)
  System            sysinfo · devinfo · securitycheck · admin

"@ -ForegroundColor Green
    Invoke-ToolCheck
}

function Invoke-SysAudit {
    Write-Host "`n  System Audit — KGreen" -ForegroundColor Cyan
    $script = Join-Path $script:ToolkitRoot 'Invoke-OrganizationAudit.ps1'
    if (Test-Path $script) {
        & $script
    } else {
        Write-Host "  Running discovery..." -ForegroundColor DarkGray
        & (Join-Path $script:ToolkitRoot 'Invoke-SystemDiscovery.ps1')
    }
    Write-Host "`n  Reports: C:\Logs\Workstation\" -ForegroundColor DarkGray
    Get-ChildItem 'C:\Logs\Workstation' -Filter 'organization-audit-*.json' -EA SilentlyContinue |
        Sort-Object Name -Descending | Select-Object -First 1 |
        ForEach-Object { Write-Host "  Latest: $($_.Name)" -ForegroundColor White }
    Write-Host ""
}

# Aliases for Sysinternals (launch from any directory)
function procexp { & (Find-SysinternalsTool 'procexp64.exe') @args }
function procmon { & (Find-SysinternalsTool 'procmon64.exe') @args }
function tcpview { & (Find-SysinternalsTool 'tcpview64.exe') @args }

function Find-SysinternalsTool([string]$Exe) {
    $paths = @(
        (Get-Command $Exe -EA SilentlyContinue).Source
        'C:\Tools\Sysinternals\' + $Exe
        'C:\Program Files\Sysinternals\' + $Exe
        (Join-Path $env:USERPROFILE "Downloads\SysinternalsSuite\$Exe")
        (Join-Path 'C:\Networking\Tools' $Exe)
    ) | Where-Object { $_ -and (Test-Path $_) } | Select-Object -First 1
    if (-not $paths) { throw "Sysinternals $Exe not found — run Install-NetworkToolkit.ps1" }
    return $paths
}

# Quick network aliases
Set-Alias -Name ping-test -Value Test-NetConnection -Force -ErrorAction SilentlyContinue

function portscan {
    param(
        [Parameter(Mandatory)][string]$HostName,
        [int[]]$Ports = @(22, 80, 443, 3389, 8080)
    )
    foreach ($p in $Ports) {
        $r = Test-NetConnection -ComputerName $HostName -Port $p -WarningAction SilentlyContinue
        $status = if ($r.TcpTestSucceeded) { 'OPEN' } else { 'closed' }
        $col = if ($r.TcpTestSucceeded) { 'Green' } else { 'DarkGray' }
        Write-Host ("  {0,-6} {1}" -f $p, $status) -ForegroundColor $col
    }
}

function cap {
    param([int]$Seconds = 30, [string]$OutDir = "$script:NetworkingHome\Captures")
    if (-not (Test-Path $OutDir)) { New-Item -ItemType Directory -Force -Path $OutDir | Out-Null }
    $out = Join-Path $OutDir ("capture-{0}.pcapng" -f (Get-Date -Format 'yyyyMMdd-HHmmss'))
    Write-Host "Capturing $Seconds s -> $out" -ForegroundColor Cyan
    tshark -i 1 -a "duration:$Seconds" -w $out
    Write-Host "Saved: $out" -ForegroundColor Green
}
