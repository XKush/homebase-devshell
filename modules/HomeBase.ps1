# HOME BASE — neural cockpit (hacker max + trust mode)

function Get-HomeBaseScoreLabelRu {
    param([int]$Score)
    if ($Score -ge 90) { return 'NOMINAL' }
    if ($Score -ge 70) { return 'DEGRADED' }
    if ($Score -ge 50) { return 'ATTENTION' }
    return 'CRITICAL'
}

function Get-HomeBaseRecommendationsRu {
    param($Report, $Trust)

    $rec = [System.Collections.Generic.List[string]]::new()

    if (-not $Trust.CanTrustDashboard) {
        $rec.Add('trustcheck — live integrity scan (required)')
        if ($Trust.BrokenCommands.Count) {
            $rec.Add("repair: $($Trust.BrokenCommands -join ', ') → repairterminal · doctor")
        }
        if ($Trust.SelfCheckFails.Count) {
            $rec.Add('selfcheck fail → Import-Module KGreen.Workstation -Force')
        }
    }
    $valFails = [math]::Max($Report.ValidationFails, $Trust.ValidationFails)
    if ($valFails -gt 0) { $rec.Add("doctor — $valFails validation errors") }
    $broken = @($Report.Health | Where-Object { $_.Status -eq 'ERROR' })
    if ($broken.Count) { $rec.Add("fix: $($broken.Name -join ', ') → repairterminal") }
    if ($Report.Backup.DaysAgo -gt 14) { $rec.Add('backupconfig — snapshot stale') }
    if ($Report.Maintenance.DaysSinceMaintenance -gt 7) { $rec.Add('cleanup — maintenance overdue') }
    if ($Report.Performance.DiskFreeGB -lt 15) { $rec.Add('cleanup — disk space low') }
    if ($Report.Score -lt 90 -and $Trust.CanTrustDashboard) { $rec.Add('doctor — full system scan') }

    $hasProblems = (-not $Trust.CanTrustDashboard) -or $Report.ValidationFails -gt 0 -or
        $Trust.WarningCount -gt 0 -or $broken.Count -gt 0 -or $Report.Score -lt 90

    if (-not $hasProblems) {
        $rec.Add('deploy: devstart · projects')
        $rec.Add('intel: sec · menu · komandy')
        $rec.Add('integrity confirmed — trustcheck')
    }

    if (Get-Command Get-SecurityReadinessReport -ErrorAction SilentlyContinue) {
        $sec = Get-SecurityReadinessReport
        if (-not $sec.PgpReady) { $rec.Insert(0, 'sec — PGP: pgp-repair или pgp-setup') }
        if (-not $sec.TorReady) { $rec.Insert(0, 'sec — Tor: tor-setup → tor-harden') }
        elseif (-not $sec.Hardened) { $rec.Insert(0, 'tor-harden — профиль Tor Browser') }
    }

    return @($rec | Select-Object -Unique | Select-Object -First 6)
}

function Get-HomeBaseProductChangelogLines {
    param([int]$MaxBullets = 3)

    $path = Join-Path $script:WSRoot 'CHANGELOG.md'
    if (-not (Test-Path $path)) { return @('CHANGELOG.md не найден') }

    $bullets = [System.Collections.Generic.List[string]]::new()
    $version = $null
    $inRelease = $false

    foreach ($line in (Get-Content -LiteralPath $path)) {
        if ($line -match '^## \[(?!Unreleased)([^\]]+)\]') {
            if ($version) { break }
            $version = $Matches[1].Trim()
            $inRelease = $true
            continue
        }
        if (-not $inRelease) { continue }
        if ($line -match '^## ') { break }
        if ($line -match '^### ') { continue }
        if ($line -match '^- (.+)') {
            $bullets.Add($Matches[1].Trim())
            if ($bullets.Count -ge $MaxBullets) { break }
        }
    }

    if ($version -and $bullets.Count) {
        return @("релиз $version") + @($bullets | ForEach-Object { "· $_" })
    }
    return @('нет записей в CHANGELOG.md')
}

function Show-HomeBase {
    param(
        [switch]$Force,
        [switch]$NoHeal,
        [switch]$SkipTrustProbe,
        [ValidateSet('minimal', 'normal', 'full')][string]$Mode
    )

    if (-not $Force -and $env:WORKSTATION_JARVIS -eq '0') { return }
    if (-not $Force -and $env:WORKSTATION_JARVIS_SHOWN -eq '1') { return }
    if ($env:CI) { return }
    if (-not [Environment]::UserInteractive) { return }

    if (-not $Force) { $env:WORKSTATION_JARVIS_SHOWN = '1' }
    $mode = if ($Mode) { $Mode } elseif ($Force) { 'full' } else {
        $m = ($env:WORKSTATION_STARTUP_MODE ?? '').ToLower().Trim()
        if ($m -in @('minimal', 'normal', 'full')) { $m } else { 'normal' }
    }

    if (-not (Get-Command Build-WocReport -ErrorAction SilentlyContinue)) {
        $wocLib = Join-Path $script:WSRoot 'lib\WorkstationOperationsCenter.ps1'
        if (Test-Path $wocLib) { . $wocLib }
    }

    if (-not (Get-Command Build-WocReport -ErrorAction SilentlyContinue)) {
        Write-HackerLine '[FATAL] WOC offline — repairterminal' -Color Red
        return
    }

    if (Test-HackerUIEnabled) { Write-HackerBootSequence }

    if (Get-Command Invoke-ProfileDriftGuard -ErrorAction SilentlyContinue) {
        Invoke-ProfileDriftGuard | Out-Null
    }
    if (Get-Command Test-PostRebootSession -ErrorAction SilentlyContinue) {
        if (Test-PostRebootSession) { Show-PostRebootChecklist }
    }

    $cached = Get-TrustReportFromCache
    $trust = if ($SkipTrustProbe -and $cached -and $cached.AgeMinutes -le 15) {
        [PSCustomObject]$cached.Report
    } else {
        if (Get-Command Save-CommandHealthCache -ErrorAction SilentlyContinue) {
            $healthPath = Join-Path (Get-WorkstationLogsRoot) 'command-health.json'
            if (-not (Test-Path $healthPath)) { Save-CommandHealthCache }
        }
        Get-SystemTrustReport -Live -Save
    }

    $report = Build-WocReport

    if (-not $NoHeal -and (Get-Command Invoke-WocSelfHeal -ErrorAction SilentlyContinue)) {
        $healed = Invoke-WocSelfHeal -Report $report
        if ($healed.Count) {
            Write-HackerLine "[HEAL] auto-recovery: $($healed -join ', ')" -Color DarkCyan
            $report = Build-WocReport
            $trust = Get-SystemTrustReport -Live -Save
        }
    }

    $honestScore = [math]::Min($report.Score, $trust.Score)
    $scoreLabel = Get-HomeBaseScoreLabelRu -Score $honestScore
    $liveWarnings = [math]::Max($trust.WarningCount, $report.WarningCount)
    $recommendations = Get-HomeBaseRecommendationsRu -Report $report -Trust $trust

    $okItems = @($report.Health | Where-Object { $_.Status -eq 'OK' })
    $warnItems = @($report.Health | Where-Object { $_.Status -eq 'WARNING' })
    $errItems = @($report.Health | Where-Object { $_.Status -eq 'ERROR' })

    if ($trust.BrokenCommands.Count) {
        foreach ($bc in $trust.BrokenCommands) {
            if (-not ($errItems.Name -contains "Command $bc")) {
                $errItems += [PSCustomObject]@{ Name = "Command $bc"; Status = 'ERROR'; Detail = 'trust probe' }
            }
        }
    }

    $P = Get-HackerPalette
    $HT = Get-HackerTexts

    # ── Banner ──────────────────────────────────────────────────────────────
    Write-HackerBanner -TrustScore $trust.Score -HealthScore $honestScore -TrustLevel $trust.Level

    Write-HackerLine $HT.WelcomeRu -Color $P.Cyan
    Write-HackerLine ($HT.SessionLine -f (Get-Date -Format 'dd.MM.yyyy HH:mm:ss'), $PWD) -Color $P.Muted
    Write-Host ''

    Show-HackerTrustPanel -Trust $trust

    if (-not $trust.CanTrustDashboard) {
        Write-HackerLine $HT.Compromised -Color $P.Alert
        Write-Host ''
    }

    # ── System telemetry ────────────────────────────────────────────────────
    Write-HackerSection -Tag 'SYS' -Title 'TELEMETRY — состояние системы' -Color $P.Cyan
    Write-HackerStat 'HEALTH' (Format-HackerBar -Percent $honestScore -Label $scoreLabel) -Color $(if ($honestScore -ge 90 -and $trust.CanTrustDashboard) { $P.TrustOk } elseif ($honestScore -ge 70) { $P.Warn } else { $P.Alert })
    Write-HackerStat 'VALIDATE' "$([math]::Max($report.ValidationFails, $trust.ValidationFails)) errors" -Color $(if ($report.ValidationFails -eq 0 -and $trust.ValidationFails -eq 0) { $P.TrustOk } else { $P.Alert })
    Write-HackerStat 'WARNINGS' "$liveWarnings live" -Color $(if ($liveWarnings -eq 0 -and $trust.CanTrustDashboard) { $P.TrustOk } else { $P.Warn })
    Write-HackerStat 'BROKEN' "$($trust.BrokenCommands.Count) commands" -Color $(if ($trust.BrokenCommands.Count -eq 0) { $P.TrustOk } else { $P.Alert })
    Write-HackerStat 'DISK C:' (Format-HackerBar -Percent $report.Performance.DiskFreePct -Label "$($report.Performance.DiskFreeGB) GB free") -Color $P.Muted
    if ($report.Network.LocalIP) {
        Write-HackerStat 'NET IP' "$($report.Network.LocalIP) / $($report.Network.PublicIP)" -Color $P.Muted
    }
    Write-Host ''

    # ── Subsystems ──────────────────────────────────────────────────────────
    Write-HackerSection -Tag 'SUB' -Title 'SUBSYSTEMS — что работает' -Color $P.TrustOk
    if ($trust.CanTrustDashboard -and $okItems.Count) {
        $okItems | Select-Object -First 10 | ForEach-Object {
            Write-HackerStatusRow -Icon '++' -Name $_.Name -Status 'OK' -Detail $_.Detail
        }
        if ($okItems.Count -gt 10) {
            Write-HackerLine "... +$($okItems.Count - 10) more" -Color $P.Muted
        }
    } else {
        Write-HackerLine '[--] no verified data — trustcheck first' -Color $P.Muted
    }
    Write-Host ''

    if ($warnItems.Count -or ($trust.Issues.Count -and -not $trust.CanTrustDashboard)) {
        Write-HackerSection -Tag 'WARN' -Title 'ANOMALIES — требует внимания' -Color $P.Warn
        $warnItems | ForEach-Object { Write-HackerStatusRow -Icon '!!' -Name $_.Name -Status 'WARNING' -Detail $_.Detail }
        if (-not $trust.CanTrustDashboard) {
            $trust.Issues | Select-Object -First 5 | ForEach-Object { Write-HackerLine "[!!] $_" -Color $P.Warn }
        }
        Write-Host ''
    }

    if ($errItems.Count) {
        Write-HackerSection -Tag 'ERR' -Title 'CRITICAL — сломано' -Color $P.Alert
        $errItems | ForEach-Object { Write-HackerStatusRow -Icon 'XX' -Name $_.Name -Status 'ERROR' -Detail $_.Detail }
        Write-Host ''
    }

    Show-HackerRecommendations -Items $recommendations

    if ($mode -ne 'minimal' -and (Get-Command Show-SecurityStatusPanel -ErrorAction SilentlyContinue)) {
        Show-SecurityStatusPanel
    }

    if ($mode -eq 'minimal') {
        Show-HackerFooter -Mode 'minimal'
        if (Get-Command Save-WocSessionState -ErrorAction SilentlyContinue) {
            $report.Score = $honestScore
            $report.WarningCount = $liveWarnings
            Save-WocSessionState -Report $report
        }
        return
    }

    Write-HackerSection -Tag 'LOG' -Title 'CHANGELOG — продукт и сессия' -Color $P.Accent
    foreach ($line in (Get-HomeBaseProductChangelogLines)) {
        Write-HackerLine "· $line" -Color $P.Muted
    }
    if ($report.Changes -and $report.Changes.Count) {
        Write-HackerLine '— с прошлой сессии —' -Color $P.Muted
        $report.Changes | Select-Object -First 3 | ForEach-Object { Write-HackerLine "· $_" -Color $P.Muted }
    }
    Write-Host ''

    Show-HackerCommandMatrix

    if ($mode -eq 'normal') {
        Show-HackerFooter -Mode 'normal'
        if (Get-Command Save-WocSessionState -ErrorAction SilentlyContinue) {
            $report.Score = $honestScore
            Save-WocSessionState -Report $report
        }
        return
    }

    # full
    Show-HackerToolsGrid -Inventory (Get-WorkstationToolInventory)
    Show-CommandGroupsRu

    Write-HackerSection -Tag 'NET' -Title 'NETWORK INTEL' -Color $P.Cyan
    Write-HackerStat 'ADAPTER' "$($report.Network.Adapter) ($($report.Network.Connectivity))" -Color $P.Muted
    Write-HackerStat 'GATEWAY' $report.Network.Gateway -Color $P.Muted
    Write-HackerStat 'DNS' $report.Network.DNS -Color $P.Muted
    Write-HackerStat 'BACKUP' "$($report.Backup.Latest ?? 'none') ($($report.Backup.DaysAgo ?? '—')d)" -Color $P.Muted
    Write-Host ''

    Show-HackerFooter -Mode 'full'

    if (Get-Command Save-WocSessionState -ErrorAction SilentlyContinue) {
        $report.Score = $honestScore
        Save-WocSessionState -Report $report
    }
}
