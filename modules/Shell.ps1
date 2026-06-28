# Shell — навигация и утилиты оболочки

$script:WorkstationRoots = @{
    Tools    = 'C:\Tools'
    Scripts  = 'C:\Scripts'
    Projects = 'C:\Projects'
    Logs     = 'C:\Logs'
    Backups  = 'C:\Backups'
    Security = 'C:\Security'
}

function projects {
    param([switch]$Help)
    if (Test-ShowCommandHelp -Name 'projects' -Help:$Help) { return }
    Set-Location $script:WorkstationRoots.Projects
    Write-Host "  → C:\Projects (папка проектов)" -ForegroundColor DarkGray
    Write-CommandLog 'projects' 'OK'
}

function tools {
    param([switch]$Help)
    if (Test-ShowCommandHelp -Name 'tools' -Help:$Help) { return }
    Set-Location $script:WorkstationRoots.Tools
    Write-Host "  → C:\Tools (установленные утилиты)" -ForegroundColor DarkGray
    Write-CommandLog 'tools' 'OK'
}

function scripts {
    param([switch]$Help)
    if (Test-ShowCommandHelp -Name 'scripts' -Help:$Help) { return }
    Set-Location $script:WorkstationRoots.Scripts
    Write-Host "  → C:\Scripts (скрипты рабочей станции)" -ForegroundColor DarkGray
    Write-CommandLog 'scripts' 'OK'
}

function Open-Project {
    param([Parameter(Mandatory)][string]$Name)
    $p = Join-Path $script:WorkstationRoots.Projects $Name
    if (-not (Test-Path $p)) { throw "Не найдено: $p" }
    Set-Location $p
}

function gs  { git status @args }
function ga  { git add @args }
function gc  { git commit @args }
function gp  { git push @args }
function gl  { git pull @args }
function gd  { git diff @args }
function gco { git checkout @args }
function gb  { git branch @args }
function glog { git log --oneline --graph --decorate -20 @args }

function Enter-Venv {
    param([string]$Path = '.venv')
    $a = Join-Path (Resolve-Path $Path).Path 'Scripts\Activate.ps1'
    if (-not (Test-Path $a)) { throw "Нет venv в $Path — сначала New-Venv" }
    . $a
}

function New-Venv {
    param([string]$Path = '.venv')
    python -m venv $Path
    Enter-Venv -Path $Path
    python -m pip install -U pip
}

function which { param([string]$Name) Get-Command $Name -ErrorAction SilentlyContinue | Format-List }
function touch { param([Parameter(Mandatory)][string]$Path) New-Item -ItemType File -Path $Path -Force | Out-Null }
function mkcd { param([Parameter(Mandatory)][string]$Path) New-Item -ItemType Directory -Path $Path -Force | Out-Null; Set-Location $Path }
function whereami {
    Write-Host "  Где вы: $PWD" -ForegroundColor Cyan
    if ((git rev-parse --is-inside-work-tree 2>$null) -eq 'true') { git status -sb }
    if ($env:VIRTUAL_ENV) { Write-Host "  Venv: $env:VIRTUAL_ENV" -ForegroundColor Green }
}
function explain {
    param([string]$Name, [switch]$Help)
    if ($Help -or -not $Name) {
        Write-Host '  explain <команда> — справка HOME BASE (или explain Get-Process для cmdlet)' -ForegroundColor Yellow
        return
    }
    if (Get-Command Show-WorkstationCommandHelp -ErrorAction SilentlyContinue) {
        $catalog = Get-WorkstationHelpCatalog
        if ($catalog.Commands.ContainsKey($Name)) {
            Show-WorkstationCommandHelp -Name $Name
            return
        }
    }
    if (Get-Command $Name -ErrorAction SilentlyContinue) { Get-Help $Name -ErrorAction SilentlyContinue | Out-String | Write-Host }
    else { Write-Host "  Команда ``$Name`` не найдена — попробуйте komandy" -ForegroundColor Red }
}

function sysinfo {
    param([switch]$Help)
    if (Test-ShowCommandHelp -Name 'sysinfo' -Help:$Help) { return }
    Invoke-WorkstationCmd 'sysinfo' {
        if (Get-Command fastfetch -ErrorAction SilentlyContinue) {
            $cfg = if ($env:FASTFETCH_CONFIG -and (Test-Path $env:FASTFETCH_CONFIG)) { $env:FASTFETCH_CONFIG } else { $null }
            if ($cfg) { fastfetch --config $cfg } else { fastfetch }
        } else {
            Get-ComputerInfo | Select-Object CsName, OsName, OsVersion, WindowsVersion
        }
    }
}

function admin {
    $prof = Join-Path $HOME 'Documents\PowerShell\Microsoft.PowerShell_profile.ps1'
    $here = ($PWD.Path -replace "'", "''")
    $boot = "`$env:WORKSTATION_JARVIS_SHOWN='0'; Set-Location '$here'; . '$prof'"
    Start-Process pwsh -Verb RunAs -ArgumentList @('-NoExit', '-Command', $boot)
}

function Initialize-ShellAliases {
    if (Get-Command eza -ErrorAction SilentlyContinue) {
        if (-not (Get-Command ls -ErrorAction SilentlyContinue)) { function script:ls { eza --icons @args } }
        if (-not (Get-Command ll -ErrorAction SilentlyContinue)) { function script:ll { eza -la --icons --git @args } }
        if (-not (Get-Command la -ErrorAction SilentlyContinue)) { function script:la { eza -a --icons @args } }
        if (-not (Get-Command lt -ErrorAction SilentlyContinue)) { function script:lt { eza --tree --level=2 --icons @args } }
    }
    if (Get-Command git -ErrorAction SilentlyContinue) {
        Set-Alias -Name g -Value git -Force -Scope Script -ErrorAction SilentlyContinue
    }
    if (Get-Command bat -ErrorAction SilentlyContinue) {
        Set-Alias -Name cat -Value bat -Force -Scope Script -ErrorAction SilentlyContinue
    }
}

Initialize-ShellAliases

function instrumenty {
    param([switch]$Help)
    if (Test-ShowCommandHelp -Name 'instrumenty' -Help:$Help) { return }
    Invoke-WorkstationCmd 'instrumenty' { Show-SystemToolsPanel }
}
