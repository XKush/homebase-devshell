# DevShell Health — unified readiness dashboard (v3)
# C:\Scripts\Workstation\lib\DevShellHealth.ps1

function Get-DevShellHealthPaths {
    param([string]$RepoRoot)
    $homeBase = Join-Path $env:USERPROFILE '.homebase'
    $logs = if (Get-Command Get-WorkstationLogsRoot -ErrorAction SilentlyContinue) {
        Get-WorkstationLogsRoot
    } else {
        'C:\Logs\Workstation'
    }
    [PSCustomObject]@{
        Baseline     = Join-Path $homeBase 'baseline.json'
        History      = Join-Path $logs 'health-history.jsonl'
        HtmlTemplate = Join-Path $RepoRoot 'docs\templates\health-report.html'
    }
}

function Get-DevShellSectionStatus {
    param(
        [int]$FailCount,
        [int]$WarnCount,
        [string]$ScoreLabel = $null
    )
    if ($FailCount -gt 0) { return 'FAIL' }
    if ($ScoreLabel) { return $ScoreLabel }
    if ($WarnCount -gt 0) { return 'WARN' }
    return 'PASS'
}

function Invoke-DevShellDoctorJson {
    param(
        [string]$RepoRoot,
        [ValidateSet('Core', 'Full')]
        [string]$Tier = 'Core'
    )
    $logs = if (Get-Command Get-WorkstationLogsRoot -ErrorAction SilentlyContinue) {
        Get-WorkstationLogsRoot
    } else {
        Join-Path $RepoRoot '..\..\Logs\Workstation'
    }
    if (-not (Test-Path $logs)) { New-Item -ItemType Directory -Force -Path $logs | Out-Null }
    $scriptPath = Join-Path $RepoRoot 'scripts\maintainer\install\Validate-Workstation.ps1'
    $null = & $scriptPath -Tier $Tier -JsonOnly *> $null
    $latest = Get-ChildItem $logs -Filter 'validation-*.json' -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if (-not $latest) { return $null }
    try { return Get-Content $latest.FullName -Raw | ConvertFrom-Json } catch { return $null }
}

function Get-DevShellHealthReport {
    param(
        [Parameter(Mandatory)][string]$RepoRoot,
        [ValidateSet('Core', 'Full')]
        [string]$Tier = 'Core',
        [string]$ProductVersion = '3.0.0'
    )

    . (Join-Path $RepoRoot 'lib\PrivacyAudit.ps1')

    $doctor = Invoke-DevShellDoctorJson -RepoRoot $RepoRoot -Tier $Tier
    $privacy = Get-PrivacyAuditReport -Scope System -RepoRoot $RepoRoot -ProductVersion $ProductVersion
    $browser = Get-PrivacyAuditReport -Scope Browser -RepoRoot $RepoRoot -ProductVersion $ProductVersion
    $network = Get-PrivacyAuditReport -Scope Vpn -RepoRoot $RepoRoot -ProductVersion $ProductVersion

    $devFail = if ($doctor) { @($doctor.Failed).Count } else { 1 }
    $devWarn = if ($doctor) { @($doctor.Warnings).Count } else { 0 }
    $devPass = if ($doctor) { @($doctor.Passed).Count } else { 0 }

    $privacyDoc = ConvertTo-PrivacyReportDocument -Report $privacy -ProductVersion $ProductVersion -Context $privacy.Context

    $sections = [ordered]@{
        developer = [ordered]@{
            id          = 'developer'
            label       = 'Developer'
            status      = Get-DevShellSectionStatus -FailCount $devFail -WarnCount $devWarn
            passed      = $devPass
            failed      = $devFail
            warnings    = $devWarn
            tier        = $Tier
            detail      = if ($devFail -eq 0) { 'Shell, tools, profile checks' } else { (@($doctor.Failed) | Select-Object -First 2) -join '; ' }
        }
        privacyConfiguration = [ordered]@{
            id          = 'privacyConfiguration'
            label       = 'Privacy Configuration'
            status      = Get-DevShellSectionStatus -FailCount $privacy.FailCount -WarnCount $privacy.WarnCount -ScoreLabel "$($privacy.Score)%"
            score       = $privacy.Score
            maxScore    = $privacyDoc.score.max
            riskLevel   = $privacy.RiskLevel
            disclaimer  = 'OS configuration only. Does not measure network anonymity.'
            warnings    = $privacy.WarnCount
            failed      = $privacy.FailCount
        }
        browserConfiguration = [ordered]@{
            id       = 'browserConfiguration'
            label    = 'Browser Configuration'
            status   = Get-DevShellSectionStatus -FailCount $browser.FailCount -WarnCount $browser.WarnCount -ScoreLabel "$($browser.Score)%"
            score    = $browser.Score
            warnings = $browser.WarnCount
            detail   = 'Policy and prefs audit — not a full browser security review.'
        }
        network = [ordered]@{
            id       = 'network'
            label    = 'Network'
            status   = Get-DevShellSectionStatus -FailCount $network.FailCount -WarnCount $network.WarnCount
            score    = $network.Score
            warnings = $network.WarnCount
            detail   = 'VPN/TUN/DNS heuristics — offline, no leak test to external sites.'
        }
    }

    $ready = ($devFail -eq 0) -and ($privacy.FailCount -eq 0)
    $message = if ($ready) { 'Ready to work.' } else { 'Not ready yet.' }

    [PSCustomObject]@{
        healthSchemaVersion = '1.0.0'
        productVersion      = $ProductVersion
        timestamp           = (Get-Date).ToString('o')
        philosophy          = 'HomeBase DevShell prepares, verifies and maintains professional Windows workstations.'
        tier                = $Tier
        sections            = $sections
        privacyReport       = $privacyDoc
        browserReport       = (ConvertTo-PrivacyReportDocument -Report $browser -ProductVersion $ProductVersion -Context $browser.Context)
        networkReport       = (ConvertTo-PrivacyReportDocument -Report $network -ProductVersion $ProductVersion -Context $network.Context)
        doctorReport        = $doctor
        summary             = [ordered]@{
            ready   = $ready
            message = $message
        }
    }
}

function Write-DevShellHealthDashboard {
    param([Parameter(Mandatory)]$Report)

    Write-Host ''
    Write-Host 'HomeBase DevShell' -ForegroundColor Cyan
    Write-Host $Report.philosophy -ForegroundColor DarkGray
    Write-Host ''

    foreach ($key in $Report.sections.Keys) {
        $s = $Report.sections[$key]
        $col = switch ($s.status) {
            'PASS' { 'Green' }
            'FAIL' { 'Red' }
            { $_ -match '%' } { if ([int]($s.status -replace '%','') -ge 85) { 'Green' } elseif ([int]($s.status -replace '%','') -ge 65) { 'Yellow' } else { 'Red' } }
            'WARN' { 'Yellow' }
            default { 'DarkGray' }
        }
        $line = if ($s.status -match '%') { "$($s.label.PadRight(22)) $($s.status)" } else { "$($s.label.PadRight(22)) $($s.status)" }
        Write-Host $line -ForegroundColor $col
        if ($s.disclaimer) {
            Write-Host "  $($s.disclaimer)" -ForegroundColor DarkGray
        }
    }

    Write-Host ''
    Write-Host 'Summary' -ForegroundColor Cyan
    $sumCol = if ($Report.summary.ready) { 'Green' } else { 'Yellow' }
    Write-Host $Report.summary.message -ForegroundColor $sumCol
    Write-Host ''
}

function Save-DevShellHealthHistory {
    param(
        [Parameter(Mandatory)]$Report,
        [string]$HistoryPath
    )
    if (-not $HistoryPath) {
        $HistoryPath = (Get-DevShellHealthPaths -RepoRoot $env:HOMEBASE_DEVSHELL_ROOT).History
    }
    $dir = Split-Path $HistoryPath -Parent
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
    $row = [ordered]@{
        timestamp = $Report.timestamp
        developer = $Report.sections.developer.status
        privacy   = $Report.sections.privacyConfiguration.score
        browser   = $Report.sections.browserConfiguration.score
        network   = $Report.sections.network.status
        ready     = $Report.summary.ready
    }
    ($row | ConvertTo-Json -Compress) | Add-Content -Path $HistoryPath -Encoding UTF8
}

function Show-DevShellHealthHistory {
    param([string]$HistoryPath, [int]$Last = 15)
    if (-not $HistoryPath) {
        $HistoryPath = (Get-DevShellHealthPaths -RepoRoot $env:HOMEBASE_DEVSHELL_ROOT).History
    }
    if (-not (Test-Path $HistoryPath)) {
        Write-Host 'No health history yet. Run: devshell health' -ForegroundColor DarkGray
        return
    }
    $rows = Get-Content $HistoryPath -Encoding UTF8 | ForEach-Object { $_ | ConvertFrom-Json }
    Write-Host ''
    Write-Host 'Health history' -ForegroundColor Cyan
    Write-Host ''
    $slice = if ($rows.Count -gt $Last) { $rows[($rows.Count - $Last)..($rows.Count - 1)] } else { $rows }
    foreach ($r in $slice) {
        $d = ([datetime]$r.timestamp).ToString('MMM dd')
        Write-Host ("{0,-8} Privacy {1,3}%  Developer {2,-4}  Ready {3}" -f $d, $r.privacy, $r.developer, $(if ($r.ready) { 'yes' } else { 'no' })) -ForegroundColor DarkGray
    }
    Write-Host ''
}

function Save-DevShellHealthBaseline {
    param(
        [Parameter(Mandatory)]$Report,
        [string]$BaselinePath
    )
    if (-not $BaselinePath) {
        $BaselinePath = (Get-DevShellHealthPaths -RepoRoot $env:HOMEBASE_DEVSHELL_ROOT).Baseline
    }
    $dir = Split-Path $BaselinePath -Parent
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
    $Report | ConvertTo-Json -Depth 12 | Set-Content $BaselinePath -Encoding UTF8
    Write-Host "Baseline saved: $BaselinePath" -ForegroundColor DarkGray
}

function Compare-DevShellHealthBaseline {
    param(
        [Parameter(Mandatory)]$Current,
        [string]$BaselinePath
    )
    if (-not $BaselinePath) {
        $BaselinePath = (Get-DevShellHealthPaths -RepoRoot $env:HOMEBASE_DEVSHELL_ROOT).Baseline
    }
    if (-not (Test-Path $BaselinePath)) {
        Write-Host 'No baseline. Run: devshell baseline' -ForegroundColor Yellow
        return $null
    }
    $base = Get-Content $BaselinePath -Raw | ConvertFrom-Json
    $changes = [System.Collections.Generic.List[string]]::new()

    foreach ($key in $Current.sections.Keys) {
        $c = $Current.sections[$key]
        $b = $base.sections.$key
        if (-not $b) { $changes.Add("$($c.label): new section"); continue }
        $cStat = if ($c.score) { "$($c.score)" } else { $c.status }
        $bStat = if ($b.score) { "$($b.score)" } else { $b.status }
        if ($cStat -ne $bStat) {
            $changes.Add("$($c.label): $bStat → $cStat")
        }
    }

    if ($Current.privacyReport -and $base.privacyReport) {
        $baseChecks = @{}
        foreach ($chk in $base.privacyReport.checks) { $baseChecks[$chk.id] = $chk.status }
        foreach ($chk in $Current.privacyReport.checks) {
            $old = $baseChecks[$chk.id]
            if ($old -and $old -ne $chk.status) {
                $changes.Add("Privacy check $($chk.id): $old → $($chk.status)")
            }
        }
    }

    [PSCustomObject]@{
        baselineTimestamp = $base.timestamp
        currentTimestamp  = $Current.timestamp
        changes           = @($changes)
        driftDetected     = ($changes.Count -gt 0)
    }
}

function Export-DevShellHealthHtml {
    param(
        [Parameter(Mandatory)]$Report,
        [Parameter(Mandatory)][string]$OutPath
    )
    $esc = { param($t) if ($null -eq $t) { return '' }; [System.Net.WebUtility]::HtmlEncode([string]$t) }

    $sectionRows = ''
    foreach ($key in $Report.sections.Keys) {
        $s = $Report.sections[$key]
        $badge = & $esc $s.status
        $sectionRows += @"
    <div class="card">
      <div class="card-head"><span>$( & $esc $s.label )</span><span class="badge">$badge</span></div>
      $(if ($s.disclaimer) { "<p class='muted'>$( & $esc $s.disclaimer )</p>" } else { '' })
      $(if ($s.detail) { "<p class='muted'>$( & $esc $s.detail )</p>" } else { '' })
    </div>
"@
    }

    $readyClass = if ($Report.summary.ready) { 'ok' } else { 'warn' }
    $html = @"
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8"/>
  <title>HomeBase DevShell Health Report</title>
  <style>
    :root { --bg:#0d1117; --card:#161b22; --border:#30363d; --text:#e6edf3; --muted:#8b949e; --ok:#3fb950; --warn:#d29922; }
    body { font-family:Segoe UI,system-ui,sans-serif; background:var(--bg); color:var(--text); margin:0; padding:2rem; }
    h1 { font-size:1.5rem; margin:0 0 .25rem; }
    .sub { color:var(--muted); font-size:.9rem; margin-bottom:1.5rem; }
    .grid { display:grid; gap:1rem; max-width:720px; }
    .card { background:var(--card); border:1px solid var(--border); border-radius:8px; padding:1rem 1.25rem; }
    .card-head { display:flex; justify-content:space-between; font-weight:600; margin-bottom:.5rem; }
    .badge { font-size:.85rem; padding:.15rem .5rem; border-radius:4px; background:#21262d; }
    .muted { color:var(--muted); font-size:.85rem; margin:.25rem 0 0; }
    .summary { margin-top:1.5rem; padding:1rem; border-radius:8px; border:1px solid var(--border); }
    .summary.$readyClass { border-color:var(--$readyClass); }
  </style>
</head>
<body>
  <h1>HomeBase DevShell</h1>
  <p class="sub">$( & $esc $Report.philosophy )<br/>$( & $esc $Report.timestamp )</p>
  <div class="grid">$sectionRows</div>
  <div class="summary $readyClass"><strong>Summary:</strong> $( & $esc $Report.summary.message )</div>
</body>
</html>
"@
    $dir = Split-Path $OutPath -Parent
    if ($dir -and -not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
    $html | Set-Content $OutPath -Encoding UTF8
    Write-Host "HTML report: $OutPath" -ForegroundColor DarkGray
}
