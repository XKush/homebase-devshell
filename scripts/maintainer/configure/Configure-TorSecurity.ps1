#Requires -Version 7.0
<#
.SYNOPSIS
    Maximum Tor session hardening for HOME BASE.
#>
param(
    [switch]$SkipInstall
)

. (Join-Path $PSScriptRoot '..\_Resolve-RepoRoot.ps1')
$repoRoot = Resolve-WorkstationRepoRoot -Start $PSScriptRoot

$ErrorActionPreference = 'Stop'
. "$repoRoot\lib\WorkstationCommon.ps1"
. "$repoRoot\lib\TorCommon.ps1"
Assert-DefenderUntouched

Write-WorkstationStep 'Tor maximum security profile'
Clear-TorKillSwitchLegacy

if (-not $SkipInstall -and -not (Find-TorBrowserExe)) {
    Write-WorkstationLog 'Tor Browser missing — installing…' 'INFO'
    & (Join-Path $repoRoot 'Install-TorBrowser.ps1')
}

$torExe = Find-TorBrowserExe
if (-not $torExe) {
    Write-WorkstationLog 'Install Tor Browser manually, then re-run tor-harden' 'ERROR'
    exit 1
}

Write-WorkstationStep 'Tor Browser profile hardening'
$profile = Ensure-TorBrowserProfileDir
if (-not $profile) {
    Write-WorkstationLog 'Profile not ready — open Tor Browser once, then re-run tor-harden' 'ERROR'
    exit 1
}
$userJs = Write-TorBrowserUserJs -ProfileDir $profile
Write-WorkstationLog "user.js → $userJs" 'OK'

$secDir = 'C:\Security\tor'
if (-not (Test-Path $secDir)) { New-Item -ItemType Directory -Force -Path $secDir | Out-Null }

@'
# TOR SESSION — правила (RU)

1. Только Tor Browser для .onion и darknet. Не смешивай с clearnet в одной сессии.
2. Перед сессией: tor-check → открыть Tor Browser.
3. PGP: pgp-fingerprint сверяй ДРУГИМ каналом. Не смешивай личность и псевдоним.
4. Не качай/не открывай файлы из чатов без проверки. Не включай Java/Flash/плагины.
5. После сессии: закрой Tor Browser.
6. Максимум анонимности = Tails OS на флешке (это Windows — компромисс).

Файлы: C:\Security\tor\ · docs/ru/TOR-MAX-SECURITY.md
'@ | Set-Content (Join-Path $secDir 'SESSION-RULES.txt') -Encoding UTF8

Set-TorSecurityState @{
    Timestamp  = (Get-Date).ToString('o')
    TorBrowser = $torExe
    Profile    = $profile
    UserJs     = $userJs
    Hardened   = $true
}

Write-Host @'

  Готово. Рекомендуемый порядок сессии:
    1. tor-check
    2. Tor Browser only
    3. pgp-* для переписки
    4. закрой Tor Browser после сессии

'@ -ForegroundColor Green
