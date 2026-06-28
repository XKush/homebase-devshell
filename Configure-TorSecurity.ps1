#Requires -Version 7.0
<#
.SYNOPSIS
    Maximum Tor session hardening for HOME BASE.
.PARAMETER LockSwitch
    Enable firewall kill switch (blocks Chrome/Edge/Firefox outbound — admin).
.PARAMETER UnlockSwitch
    Remove kill switch rules.
#>
param(
    [switch]$LockSwitch,
    [switch]$UnlockSwitch,
    [switch]$SkipInstall
)

$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\lib\WorkstationCommon.ps1"
. "$PSScriptRoot\lib\TorCommon.ps1"
Assert-DefenderUntouched

Write-WorkstationStep 'Tor maximum security profile'

if ($UnlockSwitch) {
    Disable-TorKillSwitch
    Set-TorSecurityState @{
        Timestamp  = (Get-Date).ToString('o')
        KillSwitch = $false
        Hardened   = (Get-TorSecurityState).Hardened
    }
    Write-WorkstationLog 'Kill switch OFF — clearnet browsers allowed again' 'OK'
    exit 0
}

if (-not $SkipInstall -and -not (Find-TorBrowserExe)) {
    Write-WorkstationLog 'Tor Browser missing — installing…' 'INFO'
    & (Join-Path $PSScriptRoot 'Install-TorBrowser.ps1')
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

1. Только Tor Browser для .onion и darknet. Никакого Chrome/Edge параллельно.
2. Перед сессией: tor-check → tor-lock (admin) → открыть Tor Browser.
3. PGP: pgp-fingerprint сверяй ДРУГИМ каналом. Не смешивай личность и псевдоним.
4. Не качай/не открывай файлы из чатов без проверки. Не включай Java/Flash/плагины.
5. После сессии: закрой Tor Browser → tor-unlock (admin).
6. Максимум анонимности = Tails OS на флешке (это Windows — компромисс).

Файлы: C:\Security\tor\ · docs/ru/TOR-MAX-SECURITY.md
'@ | Set-Content (Join-Path $secDir 'SESSION-RULES.txt') -Encoding UTF8

if ($LockSwitch) {
    Enable-TorKillSwitch
    Write-WorkstationLog 'Kill switch ON — Chrome/Edge/Firefox outbound blocked' 'OK'
}

Set-TorSecurityState @{
    Timestamp   = (Get-Date).ToString('o')
    TorBrowser  = $torExe
    Profile     = $profile
    UserJs      = $userJs
    KillSwitch  = [bool](Test-TorKillSwitchActive)
    Hardened    = $true
}

Write-Host @'

  Готово. Рекомендуемый порядок сессии:
    1. tor-check
    2. tor-lock          (admin — блок clearnet-браузеров)
    3. Tor Browser only
    4. pgp-* для переписки
    5. tor-unlock         (после сессии)

'@ -ForegroundColor Green
