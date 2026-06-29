#Requires -Version 7.0
<#
.SYNOPSIS
    Deploy PowerShell profile, Windows Terminal theme, and default shell.
#>
param([switch]$Force)

$ErrorActionPreference = 'Stop'
$script:WSRoot = $PSScriptRoot
. "$PSScriptRoot\lib\HomeBasePaths.ps1"
. "$PSScriptRoot\lib\WorkstationCommon.ps1"

$backupRoot = Get-HomeBasePath -Name Backups
if (-not (Test-Path $backupRoot)) { New-Item -ItemType Directory -Force -Path $backupRoot | Out-Null }
$projectsRoot = Get-HomeBasePath -Name Projects
$toolsRoot = Get-HomeBasePath -Name Tools
$scriptsRoot = Get-HomeBasePath -Name Scripts

Write-WorkstationStep 'Deploying PowerShell profile'
$canonical = Join-Path $PSScriptRoot 'profile\Microsoft.PowerShell_profile.ps1'
$targets = @(
    Join-Path $HOME 'Documents\PowerShell\Microsoft.PowerShell_profile.ps1'
    Join-Path $HOME 'Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1'
    Join-Path $HOME 'PowerShell\profile.ps1'
)

foreach ($target in $targets) {
    $dir = Split-Path $target -Parent
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
    if ((Test-Path $target) -and -not $Force) {
        $backup = Join-Path $backupRoot "profile-$(Get-Date -Format 'yyyyMMdd-HHmmss')-$(Split-Path $target -Leaf)"
        Copy-Item $target $backup -Force
        Write-WorkstationLog "Backed up profile to $backup"
    }
    Copy-Item $canonical $target -Force
    Write-WorkstationLog "Deployed profile -> $target" 'OK'
}

# Lightweight loader for PS5 that points to PS7 profile content when possible
$ps5Loader = @"
# PS5 loader — use pwsh for full workstation experience
function projects { Set-Location '$projectsRoot' }
function tools    { Set-Location '$toolsRoot' }
function scripts  { Set-Location '$scriptsRoot' }
Write-Host '[PS5] Launch pwsh for full profile (Oh My Posh, eza, fzf).' -ForegroundColor DarkGray
"@
Set-Content -Path (Join-Path $HOME 'Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1') -Value $ps5Loader -Encoding UTF8

Write-WorkstationStep 'Configuring Windows Terminal'
$wtPath = Join-Path $env:LOCALAPPDATA 'Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json'
$template = Join-Path $PSScriptRoot 'terminal\settings.template.json'
if (Test-Path $wtPath) {
    $backup = Join-Path $backupRoot "terminal-settings-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
    Copy-Item $wtPath $backup -Force
    Write-WorkstationLog "Terminal settings backup: $backup"
    $current = Get-Content $wtPath -Raw | ConvertFrom-Json
    $tpl = Get-Content $template -Raw | ConvertFrom-Json
    $current.defaultProfile = $tpl.defaultProfile
    $current.copyOnSelect = $tpl.copyOnSelect
    if (-not $current.schemes) { $current.schemes = @() }
    $existing = @($current.schemes | ForEach-Object { $_.name })
    foreach ($scheme in $tpl.schemes) {
        if ($scheme.name -notin $existing) { $current.schemes += $scheme }
    }
    $current.profiles.defaults.colorScheme = 'ReviOS Hack Dark'
    $current.profiles.defaults.startingDirectory = $projectsRoot
    $fontFace = 'CaskaydiaCove NF'
    $current.profiles.defaults | Add-Member -NotePropertyName font -NotePropertyValue ([pscustomobject]@{ face = $fontFace; size = 11; weight = 'normal' }) -Force
    foreach ($prof in $current.profiles.list) {
        $prof | Add-Member -NotePropertyName font -NotePropertyValue ([pscustomobject]@{ face = $fontFace; size = 11 }) -Force
    }
    $ps7 = $current.profiles.list | Where-Object { $_.source -eq 'Windows.Terminal.PowershellCore' } | Select-Object -First 1
    if ($ps7) { $ps7.name = 'PowerShell 7'; $ps7.hidden = $false }
    $ps5 = $current.profiles.list | Where-Object { $_.commandline -like '*WindowsPowerShell*' } | Select-Object -First 1
    if ($ps5) { $ps5.hidden = $true }
    $current | ConvertTo-Json -Depth 20 | Set-Content $wtPath -Encoding UTF8
    Write-WorkstationLog 'Windows Terminal updated' 'OK'
} else {
    Write-WorkstationLog 'Windows Terminal settings not found — install Terminal first' 'WARN'
}

Write-WorkstationStep 'Setting PowerShell 7 as default terminal profile'
# Windows 11 default terminal app
$defTermPath = 'HKCU:\Console\%%Startup'
if (-not (Test-Path $defTermPath)) { New-Item -Path $defTermPath -Force | Out-Null }
Set-ItemProperty -Path $defTermPath -Name 'DelegationConsole' -Value '{2EACA947-7F04-4AF7-8F2A-1636C7663DCF}' -Type String -ErrorAction SilentlyContinue
Write-WorkstationLog 'Default terminal delegation set (Windows Terminal)' 'OK'

Write-WorkstationStep 'Execution policy (CurrentUser)'
try {
    Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned -Force -ErrorAction Stop
    Write-WorkstationLog 'ExecutionPolicy: RemoteSigned' 'OK'
} catch {
    Write-WorkstationLog "Execution policy unchanged: $(Get-ExecutionPolicy)" 'WARN'
}

Write-WorkstationStep 'Shell profile deployment complete'
Write-Host 'Restart Windows Terminal, then run: . $PROFILE' -ForegroundColor Green
