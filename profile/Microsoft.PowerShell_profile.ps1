#Requires -Version 7.0
# Production PowerShell 7 profile — KGreen workstation (sub-300ms load target)
# Canonical profile — deploy via Install-ShellProfile.ps1

$ErrorActionPreference = 'Continue'
$env:PROFILE_LOADED = '1'

# ── HOME BASE path SSOT bootstrap (before module load) ───────────────────────
function Resolve-WorkstationRepositoryRoot {
    if ($env:WORKSTATION_ROOT -and (Test-Path (Join-Path $env:WORKSTATION_ROOT 'Config\homebase.defaults.json'))) {
        return $env:WORKSTATION_ROOT
    }
    if ($env:HOMEBASE_CONFIG -and (Test-Path $env:HOMEBASE_CONFIG)) {
        $fromConfig = Split-Path (Split-Path $env:HOMEBASE_CONFIG -Parent) -Parent
        if (Test-Path (Join-Path $fromConfig 'lib\HomeBasePaths.ps1')) { return $fromConfig }
    }
    $parent = Split-Path $PSScriptRoot -Parent
    if (Test-Path (Join-Path $parent 'lib\HomeBasePaths.ps1')) { return $parent }
    if ((Split-Path $PSScriptRoot -Leaf) -eq 'profile') {
        return $parent
    }
    return 'C:\Scripts\Workstation'
}

$script:WSRoot = Resolve-WorkstationRepositoryRoot
. (Join-Path $script:WSRoot 'lib\HomeBasePaths.ps1')
. (Join-Path $script:WSRoot 'lib\WorkstationCommon.ps1')
. (Join-Path $script:WSRoot 'lib\ProfileEnvironment.ps1')

$script:IsInteractive = [Environment]::UserInteractive -and -not $env:CI -and $Host.Name -ne 'ServerRemoteHost'
$script:WorkstationSessionReady = $false

# ── Encoding (UTF-8 everywhere) ──────────────────────────────────────────────
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::InputEncoding  = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8
$env:PYTHONUTF8 = '1'

if (-not $env:WORKSTATION_LANG) { $env:WORKSTATION_LANG = 'ru' }
if (-not $env:WORKSTATION_TRUST_MODE) { $env:WORKSTATION_TRUST_MODE = 'strict' }
if (-not $env:WORKSTATION_HACKER_UI) { $env:WORKSTATION_HACKER_UI = '1' }
if (-not $env:WORKSTATION_HACKER_SCAN) { $env:WORKSTATION_HACKER_SCAN = '1' }
if (-not $env:WORKSTATION_STARTUP_MODE) { $env:WORKSTATION_STARTUP_MODE = 'minimal' }

# ── Profile environment state (declarative — paths + WORKSTATION_* ) ───────────
Initialize-WorkstationProfileEnvironment | Out-Null

# ── Profile boot module order ─────────────────────────────────────────────────
# 1. PSReadLine (interactive shell)
# 2. KGreen.Workstation (lazy — first prompt via Initialize-WorkstationModule)
# 3. posh-git, Terminal-Icons (deferred — Initialize-WorkstationSession)

$script:ProfileBootSessionModules = @('posh-git', 'Terminal-Icons')
$script:WorkstationModuleLoaded = $false

function Import-ProfileBootModule {
    param([Parameter(Mandatory)][string]$Name)
    if (Get-Module $Name) { return }
    if (Get-Module -ListAvailable $Name) {
        Import-Module $Name -ErrorAction SilentlyContinue
    }
}

function Initialize-WorkstationModule {
    if ($script:WorkstationModuleLoaded) { return }
    $script:WorkstationModuleLoaded = $true
    if (Get-Command Import-WorkstationProfileModule -ErrorAction SilentlyContinue) {
        Import-WorkstationProfileModule -Root $script:WSRoot | Out-Null
    }
}

# ── Session init (OMP, modules, zoxide) — deferred until first prompt ─────────
function Initialize-WorkstationSession {
    if ($script:WorkstationSessionReady -or -not $script:IsInteractive) { return }
    $script:WorkstationSessionReady = $true

    if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
        $omp = $script:ProfileOmpTheme
        if (-not (Test-Path $omp)) {
            $omp = Join-Path $script:WSRoot 'terminal\active-theme.omp.json'
        }
        if (Test-Path $omp) { oh-my-posh init pwsh --config $omp | Invoke-Expression }
    }
    foreach ($mod in $script:ProfileBootSessionModules) {
        Import-ProfileBootModule -Name $mod
    }
    if (Get-Command zoxide -ErrorAction SilentlyContinue) {
        Invoke-Expression (& zoxide init powershell --cmd z | Out-String)
    }
    if (Get-Command Register-WorkstationMenuHotkeys -ErrorAction SilentlyContinue) {
        Register-WorkstationMenuHotkeys
    }
}

# ── PSReadLine (profile boot step 1) ──────────────────────────────────────────
if ($script:IsInteractive -and (Get-Module -ListAvailable PSReadLine)) {
    Import-Module PSReadLine -ErrorAction SilentlyContinue
    try {
        Set-PSReadLineOption -EditMode Windows -HistorySearchCursorMovesToEnd
        Set-PSReadLineOption -PredictionSource History -PredictionViewStyle InlineView
        Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
        Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
        Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
    } catch { }
}

# ── First-prompt: JARVIS + session init ───────────────────────────────────────
if ($script:IsInteractive) {
    $script:InnerPrompt = $function:Prompt
    function global:Prompt {
        if (-not $script:WorkstationModuleLoaded) { Initialize-WorkstationModule }
        if ($env:WORKSTATION_JARVIS -ne '0' -and $env:WORKSTATION_JARVIS_SHOWN -ne '1') {
            $env:WORKSTATION_JARVIS_SHOWN = '1'
            if (Get-Command Show-HomeBase -ErrorAction SilentlyContinue) { Show-HomeBase }
            elseif (Get-Command Show-Woc -ErrorAction SilentlyContinue) { Show-Woc }
            elseif (Get-Command Show-StartupCommandCenter -ErrorAction SilentlyContinue) { Show-StartupCommandCenter }
        }
        if (-not $script:WorkstationSessionReady) { Initialize-WorkstationSession; $script:InnerPrompt = $function:Prompt }
        if ($script:InnerPrompt -and $script:InnerPrompt -ne $function:Prompt) { return & $script:InnerPrompt }
        return '> '
    }
}

# ── fzf ───────────────────────────────────────────────────────────────────────
if ($script:IsInteractive -and (Get-Command fzf -ErrorAction SilentlyContinue) -and (Get-Module PSReadLine)) {
    $env:FZF_DEFAULT_OPTS = '--height 40% --layout=reverse --border --prompt="> "'
    Set-PSReadLineKeyHandler -Key Ctrl+r -ScriptBlock {
        $cmd = Get-History | Select-Object -ExpandProperty CommandLine | fzf
        if ($cmd) { [Microsoft.PowerShell.PSConsoleReadLine]::Insert($cmd) }
    }
}

# ── Tools ─────────────────────────────────────────────────────────────────────
if (Get-Command eza -ErrorAction SilentlyContinue) {
    function ls { eza --icons @args }
    function ll { Initialize-WorkstationSession; eza -la --icons --git @args }
    function la { eza -a --icons @args }
    function lt { eza --tree --level=2 --icons @args }
} else { function ll { Get-ChildItem -Force @args } }
if (Get-Command bat -ErrorAction SilentlyContinue) {
    Set-Alias -Name cat -Value bat -Force -Option AllScope
    $env:BAT_THEME = 'TwoDark'
}

# ── Git ───────────────────────────────────────────────────────────────────────
Set-Alias -Name g -Value git -Force -ErrorAction SilentlyContinue
function gs  { git status @args }
function ga  { git add @args }
function gc  { git commit @args }
function gp  { git push @args }
function gl  { git pull @args }
function gd  { git diff @args }
function gco { git checkout @args }
function gb  { git branch @args }
function glog { git log --oneline --graph --decorate -20 @args }

# ── Navigation ────────────────────────────────────────────────────────────────
function projects { Set-Location $script:WorkstationRoots.Projects }
function tools    { Set-Location $script:WorkstationRoots.Tools }
function scripts  { Set-Location $script:WorkstationRoots.Scripts }
function logs     { Set-Location $script:WorkstationRoots.Logs }
function Open-Project {
    param([Parameter(Mandatory)][string]$Name)
    $p = Join-Path $script:WorkstationRoots.Projects $Name
    if (-not (Test-Path $p)) { Write-Error "Not found: $p"; return }
    Set-Location $p
}

# ── Python ────────────────────────────────────────────────────────────────────
function Enter-Venv {
    param([string]$Path = '.venv')
    $a = Join-Path (Resolve-Path $Path).Path 'Scripts\Activate.ps1'
    if (-not (Test-Path $a)) { Write-Error "No venv at $Path"; return }
    . $a
}
function New-Venv { param([string]$Path = '.venv'); python -m venv $Path; Enter-Venv -Path $Path; python -m pip install -U pip }

# ── Utilities ─────────────────────────────────────────────────────────────────
function which { param([string]$Name) Get-Command $Name -ErrorAction SilentlyContinue | Format-List }
function touch { param([Parameter(Mandatory)][string]$Path) New-Item -ItemType File -Path $Path -Force | Out-Null }
function mkcd  { param([Parameter(Mandatory)][string]$Path) New-Item -ItemType Directory -Path $Path -Force | Out-Null; Set-Location $Path }
function whereami {
    Write-Host "  Location: $PWD" -ForegroundColor Cyan
    if ((git rev-parse --is-inside-work-tree 2>$null) -eq 'true') { git status -sb }
    if ($env:VIRTUAL_ENV) { Write-Host "  Venv: $env:VIRTUAL_ENV" -ForegroundColor Green }
}
function sysinfo {
    if (Get-Command fastfetch -ErrorAction SilentlyContinue) {
        $cfg = if ($env:FASTFETCH_CONFIG -and (Test-Path $env:FASTFETCH_CONFIG)) { $env:FASTFETCH_CONFIG } else { $null }
        if ($cfg) { fastfetch --config $cfg } else { fastfetch }
    } else {
        Get-ComputerInfo | Select-Object CsName, OsName, OsVersion, WindowsVersion
    }
}

function admin {
    $prof = Join-Path $HOME 'Documents\PowerShell\Microsoft.PowerShell_profile.ps1'
    $here = ($PWD.Path -replace "'", "''")
    $boot = "`$env:WORKSTATION_JARVIS_SHOWN='0'; Set-Location '$here'; . '$prof'"
    Start-Process pwsh -Verb RunAs -ArgumentList @('-NoExit', '-Command', $boot)
}

# ── Menu hotkeys — Register-WorkstationMenuHotkeys (first prompt via session init) ─
