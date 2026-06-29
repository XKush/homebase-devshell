# Tor — максимальная защита сессии (HOME BASE)
. (Join-Path $script:WSRoot 'lib\TorCommon.ps1')

function Show-TorHelpRu {
    Write-Host @'

  ═══ TOR — максимальная защита сессии ═══

  Tor Browser     = анонимный транспорт (.onion, скрытый маршрут)
  PGP             = шифрование содержимого (pgp-help)
  tor-lock        = firewall: блок Chrome/Edge/Firefox (admin)

  КОМАНДЫ
    tor-setup     установить Tor Browser
    tor-harden    профиль + правила + опционально lock
    tor-check     чеклист перед сессией
    tor-status    состояние
    tor-lock      включить kill switch (admin)
    tor-unlock    выключить kill switch (admin)

  Документация: docs/ru/TOR-MAX-SECURITY.md

'@ -ForegroundColor Green
}

function tor-setup {
    param([switch]$Help, [switch]$Force)
    if (Test-ShowCommandHelp -Name 'tor-setup' -Help:$Help) { return }
    Invoke-WorkstationCmd 'tor-setup' {
        $args = @{}
        if ($Force) { $args.Force = $true }
        & (Join-Path $script:WSRoot 'scripts\maintainer\install\Install-TorBrowser.ps1') @args
    }
}

function tor-harden {
    param([switch]$Help, [switch]$Lock)
    if (Test-ShowCommandHelp -Name 'tor-harden' -Help:$Help) { return }
    Invoke-WorkstationCmd 'tor-harden' {
        $args = @{}
        if ($Lock) { $args.LockSwitch = $true }
        & (Join-Path $script:WSRoot 'scripts\maintainer\configure\Configure-TorSecurity.ps1') @args
    }
}

function tor-check {
    param([switch]$Help)
    if (Test-ShowCommandHelp -Name 'tor-check' -Help:$Help) { return }
    Invoke-WorkstationCmd 'tor-check' {
        . (Join-Path $script:WSRoot 'lib\PgpCommon.ps1')
        $P = Get-HackerPalette
        Write-HackerSection -Tag 'SEC' -Title 'PREFLIGHT — перед Tor-сессией' -Color $P.Cyan
        foreach ($c in Invoke-TorPreflightCheck) {
            $color = if ($c.Ok) { $P.TrustOk } else { $P.Warn }
            $mark = if ($c.Ok) { '++' } else { '!!' }
            Write-HackerLine "[$mark] $($c.Check) — $($c.Hint)" -Color $color
        }
        Write-Host ''
        Write-HackerLine 'playbook: sec -Guide  ·  меню: sec' -Color $P.Matrix
        Write-Host ''
    }
}

function tor-status {
    param([switch]$Help)
    if (Test-ShowCommandHelp -Name 'tor-status' -Help:$Help) { return }
    Invoke-WorkstationCmd 'tor-status' {
        Write-HackerSection -Tag 'TOR' -Title 'SESSION STATUS' -Color Cyan
        $tor = Find-TorBrowserExe
        Write-HackerStat 'TOR BROWSER' $(if ($tor) { $tor } else { 'not installed' }) -Color $(if ($tor) { 'Green' } else { 'Red' })
        $state = Get-TorSecurityState
        if ($state) {
            Write-HackerStat 'HARDENED' $(if ($state.Hardened) { 'yes' } else { 'no' }) -Color Green
        }
        $lock = Test-TorKillSwitchActive
        Write-HackerStat 'KILL SWITCH' $(if ($lock) { 'ACTIVE' } else { 'off' }) -Color $(if ($lock) { 'Green' } else { 'Yellow' })
        Write-Host ''
    }
}

function tor-lock {
    param([switch]$Help)
    if (Test-ShowCommandHelp -Name 'tor-lock' -Help:$Help) { return }
    Invoke-WorkstationCmd 'tor-lock' {
        $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
            [Security.Principal.WindowsBuiltInRole]::Administrator)
        if (-not $isAdmin) {
            Write-HackerLine 'нужен admin — запускаю UAC…' -Color Yellow
            Write-HackerLine 'или: admin → tor-lock' -Color DarkGray
            Start-Process pwsh -Verb RunAs -ArgumentList @(
                '-NoProfile', '-Command',
                "Import-Module '$script:WSRoot\modules\KGreen.Workstation.psm1' -Force; tor-lock"
            )
            return
        }
        & (Join-Path $script:WSRoot 'scripts\maintainer\configure\Configure-TorSecurity.ps1') -LockSwitch -SkipInstall
    }
}

function tor-unlock {
    param([switch]$Help)
    if (Test-ShowCommandHelp -Name 'tor-unlock' -Help:$Help) { return }
    Invoke-WorkstationCmd 'tor-unlock' {
        $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
            [Security.Principal.WindowsBuiltInRole]::Administrator)
        if (-not $isAdmin) {
            Write-HackerLine 'нужен admin — запускаю UAC…' -Color Yellow
            Start-Process pwsh -Verb RunAs -ArgumentList @(
                '-NoProfile', '-Command',
                "Import-Module '$script:WSRoot\modules\KGreen.Workstation.psm1' -Force; tor-unlock"
            )
            return
        }
        & (Join-Path $script:WSRoot 'scripts\maintainer\configure\Configure-TorSecurity.ps1') -UnlockSwitch
    }
}

function tor-help {
    param([switch]$Help)
    if (Test-ShowCommandHelp -Name 'tor-help' -Help:$Help) { return }
    Invoke-WorkstationCmd 'tor-help' {
        Write-HackerLine 'полная шпаргалка → sec-help  ·  меню → sec' -Color DarkGray
        if (Get-Command Show-SecurityHelpRu -ErrorAction SilentlyContinue) { Show-SecurityHelpRu }
        else { Show-TorHelpRu }
    }
}

function tor-browser {
    param([switch]$Help)
    if (Test-ShowCommandHelp -Name 'tor-browser' -Help:$Help) { return }
    Invoke-WorkstationCmd 'tor-browser' {
        if (Get-Command Start-TorBrowserSession -ErrorAction SilentlyContinue) {
            Start-TorBrowserSession | Out-Null
        } else {
            throw 'Start-TorBrowserSession not available — check lib/AnonymityKit.ps1'
        }
    }
}
