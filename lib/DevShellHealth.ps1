# DevShell Health — unified readiness dashboard (v3)
# C:\Scripts\Workstation\lib\DevShellHealth.ps1

$script:DevShellHealthAllSections = @(
    'developer'
    'privacyConfiguration'
    'browserConfiguration'
    'network'
)

$script:DevShellHealthSectionAliases = @{
    developer            = 'developer'
    dev                  = 'developer'
    privacy              = 'privacyConfiguration'
    privacyconfiguration = 'privacyConfiguration'
    browser              = 'browserConfiguration'
    browserconfiguration = 'browserConfiguration'
    network              = 'network'
    net                  = 'network'
}

function Get-DevShellHealthLogsRoot {
    param([string]$RepoRoot)
    if (Get-Command Get-WorkstationLogsRoot -ErrorAction SilentlyContinue) {
        return Get-WorkstationLogsRoot
    }
    if ($RepoRoot) {
        return (Join-Path $RepoRoot '..\..\Logs\Workstation')
    }
    return 'C:\Logs\Workstation'
}

function Initialize-DevShellParentDirectory {
    param([Parameter(Mandatory)][string]$FilePath)
    $dir = [System.IO.Path]::GetDirectoryName($FilePath)
    if ($dir -and -not (Test-Path -LiteralPath $dir)) {
        $null = New-Item -ItemType Directory -Force -Path $dir
    }
}

function Get-DevShellHealthPaths {
    param([string]$RepoRoot)
    $homeBase = Join-Path $env:USERPROFILE '.homebase'
    $logs = Get-DevShellHealthLogsRoot -RepoRoot $RepoRoot
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
        [string]$ScoreLabel
    )
    if ($FailCount -gt 0) { return 'FAIL' }
    if ($ScoreLabel) { return $ScoreLabel }
    if ($WarnCount -gt 0) { return 'WARN' }
    return 'PASS'
}

function Invoke-DevShellDoctorJson {
    param(
        [Parameter(Mandatory)][string]$RepoRoot,
        [ValidateSet('Core', 'Full')]
        [string]$Tier = 'Core'
    )
    $logs = Get-DevShellHealthLogsRoot -RepoRoot $RepoRoot
    if (-not (Test-Path -LiteralPath $logs)) {
        $null = New-Item -ItemType Directory -Force -Path $logs
    }
    $scriptPath = Join-Path $RepoRoot 'scripts\maintainer\install\Validate-Workstation.ps1'
    if (-not (Test-Path -LiteralPath $scriptPath)) { return $null }
    $null = & $scriptPath -Tier $Tier -JsonOnly *> $null
    $latest = Get-ChildItem -LiteralPath $logs -Filter 'validation-*.json' -File -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1
    if (-not $latest) { return $null }
    try {
        return Get-Content -LiteralPath $latest.FullName -Raw -Encoding UTF8 | ConvertFrom-Json
    } catch {
        return $null
    }
}

function Resolve-DevShellHealthSectionKeys {
    param([string[]]$Sections)
    if (-not $Sections -or $Sections.Count -eq 0) {
        return $script:DevShellHealthAllSections
    }
    $selected = [System.Collections.Generic.HashSet[string]]::new(
        [StringComparer]::Ordinal
    )
    foreach ($s in $Sections) {
        foreach ($part in ($s -split '[,;]')) {
            $token = $part.Trim().ToLowerInvariant()
            if ([string]::IsNullOrWhiteSpace($token)) { continue }
            $canonical = $script:DevShellHealthSectionAliases[$token]
            if ($canonical) { [void]$selected.Add($canonical) }
        }
    }
    if ($selected.Count -eq 0) {
        return $script:DevShellHealthAllSections
    }
    return @($selected)
}

function New-DevShellScoredPrivacySection {
    param(
        [Parameter(Mandatory)][string]$Id,
        [Parameter(Mandatory)][string]$Label,
        [Parameter(Mandatory)]$Audit,
        [Parameter(Mandatory)]$Document,
        [string]$Disclaimer,
        [string]$Detail
    )
    $entry = [ordered]@{
        id       = $Id
        label    = $Label
        status   = Get-DevShellSectionStatus -FailCount $Audit.FailCount -WarnCount $Audit.WarnCount -ScoreLabel "$($Audit.Score)%"
        score    = $Audit.Score
        warnings = $Audit.WarnCount
        failed   = $Audit.FailCount
    }
    if ($Disclaimer) { $entry.disclaimer = $Disclaimer }
    if ($Detail) { $entry.detail = $Detail }
    if ($Document -and $Document.score) { $entry.maxScore = $Document.score.max }
    if ($Audit.RiskLevel) { $entry.riskLevel = $Audit.RiskLevel }
    return $entry
}

function Get-DevShellListCount {
    param($Value)
    if ($null -eq $Value) { return 0 }
    return @($Value).Count
}

function Get-DevShellPrivacyReportDocument {
    param(
        [Parameter(Mandatory)]$Report,
        [Parameter(Mandatory)][string]$ProductVersion
    )
    if (-not $Report) { return $null }
    return ConvertTo-PrivacyReportDocument -Report $Report -ProductVersion $ProductVersion -Context $Report.Context
}

function Get-DevShellHealthReport {
    param(
        [Parameter(Mandatory)][string]$RepoRoot,
        [ValidateSet('Core', 'Full')]
        [string]$Tier = 'Core',
        [string]$ProductVersion = '3.1.0',
        [string[]]$SectionFilter
    )

    $requested = @(Resolve-DevShellHealthSectionKeys -Sections $SectionFilter)
    $runDeveloper = 'developer' -in $requested
    $runPrivacy = 'privacyConfiguration' -in $requested
    $runBrowser = 'browserConfiguration' -in $requested
    $runNetwork = 'network' -in $requested

    if ($runPrivacy -or $runBrowser -or $runNetwork) {
        . (Join-Path $RepoRoot 'lib\PrivacyAudit.ps1')
    }

    $doctor = if ($runDeveloper) { Invoke-DevShellDoctorJson -RepoRoot $RepoRoot -Tier $Tier } else { $null }
    $privacy = if ($runPrivacy) {
        Get-PrivacyAuditReport -Scope System -RepoRoot $RepoRoot -ProductVersion $ProductVersion
    } else { $null }
    $browser = if ($runBrowser) {
        Get-PrivacyAuditReport -Scope Browser -RepoRoot $RepoRoot -ProductVersion $ProductVersion
    } else { $null }
    $network = if ($runNetwork) {
        Get-PrivacyAuditReport -Scope Vpn -RepoRoot $RepoRoot -ProductVersion $ProductVersion
    } else { $null }

    $devFail = if (-not $runDeveloper) { 0 } elseif ($doctor) { Get-DevShellListCount $doctor.Failed } else { 1 }
    $devWarn = if ($runDeveloper -and $doctor) { Get-DevShellListCount $doctor.Warnings } else { 0 }
    $devPass = if ($runDeveloper -and $doctor) { Get-DevShellListCount $doctor.Passed } else { 0 }

    $privacyDoc = if ($runPrivacy) {
        Get-DevShellPrivacyReportDocument -Report $privacy -ProductVersion $ProductVersion
    } else { $null }
    $browserDoc = if ($runBrowser) {
        Get-DevShellPrivacyReportDocument -Report $browser -ProductVersion $ProductVersion
    } else { $null }
    $networkDoc = if ($runNetwork) {
        Get-DevShellPrivacyReportDocument -Report $network -ProductVersion $ProductVersion
    } else { $null }

    $sectionMap = [ordered]@{}
    if ($runDeveloper) {
        $sectionMap['developer'] = [ordered]@{
            id       = 'developer'
            label    = 'Developer'
            status   = Get-DevShellSectionStatus -FailCount $devFail -WarnCount $devWarn
            passed   = $devPass
            failed   = $devFail
            warnings = $devWarn
            tier     = $Tier
            detail   = if ($devFail -eq 0) {
                'Shell, tools, profile checks'
            } else {
                (@($doctor.Failed) | Select-Object -First 2) -join '; '
            }
        }
    }
    if ($runPrivacy) {
        $sectionMap['privacyConfiguration'] = New-DevShellScoredPrivacySection `
            -Id 'privacyConfiguration' `
            -Label 'Privacy Configuration' `
            -Audit $privacy `
            -Document $privacyDoc `
            -Disclaimer 'OS configuration only. Does not measure network anonymity.'
    }
    if ($runBrowser) {
        $sectionMap['browserConfiguration'] = New-DevShellScoredPrivacySection `
            -Id 'browserConfiguration' `
            -Label 'Browser Configuration' `
            -Audit $browser `
            -Document $browserDoc `
            -Detail 'Policy and prefs audit — not a full browser security review.'
    }
    if ($runNetwork) {
        $sectionMap['network'] = [ordered]@{
            id       = 'network'
            label    = 'Network'
            status   = Get-DevShellSectionStatus -FailCount $network.FailCount -WarnCount $network.WarnCount
            score    = $network.Score
            warnings = $network.WarnCount
            failed   = $network.FailCount
            detail   = 'VPN/TUN/DNS heuristics — offline, no leak test to external sites.'
        }
    }

    $ready = $true
    if ($runDeveloper -and $devFail -gt 0) { $ready = $false }
    if ($runPrivacy -and $privacy.FailCount -gt 0) { $ready = $false }

    [PSCustomObject]@{
        healthSchemaVersion = '1.0.0'
        productVersion      = $ProductVersion
        timestamp           = (Get-Date).ToString('o')
        philosophy          = 'HomeBase DevShell prepares, verifies and maintains professional Windows workstations.'
        tier                = $Tier
        sectionsRequested   = $requested
        sections            = $sectionMap
        privacyReport       = $privacyDoc
        browserReport       = $browserDoc
        networkReport       = $networkDoc
        doctorReport        = $doctor
        summary             = [ordered]@{
            ready   = $ready
            message = if ($ready) { 'Ready to work.' } else { 'Not ready yet.' }
        }
    }
}

function Get-DevShellHealthSectionField {
    param(
        $Sections,
        [Parameter(Mandatory)][string]$Key,
        [Parameter(Mandatory)][string]$Property,
        $Default = $null
    )
    if (-not $Sections) { return $Default }
    $section = $Sections[$Key]
    if (-not $section) { return $Default }
    $value = $section.$Property
    if ($null -eq $value) { return $Default }
    return $value
}

function Get-DevShellHealthDashboardColor {
    param([Parameter(Mandatory)]$Section)
    switch -Regex ($Section.status) {
        '^FAIL$' { return 'Red' }
        '^WARN$' { return 'Yellow' }
        '^\d+%$' {
            $pct = [int]($Section.status -replace '%', '')
            if ($pct -ge 85) { return 'Green' }
            if ($pct -ge 65) { return 'Yellow' }
            return 'Red'
        }
        '^PASS$' { return 'Green' }
        default { return 'DarkGray' }
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
        Write-Host ("{0,-22} {1}" -f $s.label, $s.status) -ForegroundColor (Get-DevShellHealthDashboardColor -Section $s)
        if ($s.disclaimer) {
            Write-Host "  $($s.disclaimer)" -ForegroundColor DarkGray
        }
    }

    Write-Host ''
    Write-Host 'Summary' -ForegroundColor Cyan
    Write-Host $Report.summary.message -ForegroundColor $(if ($Report.summary.ready) { 'Green' } else { 'Yellow' })
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
    Initialize-DevShellParentDirectory -FilePath $HistoryPath
    $row = [ordered]@{
        timestamp = $Report.timestamp
        developer = Get-DevShellHealthSectionField -Sections $Report.sections -Key 'developer' -Property 'status' -Default 'N/A'
        privacy   = Get-DevShellHealthSectionField -Sections $Report.sections -Key 'privacyConfiguration' -Property 'score'
        browser   = Get-DevShellHealthSectionField -Sections $Report.sections -Key 'browserConfiguration' -Property 'score'
        network   = Get-DevShellHealthSectionField -Sections $Report.sections -Key 'network' -Property 'status' -Default 'N/A'
        ready     = $Report.summary.ready
        sections  = @($Report.sectionsRequested)
    }
    ($row | ConvertTo-Json -Compress) | Add-Content -LiteralPath $HistoryPath -Encoding UTF8
}

function Show-DevShellHealthHistory {
    param([string]$HistoryPath, [int]$Last = 15)
    if (-not $HistoryPath) {
        $HistoryPath = (Get-DevShellHealthPaths -RepoRoot $env:HOMEBASE_DEVSHELL_ROOT).History
    }
    if (-not (Test-Path -LiteralPath $HistoryPath)) {
        Write-Host 'No health history yet. Run: devshell health' -ForegroundColor DarkGray
        return
    }

    $rows = [System.Collections.Generic.List[object]]::new()
    $tailBuffer = [Math]::Max($Last * 4, 64)
    foreach ($line in (Get-Content -LiteralPath $HistoryPath -Encoding UTF8 -Tail $tailBuffer -ErrorAction SilentlyContinue)) {
        if ([string]::IsNullOrWhiteSpace($line)) { continue }
        try {
            $rows.Add(($line | ConvertFrom-Json))
        } catch {
            Write-Verbose "Skipping invalid history line: $line"
        }
    }
    if ($rows.Count -eq 0) {
        Write-Host 'No readable health history entries.' -ForegroundColor DarkGray
        return
    }

    Write-Host ''
    Write-Host 'Health history' -ForegroundColor Cyan
    Write-Host ''
    $slice = if ($rows.Count -gt $Last) { @($rows)[($rows.Count - $Last)..($rows.Count - 1)] } else { @($rows) }
    foreach ($r in $slice) {
        $d = ([datetime]$r.timestamp).ToString('MMM dd')
        $privacy = if ($null -ne $r.privacy) { "{0,3}%" -f $r.privacy } else { ' N/A' }
        $developer = if ($r.developer) { $r.developer } else { 'N/A' }
        Write-Host ("{0,-8} Privacy {1}  Developer {2,-4}  Ready {3}" -f $d, $privacy, $developer, $(if ($r.ready) { 'yes' } else { 'no' })) -ForegroundColor DarkGray
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
    Initialize-DevShellParentDirectory -FilePath $BaselinePath
    $Report | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath $BaselinePath -Encoding UTF8
    Write-Host "Baseline saved: $BaselinePath" -ForegroundColor DarkGray
}

function New-DevShellBaselineCompareResult {
    param(
        $BaselineTimestamp,
        [Parameter(Mandatory)][string]$CurrentTimestamp,
        [string[]]$Changes = @(),
        [bool]$DriftDetected,
        [switch]$NoBaseline,
        [switch]$BaselineInvalid
    )
    $result = [ordered]@{
        baselineTimestamp = $BaselineTimestamp
        currentTimestamp  = $CurrentTimestamp
        changes           = @($Changes)
        driftDetected     = $DriftDetected
    }
    if ($NoBaseline) { $result.noBaseline = $true }
    if ($BaselineInvalid) { $result.baselineInvalid = $true }
    return [PSCustomObject]$result
}

function Compare-DevShellHealthBaseline {
    param(
        [Parameter(Mandatory)]$Current,
        [string]$BaselinePath
    )
    if (-not $BaselinePath) {
        $BaselinePath = (Get-DevShellHealthPaths -RepoRoot $env:HOMEBASE_DEVSHELL_ROOT).Baseline
    }
    if (-not (Test-Path -LiteralPath $BaselinePath)) {
        Write-Host 'No baseline. Run: devshell baseline' -ForegroundColor Yellow
        return New-DevShellBaselineCompareResult `
            -BaselineTimestamp $null `
            -CurrentTimestamp $Current.timestamp `
            -DriftDetected $false `
            -NoBaseline
    }
    try {
        $base = Get-Content -LiteralPath $BaselinePath -Raw -Encoding UTF8 | ConvertFrom-Json
    } catch {
        Write-Host 'Baseline file is invalid JSON. Run: devshell baseline' -ForegroundColor Yellow
        return New-DevShellBaselineCompareResult `
            -BaselineTimestamp $null `
            -CurrentTimestamp $Current.timestamp `
            -Changes @('Baseline file is unreadable or corrupt') `
            -DriftDetected $true `
            -BaselineInvalid
    }

    $changes = [System.Collections.Generic.List[string]]::new()
    foreach ($key in $Current.sections.Keys) {
        $c = $Current.sections[$key]
        $b = $base.sections.$key
        if (-not $b) {
            $changes.Add("$($c.label): new section")
            continue
        }
        $cStat = if ($null -ne $c.score) { "$($c.score)" } else { $c.status }
        $bStat = if ($null -ne $b.score) { "$($b.score)" } else { $b.status }
        if ($cStat -ne $bStat) {
            $changes.Add("$($c.label): $bStat → $cStat")
        }
    }

    if ($Current.privacyReport -and $base.privacyReport) {
        $baseChecks = @{}
        foreach ($chk in @($base.privacyReport.checks)) {
            if ($chk.id) { $baseChecks[$chk.id] = $chk.status }
        }
        foreach ($chk in @($Current.privacyReport.checks)) {
            $old = $baseChecks[$chk.id]
            if ($old -and $old -ne $chk.status) {
                $changes.Add("Privacy check $($chk.id): $old → $($chk.status)")
            }
        }
    }

    return New-DevShellBaselineCompareResult `
        -BaselineTimestamp $base.timestamp `
        -CurrentTimestamp $Current.timestamp `
        -Changes @($changes) `
        -DriftDetected ($changes.Count -gt 0)
}

function Write-DevShellVerifyOutput {
    param(
        [Parameter(Mandatory)]$Diff,
        [switch]$Json
    )
    if ($Json) {
        if ($Diff.noBaseline) {
            @{ error = 'no_baseline'; message = 'Run: devshell baseline' } | ConvertTo-Json
            return 1
        }
        if ($Diff.baselineInvalid) {
            @{
                error   = 'baseline_invalid'
                message = 'Baseline file is unreadable or corrupt'
                changes = @($Diff.changes)
            } | ConvertTo-Json
            return 1
        }
        $Diff | ConvertTo-Json -Depth 5
        return $(if ($Diff.driftDetected) { 1 } else { 0 })
    }

    Write-Host ''
    Write-Host 'Baseline verify' -ForegroundColor Cyan
    if ($Diff.noBaseline -or $Diff.baselineInvalid) {
        if ($Diff.baselineInvalid -and $Diff.changes) {
            Write-Host "  $($Diff.changes[0])" -ForegroundColor Yellow
        }
        return 1
    }
    Write-Host "  Baseline: $($Diff.baselineTimestamp)" -ForegroundColor DarkGray
    Write-Host "  Current:  $($Diff.currentTimestamp)" -ForegroundColor DarkGray
    Write-Host ''
    if (-not $Diff.driftDetected) {
        Write-Host '  No drift detected.' -ForegroundColor Green
    } else {
        Write-Host '  Changes:' -ForegroundColor Yellow
        $Diff.changes | ForEach-Object { Write-Host "    $_" -ForegroundColor DarkGray }
    }
    Write-Host ''
    return $(if ($Diff.driftDetected) { 1 } else { 0 })
}

function Export-DevShellHealthHtml {
    param(
        [Parameter(Mandatory)]$Report,
        [Parameter(Mandatory)][string]$OutPath
    )
    $esc = { param($t) if ($null -eq $t) { return '' }; [System.Net.WebUtility]::HtmlEncode([string]$t) }

    $sb = [System.Text.StringBuilder]::new()
    foreach ($key in $Report.sections.Keys) {
        $s = $Report.sections[$key]
        $badge = & $esc $s.status
        $label = & $esc $s.label
        $disclaimer = if ($s.disclaimer) { "<p class='muted'>$( & $esc $s.disclaimer )</p>" } else { '' }
        $detail = if ($s.detail) { "<p class='muted'>$( & $esc $s.detail )</p>" } else { '' }
        [void]$sb.AppendLine(@"
    <div class="card">
      <div class="card-head"><span>$label</span><span class="badge">$badge</span></div>
      $disclaimer
      $detail
    </div>
"@)
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
  <div class="grid">$($sb.ToString())</div>
  <div class="summary $readyClass"><strong>Summary:</strong> $( & $esc $Report.summary.message )</div>
</body>
</html>
"@
    Initialize-DevShellParentDirectory -FilePath $OutPath
    $html | Set-Content -LiteralPath $OutPath -Encoding UTF8
    Write-Host "HTML report: $OutPath" -ForegroundColor DarkGray
}
