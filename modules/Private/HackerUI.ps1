# HOME BASE — hacker / cyber cockpit UI (Tokyo Night + matrix green)

function Test-HackerUIEnabled {
    return ($env:WORKSTATION_HACKER_UI ?? '1') -ne '0'
}

function Get-HackerPalette {
    return @{
        Matrix   = 'DarkGreen'
        Neon     = 'Green'
        Cyan     = 'Cyan'
        Magenta  = 'Magenta'
        Alert    = 'Red'
        Warn     = 'Yellow'
        Muted    = 'DarkGray'
        Data     = 'White'
        Accent   = 'DarkCyan'
        TrustOk  = 'Green'
        TrustBad = 'Red'
    }
}

function Format-HackerBar {
    param(
        [int]$Percent,
        [int]$Width = 28,
        [string]$Label = ''
    )
    $pct = [math]::Max(0, [math]::Min(100, $Percent))
    $fill = [math]::Round($Width * $pct / 100)
    $bar = ('█' * $fill) + ('░' * ($Width - $fill))
    $lbl = if ($Label) { " $Label" } else { '' }
    return "[$bar] {0,3}%{1}" -f $pct, $lbl
}

function Write-HackerLine {
    param([string]$Text, [string]$Color = 'White', [string]$Prefix = '  ')
    Write-Host "$Prefix$Text" -ForegroundColor $Color
}

function Write-HackerRule {
    param([int]$Width = 62, [string]$Char = '─')
    Write-HackerLine ($Char * $Width) -Color DarkGray
}

function Write-HackerSection {
    param(
        [Parameter(Mandatory)][string]$Tag,
        [Parameter(Mandatory)][string]$Title,
        [string]$Color = 'Cyan'
    )
    Write-Host ''
    Write-HackerLine "[$Tag] $Title" -Color $Color
    Write-HackerRule
}

function Write-HackerStat {
    param(
        [Parameter(Mandatory)][string]$Key,
        [Parameter(Mandatory)][string]$Value,
        [string]$Color = 'White',
        [int]$KeyWidth = 14
    )
    Write-HackerLine ("{0,-$KeyWidth} {1}" -f $Key, $Value) -Color $Color
}

function Write-HackerBadge {
    param(
        [Parameter(Mandatory)][string]$Label,
        [Parameter(Mandatory)][string]$Value,
        [string]$Color = 'Green'
    )
    Write-Host "  [" -NoNewline -ForegroundColor DarkGray
    Write-Host $Label -NoNewline -ForegroundColor Cyan
    Write-Host ":$Value]" -NoNewline -ForegroundColor $Color
}

function Write-HackerBanner {
    param(
        [int]$TrustScore = 0,
        [int]$HealthScore = 0,
        [string]$TrustLevel = 'UNKNOWN',
        [string]$User = $env:USERNAME
    )

    $P = Get-HackerPalette
    $hostName = $env:COMPUTERNAME

    Write-Host ''
    Write-Host '  ╔══════════════════════════════════════════════════════════════╗' -ForegroundColor $P.Accent
    Write-Host '  ║' -NoNewline -ForegroundColor $P.Accent
    Write-Host '  ▓▓ HOME BASE // NEURAL COCKPIT' -NoNewline -ForegroundColor $P.Neon
    Write-Host (' ' * 18) -NoNewline
    Write-Host '▓▓  ║' -ForegroundColor $P.Accent
    Write-Host '  ║' -NoNewline -ForegroundColor $P.Accent
    Write-Host "  operator: $User@$hostName" -NoNewline -ForegroundColor $P.Cyan
    Write-Host (' ' * (33 - ($User.Length + $hostName.Length))) -NoNewline
    Write-Host '║' -ForegroundColor $P.Accent
    Write-Host '  ║' -NoNewline -ForegroundColor $P.Accent
    Write-Host '  mode: hacker/max · trust:live · selfcheck:on · lang:ru' -NoNewline -ForegroundColor $P.Muted
    Write-Host '   ║' -ForegroundColor $P.Accent
    Write-Host '  ╠══════════════════════════════════════════════════════════════╣' -ForegroundColor $P.Accent
    Write-Host '  ║  ' -NoNewline -ForegroundColor $P.Accent
    Write-Host (Format-HackerBar -Percent $HealthScore -Label 'HEALTH') -NoNewline -ForegroundColor $(if ($HealthScore -ge 90) { $P.TrustOk } elseif ($HealthScore -ge 70) { $P.Warn } else { $P.Alert })
    Write-Host '           ║' -ForegroundColor $P.Accent
    Write-Host '  ║  ' -NoNewline -ForegroundColor $P.Accent
    $tCol = switch ($TrustLevel) { 'VERIFIED' { $P.TrustOk } 'UNTRUSTED' { $P.TrustBad } default { $P.Warn } }
    Write-Host (Format-HackerBar -Percent $TrustScore -Label "TRUST/$TrustLevel") -NoNewline -ForegroundColor $tCol
    Write-Host '  ║' -ForegroundColor $P.Accent
    Write-Host '  ╚══════════════════════════════════════════════════════════════╝' -ForegroundColor $P.Accent
    Write-Host ''
}

function Write-HackerBootSequence {
    if (($env:WORKSTATION_HACKER_SCAN ?? '1') -eq '0') { return }
    $P = Get-HackerPalette
    foreach ($line in @(
        '[BOOT] mounting KGreen.Workstation module...'
        '[BOOT] running live trust probe...'
        '[BOOT] syncing command matrix...'
    )) {
        Write-HackerLine $line -Color $P.Matrix
    }
}

function Write-HackerStatusRow {
    param(
        [string]$Icon,
        [string]$Name,
        [string]$Status,
        [string]$Detail = ''
    )
    $col = switch ($Status) {
        'OK' { 'Green' } 'ERROR' { 'Red' } 'WARNING' { 'Yellow' } default { 'DarkGray' }
    }
    $sym = switch ($Status) { 'OK' { '++' } 'ERROR' { 'XX' } 'WARNING' { '!!' } default { '--' } }
    $det = if ($Detail) { " │ $Detail" } else { '' }
    Write-HackerLine ("[$sym] $Icon $Name$det") -Color $col
}

function Show-HackerCommandMatrix {
    $P = Get-HackerPalette
    Write-HackerSection -Tag 'CMD' -Title 'COMMAND MATRIX — быстрый доступ' -Color $P.Cyan

    $matrix = @(
        @{ Tag = 'SYS'; Color = 'Green';  Cmds = 'doctor · trustcheck · scan · windowsstatus · sysinfo' }
        @{ Tag = 'NET'; Color = 'Cyan';   Cmds = 'nettools · networkstatus · toolcheck · portscan' }
        @{ Tag = 'DEV'; Color = 'Magenta'; Cmds = 'devstart · projects · workspace · new-project' }
        @{ Tag = 'OPS'; Color = 'Yellow'; Cmds = 'cleanup · backupconfig · logs · updateall' }
        @{ Tag = 'REC'; Color = 'Red';    Cmds = 'repairterminal · fixprofile · restoreconfig' }
        @{ Tag = 'DOC'; Color = 'White';  Cmds = 'menu · palette · komandy · helpme · learn · hack' }
    )

    foreach ($row in $matrix) {
        Write-Host '  ' -NoNewline
        Write-Host "[$($row.Tag)]" -NoNewline -ForegroundColor $row.Color
        Write-Host " $($row.Cmds)" -ForegroundColor $P.Muted
    }
    Write-Host ''
    Write-HackerLine '>> любая команда: ``имя -help`` │ полный каталог: komandy' -Color $P.Matrix
}

function Show-HackerToolsGrid {
    param($Inventory)

    $P = Get-HackerPalette
    Write-HackerSection -Tag 'INV' -Title 'INVENTORY SCAN — инструменты системы' -Color $P.Neon

    $ruCatalog = Get-WorkstationToolCatalogRu
    foreach ($tool in $ruCatalog) {
        $item = $Inventory | Where-Object { $_.Name -eq $tool.Name -or $_.Command -eq $tool.Cmd } | Select-Object -First 1
        $st = if ($item) {
            switch ($item.Status) { 'OK' { '[OK]' } 'optional' { '[~~]' } default { '[!!]' } }
        } else { '[??]' }

        $stCol = switch ($st) { '[OK]' { $P.TrustOk } '[!!]' { $P.Alert } '[~~]' { $P.Muted } default { $P.Warn } }

        Write-Host '  ' -NoNewline
        Write-Host $st -NoNewline -ForegroundColor $stCol
        Write-Host " $($tool.Name.PadRight(16)) " -NoNewline -ForegroundColor $P.Data
        Write-Host $tool.What -ForegroundColor $P.Muted
        Write-Host ('  ' + (' ' * 22) + '>> ' + $tool.Example) -ForegroundColor $P.Matrix
    }
    Write-Host ''
}

function Show-HackerTrustPanel {
    param($Trust)

    $P = Get-HackerPalette
    $lvl = Get-TrustLevelRu -Level $Trust.Level

    Write-HackerSection -Tag 'TRUST' -Title 'РЕЖИМ ДОВЕРИЯ — панель не врёт' -Color $(if ($Trust.CanTrustDashboard) { $P.TrustOk } else { $P.TrustBad })

    Write-HackerStat 'LEVEL' $lvl.Text -Color $lvl.Color
    Write-HackerStat 'SCORE' (Format-HackerBar -Percent $Trust.Score -Width 20) -Color $lvl.Color
    Write-HackerStat 'SELFCHK' "$($Trust.SelfChecksPassed)/$($Trust.SelfChecksTotal) OK" -Color $(if ($Trust.SelfChecksPassed -eq $Trust.SelfChecksTotal) { $P.TrustOk } else { $P.Alert })
    Write-HackerStat 'PROBE' "$($Trust.ProbeDurationMs) ms · mode:$($Trust.TrustMode)" -Color $P.Muted
    Write-HackerStat 'INTEGRITY' $(if ($Trust.CanTrustDashboard) { 'CONFIRMED — live data' } else { 'COMPROMISED — fix required' }) -Color $(if ($Trust.CanTrustDashboard) { $P.TrustOk } else { $P.Alert })

    if ($Trust.BrokenCommands.Count) {
        Write-HackerStat 'BROKEN' ($Trust.BrokenCommands -join ', ') -Color $P.Alert
    }
    if (-not $Trust.CanTrustDashboard -and $Trust.Issues.Count) {
        Write-HackerLine '>> issues:' -Color $P.Warn
        $Trust.Issues | Select-Object -First 6 | ForEach-Object { Write-HackerLine "   $_" -Color $P.Warn -Prefix '' }
    }
    Write-Host ''
}

function Show-HackerRecommendations {
    param([string[]]$Items)

    $P = Get-HackerPalette
    Write-HackerSection -Tag 'TASK' -Title 'MISSION QUEUE — что сделать сегодня' -Color $P.Warn
    $i = 1
    foreach ($item in $Items) {
        Write-HackerLine ("{0:D2} >> {1}" -f $i, $item) -Color $P.Data
        $i++
    }
    Write-Host ''
}

function Show-HackerFooter {
    param([string]$Mode = 'minimal')
    $P = Get-HackerPalette
    Write-HackerRule -Char '═'
    $cmds = if ($Mode -eq 'full') {
        'hack · menu · scan · trustcheck · doctor · komandy · instrumenty · nettools'
    } else {
        'home · hack · scan · trustcheck · doctor · menu · komandy'
    }
    Write-HackerLine ">> $cmds" -Color $P.Matrix
    Write-HackerLine '>> `$env:WORKSTATION_STARTUP_MODE = minimal|normal|full' -Color $P.Muted
    Write-Host ''
}
