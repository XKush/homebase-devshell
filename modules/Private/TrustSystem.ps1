# Режим доверия — HOME BASE не может врать

$script:TrustReportPath = 'C:\Logs\Workstation\trust-report.json'
$script:TrustMaxCacheMin = 15

function Get-TrustMode {
    $m = ($env:WORKSTATION_TRUST_MODE ?? 'strict').ToLower().Trim()
    if ($m -in @('strict', 'normal', 'fast')) { return $m }
    return 'strict'
}

function Save-TrustReport {
    param([Parameter(Mandatory)]$Report)
    $dir = Split-Path $script:TrustReportPath -Parent
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
    $Report | ConvertTo-Json -Depth 8 | Set-Content $script:TrustReportPath -Encoding UTF8
}

function Get-TrustReportFromCache {
    if (-not (Test-Path $script:TrustReportPath)) { return $null }
    try {
        $r = Get-Content $script:TrustReportPath -Raw | ConvertFrom-Json
        $age = ((Get-Date) - [datetime]$r.Timestamp).TotalMinutes
        return [PSCustomObject]@{ Report = $r; AgeMinutes = [math]::Round($age, 1) }
    } catch { return $null }
}

function Get-SystemTrustReport {
    param(
        [switch]$Live,
        [switch]$Save,
        [int]$MaxCacheMinutes = 15
    )

    $mode = Get-TrustMode
    $cached = Get-TrustReportFromCache

    if (-not $Live) {
        if ($mode -eq 'fast' -and $cached -and $cached.AgeMinutes -le $MaxCacheMinutes) {
            return [PSCustomObject]$cached.Report
        }
        if ($mode -eq 'normal' -and $cached -and $cached.AgeMinutes -le $MaxCacheMinutes) {
            return [PSCustomObject]$cached.Report
        }
    }

    if (-not $Live -and $mode -ne 'strict' -and $cached) {
        $r = [PSCustomObject]$cached.Report
        $r | Add-Member -NotePropertyName IsStale -NotePropertyValue ($cached.AgeMinutes -gt $MaxCacheMinutes) -Force
        return $r
    }

    # ── Live probe ──────────────────────────────────────────────────────────
    $sw = [Diagnostics.Stopwatch]::StartNew()
    $issues = [System.Collections.Generic.List[string]]::new()

    # Модуль
    $modOk = [bool](Get-Module KGreen.Workstation)
    if (-not $modOk) { $issues.Add((Get-TrustMessage 'ModuleMissing')) }

    # Самопроверки всех команд
    $selfChecks = Invoke-AllCommandSelfChecks
    $selfFails = @($selfChecks | Where-Object { -not $_.OK })
    if ($selfFails.Count) {
        $issues.Add((Get-TrustMessage 'SelfCheckFail' -Detail ($selfFails.Command -join ', ')))
    }

    # Inventory команд
    $cmdHealth = Get-WorkstationCommandHealth
    $broken = @($cmdHealth | Where-Object { $_.Status -eq 'BROKEN' })
    $noHelp = @($cmdHealth | Where-Object { $_.Status -eq 'NO_HELP' })
    if ($broken.Count) {
        $issues.Add((Get-TrustMessage 'CommandBroken' -Detail ($broken.Name -join ', ')))
    }
    if ($noHelp.Count) {
        $issues.Add("Без -help: $($noHelp.Name -join ', ')")
    }

    # Профиль
    $canon = Join-Path $script:WSRoot 'profile\Microsoft.PowerShell_profile.ps1'
    $liveProfilePath = Join-Path $env:USERPROFILE 'Documents\PowerShell\Microsoft.PowerShell_profile.ps1'
    $profileOk = $false
    if ((Test-Path $canon) -and (Test-Path $liveProfilePath)) {
        $profileOk = (Get-FileHash $canon).Hash -eq (Get-FileHash $liveProfilePath).Hash
    }
    if (-not $profileOk) { $issues.Add((Get-TrustMessage 'ProfileDrift')) }

    # command-health.json
    $healthPath = 'C:\Logs\Workstation\command-health.json'
    $healthAge = $null
    $execFailures = 0
    if (Test-Path $healthPath) {
        $healthAge = [math]::Round(((Get-Date) - (Get-Item $healthPath).LastWriteTime).TotalMinutes, 1)
        if ($healthAge -gt $MaxCacheMinutes) {
            $issues.Add((Get-TrustMessage 'HealthStale' -Detail $healthAge))
        }
        try {
            $h = Get-Content $healthPath -Raw | ConvertFrom-Json
            if ($h.ExecuteFailures -gt 0) { $execFailures = $h.ExecuteFailures; $issues.Add("Exec failures: $execFailures") }
            if ($h.Broken -gt 0) { $issues.Add("Health report: $($h.Broken) broken") }
        } catch { $issues.Add('command-health.json не читается') }
    } else {
        $issues.Add('command-health.json отсутствует — Test-WorkstationCommands')
    }

    # validation json
    $valFail = 0
    $val = Get-ChildItem 'C:\Logs\Workstation' -Filter 'validation-*.json' -EA SilentlyContinue |
        Sort-Object Name -Descending | Select-Object -First 1
    if ($val) {
        try {
            $vj = Get-Content $val.FullName -Raw | ConvertFrom-Json
            $valFail = if ($vj.Metrics.FailCount) { $vj.Metrics.FailCount } elseif ($vj.Failed) { $vj.Failed } else { 0 }
            if ($valFail -gt 0) { $issues.Add((Get-TrustMessage 'ValidationFail' -Detail $valFail)) }
        } catch { }
    }

    # Score
    $score = 100
    $score -= $broken.Count * 12
    $score -= $selfFails.Count * 10
    $score -= $noHelp.Count * 3
    if (-not $profileOk) { $score -= 8 }
    if (-not $modOk) { $score -= 20 }
    $score -= $valFail * 5
    $score -= $execFailures * 8
    if ($healthAge -and $healthAge -gt $MaxCacheMinutes) { $score -= 6 }
    $score = [math]::Max(0, [math]::Min(100, $score))

    # Level
    $level = if ($broken.Count -gt 0 -or $selfFails.Count -gt 0 -or -not $modOk) {
        'UNTRUSTED'
    } elseif ($issues.Count -gt 0) {
        if ($healthAge -and $healthAge -gt $MaxCacheMinutes) { 'STALE' } else { 'DEGRADED' }
    } else {
        'VERIFIED'
    }

    $sw.Stop()

    $report = [PSCustomObject][ordered]@{
        Timestamp         = (Get-Date).ToString('o')
        Level             = $level
        TrustMode         = $mode
        Score             = $score
        CanTrustDashboard = ($broken.Count -eq 0 -and $selfFails.Count -eq 0 -and $modOk)
        LiveProbe         = $true
        ProbeDurationMs   = $sw.ElapsedMilliseconds
        BrokenCommands    = @($broken | ForEach-Object { $_.Name })
        SelfCheckFails    = @($selfFails | ForEach-Object { [ordered]@{ Command = $_.Command; Detail = $_.Detail } })
        NoHelpCommands    = @($noHelp | ForEach-Object { $_.Name })
        WarningCount      = $issues.Count
        ValidationFails   = $valFail
        ExecuteFailures   = $execFailures
        ProfileSynced     = $profileOk
        ModuleLoaded      = $modOk
        HealthCacheAgeMin = $healthAge
        Issues            = @($issues)
        SelfChecksPassed  = @($selfChecks | Where-Object { $_.OK }).Count
        SelfChecksTotal   = $selfChecks.Count
    }

    if ($Save) { Save-TrustReport -Report $report }
    return $report
}

function Show-TrustReport {
    param($Trust)

    if (-not $Trust) { $Trust = Get-SystemTrustReport -Live -Save }

    if (Test-HackerUIEnabled) {
        Show-HackerTrustPanel -Trust $Trust
        $P = Get-HackerPalette
        Write-HackerStat 'TIMESTAMP' ([datetime]$Trust.Timestamp).ToString('dd.MM.yyyy HH:mm:ss') -Color $P.Muted
        Write-Host ''
        return
    }

    $lvl = Get-TrustLevelRu -Level $Trust.Level
    $T = Get-HomeBaseTexts

    Write-Host ''
    Write-Host "  $($T.SectionTrust)" -ForegroundColor Cyan
    Write-Host '  ──────────────────────────────────────────────────────────' -ForegroundColor DarkGray
    Write-Host ("  Уровень:     {0}" -f $lvl.Text) -ForegroundColor $lvl.Color
    Write-Host ("  Оценка:      {0}/100" -f $Trust.Score) -ForegroundColor $(if ($Trust.Score -ge 90) { 'Green' } elseif ($Trust.Score -ge 70) { 'Yellow' } else { 'Red' })
    Write-Host ("  Режим:       {0}" -f $Trust.TrustMode) -ForegroundColor DarkGray
    Write-Host ("  Live-probe:  {0} ({1} ms)" -f $Trust.LiveProbe, $Trust.ProbeDurationMs) -ForegroundColor DarkGray
    Write-Host ("  Самопроверки:{0}/{1} OK" -f $Trust.SelfChecksPassed, $Trust.SelfChecksTotal) -ForegroundColor $(if ($Trust.SelfChecksPassed -eq $Trust.SelfChecksTotal) { 'Green' } else { 'Red' })
    Write-Host ("  Можно верить панели: {0}" -f $(if ($Trust.CanTrustDashboard) { 'ДА' } else { 'НЕТ — исправьте проблемы' })) -ForegroundColor $(if ($Trust.CanTrustDashboard) { 'Green' } else { 'Red' })

    if ($Trust.BrokenCommands.Count) {
        Write-Host ("  Сломано:     {0}" -f ($Trust.BrokenCommands -join ', ')) -ForegroundColor Red
    }
    if ($Trust.Issues.Count) {
        Write-Host '  Замечания:' -ForegroundColor Yellow
        $Trust.Issues | Select-Object -First 8 | ForEach-Object { Write-Host "    · $_" -ForegroundColor DarkGray }
    }
    Write-Host ("  Проверено:   {0}" -f ([datetime]$Trust.Timestamp).ToString('dd.MM.yyyy HH:mm:ss')) -ForegroundColor DarkGray
    Write-Host ''
}

function trustcheck {
    param([switch]$Help)
    if (Test-ShowCommandHelp -Name 'trustcheck' -Help:$Help) { return }
    Invoke-WorkstationCmd 'trustcheck' -SkipSelfCheck {
        Write-Host "`n  Проверка доверия к системе (live)...`n" -ForegroundColor Cyan
        $t = Get-SystemTrustReport -Live -Save
        if (Get-Command Add-TrustChainBlock -ErrorAction SilentlyContinue) {
            Add-TrustChainBlock -TrustReport $t -Event 'trustcheck' | Out-Null
        }
        Show-TrustReport -Trust $t
        if (-not $t.CanTrustDashboard) {
            Write-Host '  ⚠ HOME BASE не будет скрывать проблемы. Выполните doctor или repairterminal.' -ForegroundColor Yellow
        } else {
            Write-Host '  ✓ Система прошла live-проверку. Панель home показывает правду.' -ForegroundColor Green
        }
        Write-Host ''
    }
}

function Update-TrustCache {
    Get-SystemTrustReport -Live -Save | Out-Null
}
