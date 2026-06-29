# SHADOW OPS — Tor + PGP (единое меню безопасности)
. (Join-Path $script:WSRoot 'lib\TorCommon.ps1')
. (Join-Path $script:WSRoot 'lib\PgpCommon.ps1')

function Get-SecurityReadinessReport {
    Initialize-GpgPath | Out-Null

    $pgpMeta = $null
    if (Test-Path 'C:\Security\pgp\pgp-identity.json') {
        try { $pgpMeta = Get-Content 'C:\Security\pgp\pgp-identity.json' -Raw | ConvertFrom-Json } catch { }
    }
    $pgpFpr = if ($pgpMeta) { $pgpMeta.Fingerprint } else { Get-GpgPrimaryFingerprint }
    $pgpUid = if ($pgpMeta) { $pgpMeta.Uid } else { $null }

    $torExe = Find-TorBrowserExe
    $torState = Get-TorSecurityState
    $killSwitch = Test-TorKillSwitchActive

    $score = 0
    if ($pgpFpr) { $score += 35 }
    if ($torExe) { $score += 25 }
    if ($torState -and $torState.Hardened) { $score += 20 }
    if ($killSwitch) { $score += 10 }
    if ($pgpMeta -and $pgpMeta.Revocation) { $score += 10 }

    $level = if ($score -ge 80) { 'READY' } elseif ($score -ge 50) { 'PARTIAL' } else { 'SETUP' }

    [PSCustomObject]@{
        Score       = $score
        Level       = $level
        PgpReady    = [bool]$pgpFpr
        PgpUid      = $pgpUid
        Fingerprint = $pgpFpr
        TorReady    = [bool]$torExe
        TorPath     = $torExe
        Hardened    = [bool]($torState -and $torState.Hardened)
        KillSwitch  = $killSwitch
    }
}

function Show-SecurityGuideRu {
    $P = Get-HackerPalette
    Write-HackerSection -Tag 'SEC' -Title 'PLAYBOOK — безопасная Tor-сессия' -Color $P.Neon

    $steps = @(
        @{ N = '01'; Cmd = 'tor-check';     Text = 'чеклист: Tor + PGP + kill switch' }
        @{ N = '02'; Cmd = 'tor-lock';      Text = 'admin — закрой Chrome/Edge, блок clearnet' }
        @{ N = '03'; Cmd = 'Tor Browser';   Text = 'ТОЛЬКО Tor Browser для .onion' }
        @{ N = '04'; Cmd = 'pgp-fingerprint'; Text = 'сверь отпечаток ДРУГИМ каналом' }
        @{ N = '05'; Cmd = 'pgp-encrypt';   Text = 'файлы/сообщения — шифруй локально' }
        @{ N = '06'; Cmd = 'tor-unlock';    Text = 'admin — после сессии снять lock' }
    )

    foreach ($s in $steps) {
        Write-Host '  ' -NoNewline
        Write-Host $s.N -NoNewline -ForegroundColor $P.Accent
        Write-Host ' │ ' -NoNewline -ForegroundColor $P.Muted
        Write-Host $s.Cmd.PadRight(18) -NoNewline -ForegroundColor $P.Cyan
        Write-Host $s.Text -ForegroundColor $P.Muted
    }

    Write-Host ''
    Write-HackerSection -Tag 'WARN' -Title 'NEVER — никогда' -Color $P.Alert
    foreach ($rule in @(
        'приватный ключ + passphrase — только локально'
        'не смешивай реальное имя и псевдоним'
        'не доверяй fingerprint из того же чата'
        'не открывай вложения без проверки'
    )) {
        Write-HackerLine "× $rule" -Color $P.Warn
    }
    Write-Host ''
}

function Show-SecurityStatusPanel {
    $P = Get-HackerPalette
    $r = Get-SecurityReadinessReport

    $lvlCol = switch ($r.Level) { 'READY' { $P.TrustOk } 'PARTIAL' { $P.Warn } default { $P.Alert } }

    Write-Host ''
    Write-Host '  ┌──────────────── SHADOW OPS ────────────────┐' -ForegroundColor $P.Accent
    Write-Host '  │' -NoNewline -ForegroundColor $P.Accent
    Write-Host ('  readiness: ' + (Format-HackerBar -Percent $r.Score -Width 22 -Label $r.Level)) -NoNewline -ForegroundColor $lvlCol
    Write-Host '  │' -ForegroundColor $P.Accent

    $torMark = if ($r.TorReady) { '++' } else { '!!' }
    $torCol = if ($r.TorReady) { $P.TrustOk } else { $P.Alert }
    $torDet = if ($r.TorReady) {
        $h = if ($r.Hardened) { 'hardened' } else { 'install ok · run tor-harden' }
        $l = if ($r.KillSwitch) { ' · LOCK ON' } else { ' · lock off' }
        "$h$l"
    } else { 'tor-setup' }
    Write-Host '  │' -NoNewline -ForegroundColor $P.Accent
    Write-Host "  [$torMark] TOR   $torDet" -ForegroundColor $torCol
    Write-Host '  │' -NoNewline -ForegroundColor $P.Accent

    $pgpMark = if ($r.PgpReady) { '++' } else { '!!' }
    $pgpCol = if ($r.PgpReady) { $P.TrustOk } else { $P.Alert }
    $pgpDet = if ($r.PgpReady) {
        $uid = if ($r.PgpUid) { $r.PgpUid } else { 'key ok' }
        $short = if ($r.Fingerprint.Length -gt 16) { $r.Fingerprint.Substring(0, 16) + '…' } else { $r.Fingerprint }
        "$uid · $short"
    } else { 'pgp-setup · pgp-repair' }
    Write-Host "  [$pgpMark] PGP   $pgpDet" -ForegroundColor $pgpCol
    Write-Host '  └──────────────────────────────────────────────┘' -ForegroundColor $P.Accent

    $next = if (-not $r.PgpReady) { 'pgp-repair' }
        elseif (-not $r.TorReady) { 'tor-setup → tor-harden' }
        elseif (-not $r.Hardened) { 'tor-harden' }
        elseif (-not $r.KillSwitch) { 'tor-check → tor-lock (admin)' }
        else { 'tor-check — ready for session' }
    Write-HackerLine ">> next: $next  ·  menu: sec  ·  guide: sec -Guide" -Color $P.Matrix
    Write-Host ''
}

function Show-SecurityHelpRu {
    $P = Get-HackerPalette
    Write-HackerSection -Tag 'SEC' -Title 'SHADOW OPS — Tor + PGP' -Color $P.Neon

    Write-HackerLine 'Tor  = куда ходишь (IP, маршрут, .onion)' -Color $P.Muted
    Write-HackerLine 'PGP  = что отправляешь (шифрование + подпись)' -Color $P.Muted
    Write-Host ''

    Write-HackerSection -Tag 'CMD' -Title 'КОМАНДЫ' -Color $P.Cyan
    $cmds = @(
        'sec / menu → SHADOW OPS     единое меню'
        'tor-check                   чеклист перед сессией'
        'tor-harden · tor-lock       hardening + kill switch'
        'pgp-fingerprint · pgp-export ключ для контактов'
        'pgp-encrypt · pgp-decrypt   файлы локально'
    )
    foreach ($c in $cmds) { Write-HackerLine $c -Color $P.Data }

    Write-Host ''
    Show-SecurityGuideRu
    Write-HackerLine 'docs: docs/ru/TOR-MAX-SECURITY.md · PGP-TOR-BASICS.md' -Color $P.Matrix
    Write-Host ''
}

function Get-SecurityMenuItems {
    return @(
        '[OVERVIEW] status — панель PGP + Tor'
        '[OVERVIEW] guide — playbook безопасной сессии'
        '[OVERVIEW] check — tor-check (preflight)'
        '[PGP] fingerprint — отпечаток для проверки'
        '[PGP] export — публичный ключ (.asc)'
        '[PGP] status — список ключей'
        '[PGP] repair — завершить настройку ключа'
        '[PGP] setup — создать новый ключ'
        '[TOR] harden — профиль + правила'
        '[TOR] setup — установить Tor Browser'
        '[TOR] lock — kill switch (admin)'
        '[TOR] unlock — снять lock (admin)'
        '[TOR] status — состояние Tor'
        '[DOC] help — полная шпаргалка'
        '[DOC] docs — открыть TOR-MAX-SECURITY.md'
    )
}

function Invoke-SecurityMenuAction {
    param([string]$Pick)

    if (-not $Pick) { return }

    switch -Wildcard ($Pick) {
        '*status —*'        { Show-SecurityStatusPanel; break }
        '*guide —*'         { Show-SecurityGuideRu; break }
        '*check —*'         { tor-check; break }
        '*fingerprint —*'   { pgp-fingerprint; break }
        '*export —*'        { pgp-export; break }
        '[PGP] status*'     { pgp-status; break }
        '*repair —*'        { pgp-repair; break }
        '*setup — создать*'  { pgp-setup; break }
        '*harden —*'        { tor-harden; break }
        '*setup — установить*' { tor-setup; break }
        '*lock —*'          { tor-lock; break }
        '*unlock —*'        { tor-unlock; break }
        '[TOR] status*'     { tor-status; break }
        '*help —*'          { Show-SecurityHelpRu; break }
        '*docs —*'          {
            $doc = Join-Path $script:WSRoot 'docs\ru\TOR-MAX-SECURITY.md'
            if (Get-Command bat -ErrorAction SilentlyContinue) { bat $doc }
            elseif (Test-Path $doc) { Get-Content $doc | Select-Object -First 40 }
            else { Write-HackerLine "нет файла: $doc" -Color Yellow }
            break
        }
        default             { Show-SecurityStatusPanel }
    }
}

function Show-SecurityMenu {
    Show-SecurityStatusPanel

    if (-not (Get-Command fzf -ErrorAction SilentlyContinue)) {
        Write-HackerLine 'fzf нет — используй: sec -Guide или tor-check' -Color Yellow
        Show-SecurityGuideRu
        return
    }

    $env:FZF_DEFAULT_OPTS = '--height 55% --layout=reverse --border --prompt="SEC> "'
    $pick = Get-SecurityMenuItems | fzf --header 'SHADOW OPS // Tor + PGP · Enter=run · Esc=back'
    Invoke-SecurityMenuAction -Pick $pick
}

function sec {
    param(
        [switch]$Help,
        [switch]$Status,
        [switch]$Guide,
        [switch]$Menu
    )

    if (Test-ShowCommandHelp -Name 'sec' -Help:$Help) { return }

    Invoke-WorkstationCmd 'sec' {
        if ($Status) { Show-SecurityStatusPanel; return }
        if ($Guide)  { Show-SecurityGuideRu; return }
        Show-SecurityMenu
    }
}

function privacy {
    param(
        [switch]$Help,
        [switch]$Status,
        [switch]$Guide,
        [switch]$Menu
    )
    sec @PSBoundParameters
}

function anon {
    param([switch]$Help)
    if (Test-ShowCommandHelp -Name 'anon' -Help:$Help) { return }
    Invoke-WorkstationCmd 'anon' { Invoke-WorkstationNavHub -Start 'sec' }
}

function sec-help {
    param([switch]$Help)
    if (Test-ShowCommandHelp -Name 'sec-help' -Help:$Help) { return }
    Invoke-WorkstationCmd 'sec-help' { Show-SecurityHelpRu }
}
