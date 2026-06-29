#Requires -Version 7.0
<#
.SYNOPSIS
    Repair Nerd Font installation and sync Windows Terminal font face.
    Fixes missing glyphs after reboot (wrong font family name).
#>
param([switch]$Force)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '..\_Resolve-RepoRoot.ps1')
$repoRoot = Resolve-WorkstationRepoRoot -Start $PSScriptRoot
$script:WSRoot = $repoRoot
. (Join-Path $repoRoot 'lib\WorkstationCommon.ps1')

# Correct face for terminal (mono nerd font — matches oh-my-posh CascadiaCode install)
$script:TerminalFontFace = 'CaskaydiaCove NF'

Write-WorkstationStep 'Nerd Font repair'

# Reinstall if missing NF Regular
$fontsKey = 'HKCU:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts'
$hasNF = (Get-ItemProperty $fontsKey -EA SilentlyContinue).PSObject.Properties.Name |
    Where-Object { $_ -like 'CaskaydiaCove NF Regular*' }
if (-not $hasNF -or $Force) {
    Write-WorkstationLog 'Installing CascadiaCode Nerd Font (headless)...'
    oh-my-posh font install CascadiaCode --headless 2>&1 | Out-Null
}

# Verify
$hasNF = (Get-ItemProperty $fontsKey -EA SilentlyContinue).PSObject.Properties.Name |
    Where-Object { $_ -like 'CaskaydiaCove NF Regular*' }
if (-not $hasNF) { throw 'CaskaydiaCove NF not installed — run: oh-my-posh font install CascadiaCode --headless' }
Write-WorkstationLog 'CaskaydiaCove NF verified in registry' 'OK'

Write-WorkstationStep 'Sync Windows Terminal font on ALL profiles'
$wtPath = Join-Path $env:LOCALAPPDATA 'Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json'
if (-not (Test-Path $wtPath)) { throw 'Windows Terminal settings not found' }

$backup = "C:\Backups\Workstation\terminal-pre-font-fix-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
Copy-Item $wtPath $backup -Force
$wt = Get-Content $wtPath -Raw | ConvertFrom-Json

# Force correct font face everywhere
$fontBlock = [ordered]@{ face = $script:TerminalFontFace; size = 11; weight = 'normal' }
$wt.profiles.defaults.font = $fontBlock
foreach ($prof in $wt.profiles.list) {
    if (-not $prof.font) { $prof | Add-Member -NotePropertyName font -NotePropertyValue ([pscustomobject]$fontBlock) -Force }
    else {
        $prof.font.face = $script:TerminalFontFace
        if (-not $prof.font.size) { $prof.font | Add-Member -NotePropertyName size -NotePropertyValue 11 -Force }
    }
}

# Ensure PS7 profile uses same scheme
$wt.profiles.defaults.colorScheme = 'ReviOS Hack Dark'
$wt | ConvertTo-Json -Depth 20 | Set-Content $wtPath -Encoding UTF8
Write-WorkstationLog "Terminal font set to: $script:TerminalFontFace" 'OK'

Write-WorkstationStep 'Persist font env for tools (eza icons)'
[Environment]::SetEnvironmentVariable('ESCAPE_UTILS_LOG_LEVEL', 'error', 'User') | Out-Null
# eza uses nerd font via terminal font — no extra env needed

# Write jarvis font status
@{
    FontFace    = $script:TerminalFontFace
    RepairedAt  = (Get-Date).ToString('o')
    RegistryOK  = $true
} | ConvertTo-Json | Set-Content 'C:\Logs\Workstation\font-status.json' -Encoding UTF8

Write-Host "Font repair complete. Restart Windows Terminal." -ForegroundColor Green
Write-Host "  Face: $script:TerminalFontFace (not 'CaskaydiaCove Nerd Font')" -ForegroundColor DarkGray
