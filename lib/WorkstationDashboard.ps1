# Fast startup dashboard — KGreen workstation command center
# C:\Scripts\Workstation\lib\WorkstationDashboard.ps1

function Get-WorkstationMetricLine {
    param([string]$Label, [string]$Value, [ValidateSet('ok','warn','err','info')][string]$Status = 'info')
    $icon = switch ($Status) {
        'ok'   { '+' }
        'warn' { '!' }
        'err'  { 'x' }
        default { '-' }
    }
    $color = switch ($Status) {
        'ok'   { 'Green' }
        'warn' { 'Yellow' }
        'err'  { 'Red' }
        default { 'DarkGray' }
    }
    Write-Host ("  [{0}] " -f $icon) -NoNewline -ForegroundColor $color
    Write-Host ("{0,-16}" -f $Label) -NoNewline -ForegroundColor DarkGray
    Write-Host $Value -ForegroundColor Cyan
}

function Show-WorkstationDashboard {
    param([switch]$Full)

    if ($env:WORKSTATION_DASHBOARD -eq '0') { return }

    $owner = 'KGreen'
    $line = '─' * 52
    Write-Host ""
    Write-Host "  $line" -ForegroundColor DarkGray
    Write-Host "  WORKSTATION  ·  $owner  ·  $(Get-Date -Format 'yyyy-MM-dd HH:mm')" -ForegroundColor White
    Write-Host "  $line" -ForegroundColor DarkGray

    # Shell
    Get-WorkstationMetricLine 'PowerShell' "7 $($PSVersionTable.PSVersion)" 'ok'

    # Git (local repo only — fast)
    $gitOk = Get-Command git -EA SilentlyContinue
    if ($gitOk) {
        $inRepo = git rev-parse --is-inside-work-tree 2>$null
        if ($inRepo -eq 'true') {
            $branch = git branch --show-current 2>$null
            $dirty = git status --porcelain 2>$null
            $st = if ($dirty) { 'warn' } else { 'ok' }
            Get-WorkstationMetricLine 'Git' "$branch$(if($dirty){' *'})" $st
        } else {
            Get-WorkstationMetricLine 'Git' "$(git config --global user.name) (global)" 'ok'
        }
    }

    # Python
    if (Get-Command python -EA SilentlyContinue) {
        $py = python --version 2>&1
        $venv = if ($env:VIRTUAL_ENV) { ' venv active' } else { '' }
        Get-WorkstationMetricLine 'Python' "$py$venv" 'ok'
    }

    # Tools health (existence only — instant)
    $core = @('eza','bat','fzf','code','rg')
    $missing = @($core | Where-Object { -not (Get-Command $_ -EA SilentlyContinue) })
    Get-WorkstationMetricLine 'Tools' $(if ($missing) { "missing: $($missing -join ', ')" } else { 'all core OK' }) $(if ($missing) { 'warn' } else { 'ok' })

    # System resources — lightweight (no CIM on every launch)
    $maintFile = 'C:\Logs\Workstation\maintenance-last.json'
    if (Test-Path $maintFile) {
        try {
            $m = Get-Content $maintFile -Raw | ConvertFrom-Json
            Get-WorkstationMetricLine 'Disk C:' "$($m.FreeGB) GB free" $(if ($m.FreeGB -lt 15) { 'warn' } else { 'ok' })
            if ($m.MemPct) { Get-WorkstationMetricLine 'Memory' "$($m.MemPct)% used" $(if ($m.MemPct -gt 85) { 'warn' } else { 'ok' }) }
            if ($m.UptimeH) { Get-WorkstationMetricLine 'Uptime' "$($m.UptimeH)h" 'info' }
        } catch { }
    }
    $disk = Get-PSDrive C -EA SilentlyContinue
    if ($disk -and -not (Test-Path $maintFile)) {
        Get-WorkstationMetricLine 'Disk C:' "$([math]::Round($disk.Free/1GB)) GB free" 'info'
    }

    # Backup status
    $lastBak = Get-ChildItem 'C:\Backups\Workstation' -Directory -EA SilentlyContinue | Sort-Object Name -Descending | Select-Object -First 1
    if ($lastBak) {
        $age = ((Get-Date) - $lastBak.CreationTime).TotalDays
        Get-WorkstationMetricLine 'Backup' "$($lastBak.Name) ($([math]::Round($age,0))d ago)" $(if ($age -gt 7) { 'warn' } else { 'ok' })
    } else {
        Get-WorkstationMetricLine 'Backup' 'none — run backupconfig' 'warn'
    }

    # Security — deferred detail (run securitycheck for full audit)
    Get-WorkstationMetricLine 'Security' 'securitycheck for details' 'info'

    # Last validation
    $lastVal = Get-ChildItem 'C:\Logs\Workstation\validation-*.json' -EA SilentlyContinue | Sort-Object Name -Descending | Select-Object -First 1
    if ($lastVal) {
        try {
            $v = Get-Content $lastVal -Raw | ConvertFrom-Json
            $fc = if ($v.Metrics.FailCount) { $v.Metrics.FailCount } else { 0 }
            Get-WorkstationMetricLine 'Health' $(if ($fc -eq 0) { 'last check passed' } else { "$fc failures" }) $(if ($fc -eq 0) { 'ok' } else { 'err' })
        } catch { }
    }

    if ($Full) {
        Write-Host "  $line" -ForegroundColor DarkGray
        Write-Host "  networkstatus · updateall · doctor · helpme" -ForegroundColor DarkGray
    } else {
        Write-Host "  $line" -ForegroundColor DarkGray
        Write-Host "  helpme · doctor · workstationstatus -Full" -ForegroundColor DarkGray
    }
    Write-Host ""
}

# Dashboard display is triggered from profile Prompt (first render) — not on import
