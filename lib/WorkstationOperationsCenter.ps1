# Workstation Operations Center (WOC) — KGreen
# C:\Scripts\Workstation\lib\WorkstationOperationsCenter.ps1

$pathsLib = Join-Path $PSScriptRoot 'HomeBasePaths.ps1'
if (Test-Path $pathsLib) { . $pathsLib }

function Get-WocLogsRoot {
    if (Get-Command Get-HomeBasePath -ErrorAction SilentlyContinue) {
        return Get-HomeBasePath -Name Logs
    }
    return 'C:\Logs\Workstation'
}

function Get-WocBackupsRoot {
    if (Get-Command Get-HomeBasePath -ErrorAction SilentlyContinue) {
        return Get-HomeBasePath -Name Backups
    }
    return 'C:\Backups\Workstation'
}

function Get-WocRepositoryRoot {
    if ($script:WSRoot) { return $script:WSRoot }
    if ($env:WORKSTATION_ROOT) { return $env:WORKSTATION_ROOT }
    if (Get-Command Get-HomeBasePath -ErrorAction SilentlyContinue) {
        return Get-HomeBasePath -Name RepositoryRoot
    }
    return 'C:\Scripts\Workstation'
}

function Resolve-WocMaintainerScript {
    param([Parameter(Mandatory)][string]$Name)
    $root = Get-WocRepositoryRoot
    $resolveLib = Join-Path $root 'scripts\maintainer\_Resolve-RepoRoot.ps1'
    if (Test-Path $resolveLib) {
        if (-not (Get-Command Resolve-WorkstationScript -ErrorAction SilentlyContinue)) {
            . $resolveLib
        }
        try {
            return Resolve-WorkstationScript -Name $Name -Start $root
        } catch { }
    }
    foreach ($sub in @('install', 'invoke', 'configure', 'test', 'phase2')) {
        $candidate = Join-Path $root "scripts\maintainer\$sub\$Name"
        if (Test-Path $candidate) { return $candidate }
    }
    return Join-Path $root $Name
}

function Get-WocOmpThemePath {
    if ($script:ProfileOmpTheme -and (Test-Path $script:ProfileOmpTheme)) {
        return $script:ProfileOmpTheme
    }
    $repo = Get-WocRepositoryRoot
    $active = Join-Path $repo 'terminal\active-theme.omp.json'
    if (Test-Path $active) { return $active }
    return Join-Path $repo 'terminal\homebase-hacker.omp.json'
}

$script:WocLogDir    = Get-WocLogsRoot
$script:WocStatePath = Join-Path $script:WocLogDir 'woc-last-session.json'
$script:WocCachePath = Join-Path $script:WocLogDir 'woc-cache.json'
$script:WocOwner     = 'KGreen'
$script:WocWidth     = 62

function Get-WocMode {
    $m = ($env:WORKSTATION_STARTUP_MODE ?? '').ToLower().Trim()
    if ($m -in @('minimal', 'normal', 'full')) { return $m }
    return 'normal'
}

function Get-WocFileCache {
    $c = [ordered]@{}
    foreach ($f in @(
        @{ K = 'Maint'; P = 'maintenance-last.json' }
        @{ K = 'Start'; P = 'startup-cache.json' }
        @{ K = 'Font';  P = 'font-status.json' }
        @{ K = 'Woc';   P = 'woc-cache.json' }
    )) {
        $path = Join-Path $script:WocLogDir $f.P
        if (Test-Path $path) { try { $c[$f.K] = Get-Content $path -Raw | ConvertFrom-Json } catch { } }
    }
    $val = Get-ChildItem $script:WocLogDir -Filter 'validation-*.json' -EA SilentlyContinue |
        Sort-Object Name -Descending | Select-Object -First 1
    if ($val) { try { $c.Val = Get-Content $val.FullName -Raw | ConvertFrom-Json } catch { } }
    return $c
}

function New-WocCheck([string]$Name, [string]$Status, [string]$Detail = '') {
    [PSCustomObject]@{ Name = $Name; Status = $Status; Detail = $Detail }
}

function Test-WocHealthChecks {
    $checks = [System.Collections.Generic.List[object]]::new()
    $repo  = Get-WocRepositoryRoot
    $canon = Join-Path $repo 'profile\Microsoft.PowerShell_profile.ps1'
    $live  = Join-Path $env:USERPROFILE 'Documents\PowerShell\Microsoft.PowerShell_profile.ps1'

    # PowerShell
    $checks.Add((New-WocCheck 'PowerShell 7' $(if (Get-Command pwsh -EA SilentlyContinue) { 'OK' } else { 'ERROR' }) ($PSVersionTable.PSVersion.ToString())))

    # Profile
    if (-not (Test-Path $live)) { $checks.Add((New-WocCheck 'Profile' 'ERROR' 'missing live profile')) }
    elseif (-not (Test-Path $canon)) { $checks.Add((New-WocCheck 'Profile' 'ERROR' 'canonical missing')) }
    else {
        $match = (Get-FileHash $canon).Hash -eq (Get-FileHash $live).Hash
        $checks.Add((New-WocCheck 'Profile' $(if ($match) { 'OK' } else { 'WARNING' }) $(if ($match) { 'synced' } else { 'drift detected' })))
    }

    # Windows Terminal
    $wt = Join-Path $env:LOCALAPPDATA 'Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json'
    if (Test-Path $wt) {
        try {
            $w = Get-Content $wt -Raw | ConvertFrom-Json
            $ff = $w.profiles.defaults.font.face
            $checks.Add((New-WocCheck 'Windows Terminal' $(if ($ff -eq 'CaskaydiaCove NF') { 'OK' } else { 'WARNING' }) "font: $ff"))
        } catch { $checks.Add((New-WocCheck 'Windows Terminal' 'WARNING' 'settings unreadable')) }
    } else { $checks.Add((New-WocCheck 'Windows Terminal' 'WARNING' 'settings not found')) }

    # Oh My Posh — active theme (read-only config check)
    $omp = Get-WocOmpThemePath
    if ((Get-Command oh-my-posh -EA SilentlyContinue) -and (Test-Path $omp)) {
        $checks.Add((New-WocCheck 'Oh My Posh' 'OK' (Split-Path $omp -Leaf)))
    } elseif (Get-Command oh-my-posh -EA SilentlyContinue) {
        $checks.Add((New-WocCheck 'Oh My Posh' 'WARNING' 'active theme missing'))
    } else { $checks.Add((New-WocCheck 'Oh My Posh' 'ERROR' 'not installed')) }

    # Font
    $fs = Join-Path $script:WocLogDir 'font-status.json'
    if (Test-Path $fs) {
        try {
            $f = Get-Content $fs -Raw | ConvertFrom-Json
            $checks.Add((New-WocCheck 'Nerd Font' $(if ($f.FontFace -eq 'CaskaydiaCove NF') { 'OK' } else { 'ERROR' }) $f.FontFace))
        } catch { $checks.Add((New-WocCheck 'Nerd Font' 'WARNING' 'status unknown')) }
    } else { $checks.Add((New-WocCheck 'Nerd Font' 'WARNING' 'font-status.json missing')) }

    # Modules
    foreach ($mod in @('PSReadLine', 'posh-git')) {
        $checks.Add((New-WocCheck "Module $mod" $(if (Get-Module -ListAvailable $mod) { 'OK' } else { 'WARNING' }) $(if (Get-Module -ListAvailable $mod) { 'installed' } else { 'missing' })))
    }

    # Aliases / commands
    foreach ($cmd in @('projects', 'doctor', 'll', 'sysinfo', 'nettools', 'toolcheck', 'jarvis')) {
        $checks.Add((New-WocCheck "Command $cmd" $(if (Get-Command $cmd -EA SilentlyContinue) { 'OK' } else { 'ERROR' }) ''))
    }

    # Command center health (from Test-WorkstationCommands or live registry)
    $cmdHealthPath = Join-Path $script:WocLogDir 'command-health.json'
    if (Test-Path $cmdHealthPath) {
        try {
            $ch = Get-Content $cmdHealthPath -Raw | ConvertFrom-Json
            if ($ch.Broken -gt 0) {
                $checks.Add((New-WocCheck 'Command Center' 'ERROR' "$($ch.Broken) broken: $($ch.BrokenCommands -join ', ')"))
            } elseif ($ch.ExecuteFailures -gt 0) {
                $checks.Add((New-WocCheck 'Command Center' 'WARNING' "$($ch.ExecuteFailures) exec failure(s)"))
            } else {
                $checks.Add((New-WocCheck 'Command Center' 'OK' "$($ch.Passed)/$($ch.TotalCommands) commands OK"))
            }
        } catch {
            $checks.Add((New-WocCheck 'Command Center' 'WARNING' 'command-health.json unreadable'))
        }
    } elseif (Get-Command Get-WorkstationCommandHealth -EA SilentlyContinue) {
        $live = @(Get-WorkstationCommandHealth | Where-Object { $_.Status -ne 'OK' })
        if ($live.Count) {
            $checks.Add((New-WocCheck 'Command Center' 'ERROR' "$($live.Count) broken command(s)"))
        } else {
            $checks.Add((New-WocCheck 'Command Center' 'OK' 'all registered commands loaded'))
        }
    } else {
        $checks.Add((New-WocCheck 'Command Center' 'WARNING' 'run Test-WorkstationCommands'))
    }

    # Core scripts
    foreach ($scr in @('Validate-Workstation.ps1', 'Repair-WorkstationFonts.ps1', 'Invoke-Maintenance.ps1')) {
        $p = Resolve-WocMaintainerScript -Name $scr
        $checks.Add((New-WocCheck "Script $scr" $(if (Test-Path $p) { 'OK' } else { 'ERROR' }) ''))
    }

    return @($checks)
}

function Get-WocPerformanceBlock {
    param($Cache)
    $block = [ordered]@{}
    $block.ProfileMs = if ($Cache.Val.Metrics.ProfileLoadMs) { $Cache.Val.Metrics.ProfileLoadMs } else { '—' }
    $block.CpuPct      = $Cache.Woc.CpuPct ?? $Cache.Start.CpuPct
    $block.MemPct      = $Cache.Woc.MemPct ?? $Cache.Maint.MemPct
    $disk = Get-PSDrive C -EA SilentlyContinue
    if ($disk -and ($disk.Used + $disk.Free)) {
        $block.DiskFreeGB = [math]::Round($disk.Free / 1GB, 1)
        $block.DiskFreePct = [math]::Round(100 * $disk.Free / ($disk.Used + $disk.Free), 0)
    }
    $block.BootTime = $Cache.Woc.BootTime
    $block.Uptime   = if ($Cache.Maint.UptimeH) { "$($Cache.Maint.UptimeH)h" } else { '—' }
    if (-not $block.BootTime) {
        try {
            $os = Get-CimInstance Win32_OperatingSystem -OperationTimeoutSec 1
            $block.BootTime = $os.LastBootUpTime.ToString('yyyy-MM-dd HH:mm')
            $block.Uptime = Format-WocUptime ((Get-Date) - $os.LastBootUpTime)
        } catch { $block.BootTime = '—' }
    }
    $block.LastMaintenance = $Cache.Maint.Timestamp
    $block.TopProcesses    = @($Cache.Woc.TopProcesses)
    $block.SlowStartup     = ($block.ProfileMs -is [int] -and $block.ProfileMs -gt 300)
    $block.HighRam         = ($block.MemPct -ge 85)
    $block.HighCpu         = ($block.CpuPct -ge 80)
    return $block
}

function Get-WocSecurityBlock {
    param($Cache)
    if ($Cache.Woc.SecurityChecks) {
        return @($Cache.Woc.SecurityChecks | ForEach-Object {
            New-WocCheck $_.Name $_.Status $_.Detail
        })
    }
    # Fast fallback — registry only (no Get-NetFirewallProfile on startup)
    $items = [System.Collections.Generic.List[object]]::new()
    if ($Cache.Maint.SecurityFlags -contains 'inbound-open') {
        try {
            $liveBad = @(Get-NetFirewallProfile -EA Stop | Where-Object { $_.DefaultInboundAction -ne 'Block' })
            if ($liveBad.Count) {
                $items.Add((New-WocCheck 'Firewall' 'WARNING' 'inbound not Block — admin: Harden-Security.ps1'))
            } else {
                $items.Add((New-WocCheck 'Firewall' 'OK' 'inbound Block (live)'))
            }
        } catch {
            $items.Add((New-WocCheck 'Firewall' 'WARNING' 'inbound not Block (cached)'))
        }
    } else {
        $items.Add((New-WocCheck 'Firewall' 'OK' 'cached OK'))
    }
    try {
        $uac = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' -EA Stop
        $items.Add((New-WocCheck 'UAC' $(if ($uac.EnableLUA -eq 1) { 'OK' } else { 'ERROR' }) 'enabled'))
    } catch { $items.Add((New-WocCheck 'UAC' 'WARNING' 'unknown')) }
    try {
        $smb = Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters' -Name SMB1 -EA SilentlyContinue
        $items.Add((New-WocCheck 'SMB1' $(if ($smb.SMB1 -eq 0) { 'OK' } else { 'WARNING' }) 'disabled'))
    } catch { }
    try {
        $rdp = Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server' -Name fDenyTSConnections -EA SilentlyContinue
        $items.Add((New-WocCheck 'Remote Desktop' $(if ($rdp.fDenyTSConnections -eq 1) { 'OK' } else { 'WARNING' }) 'disabled'))
    } catch { }
    return @($items)
}

function Get-WocBackupBlock {
    param($Cache)
    if ($Cache.Woc.BackupSummary) {
        $b = $Cache.Woc.BackupSummary
        return [ordered]@{
            Count = $b.Count; Latest = $b.Latest; DaysAgo = $b.DaysAgo
            SizeMB = $b.SizeMB; Status = $b.Status; RestoreTest = $b.RestoreTest ?? 'never recorded'
        }
    }
    $root = Get-WocBackupsRoot
    $dirs = @(Get-ChildItem $root -Directory -EA SilentlyContinue |
        Where-Object { $_.Name -ne '_Archive' } |
        Sort-Object LastWriteTime -Descending)
    $latest = $dirs | Select-Object -First 1
    $block = [ordered]@{ Count = $dirs.Count; Latest = $null; DaysAgo = $null; SizeMB = 0; Status = 'ERROR'; RestoreTest = 'never recorded' }
    if ($latest) {
        $block.Latest = $latest.Name
        $block.DaysAgo = [math]::Round(((Get-Date) - $latest.CreationTime).TotalDays, 1)
        $block.Status = if ($block.DaysAgo -gt 14) { 'WARNING' } else { 'OK' }
    }
    return $block
}

function Get-WocDevelopmentBlock {
    $tools = @(
        @{ N = 'Git';    C = 'git';    V = '--version' }
        @{ N = 'Python'; C = 'python'; V = '--version' }
        @{ N = 'VS Code'; C = 'code';  V = '--version' }
        @{ N = 'WinGet'; C = 'winget'; V = '--version' }
        @{ N = 'GitHub CLI'; C = 'gh'; V = '--version' }
        @{ N = 'Node';   C = 'node';   V = '--version'; Opt = $true }
    )
    $out = foreach ($t in $tools) {
        $cmd = Get-Command $t.C -EA SilentlyContinue
        $ver = '—'
        if ($cmd -and $t.V) { try { $ver = (& $t.C $t.V 2>&1 | Select-Object -First 1).ToString().Trim() } catch { $ver = 'installed' } }
        $st = if ($cmd) { 'OK' } elseif ($t.Opt) { 'OK' } else { 'WARNING' }
        New-WocCheck $t.N $st $ver
    }
    return @($out)
}

function Get-WocNetworkBlock {
    param($Cache)
    $block = [ordered]@{}
    $cn = $Cache.Woc.NetworkCached
    if ($cn) {
        return [ordered]@{
            Adapter = $cn.Adapter; AdapterCount = $cn.AdapterCount; LocalIP = $cn.LocalIP
            PublicIP = $cn.PublicIP; DNS = $cn.DNS; Gateway = $cn.Gateway
            Connectivity = $cn.Connectivity; Profile = $cn.Profile
        }
    }
    $block.PublicIP = $Cache.Woc.PublicIP ?? $Cache.Start.PublicIP ?? 'not cached'
    $block.Adapter = '—'; $block.LocalIP = '—'; $block.DNS = '—'; $block.Gateway = '—'; $block.Profile = $Cache.Woc.NetworkProfile ?? '—'
    $block.Connectivity = 'unknown'
    $block.AdapterCount = $Cache.Start.NetworkUp ?? 0
    return $block
}

function Get-WocMaintenanceBlock {
    param($Cache)
    $m = [ordered]@{
        DaysSinceMaintenance = $null; DaysSinceBackup = $null
        DaysSinceUpdate = $null; DaysSinceReboot = $null
        PendingUpdates = $Cache.Maint.PendingUpdates
    }
    if ($Cache.Maint.Timestamp) {
        $m.DaysSinceMaintenance = [math]::Round(((Get-Date) - [datetime]$Cache.Maint.Timestamp).TotalDays, 1)
    }
    if ($Cache.Woc.BackupSummary.DaysAgo) { $m.DaysSinceBackup = $Cache.Woc.BackupSummary.DaysAgo }
    else {
        $bak = Get-WocBackupBlock -Cache $Cache
        $m.DaysSinceBackup = $bak.DaysAgo
    }
    if ($Cache.Woc.LastUpdateCheck) {
        $m.DaysSinceUpdate = [math]::Round(((Get-Date) - [datetime]$Cache.Woc.LastUpdateCheck).TotalDays, 1)
    }
    if ($Cache.Woc.DaysSinceReboot) { $m.DaysSinceReboot = $Cache.Woc.DaysSinceReboot }
    return $m
}

function Get-WocChanges {
    param($Snapshot)
    $changes = [System.Collections.Generic.List[string]]::new()
    if (-not (Test-Path $script:WocStatePath)) {
        $changes.Add('First session — baseline saved')
        return @($changes)
    }
    try {
        $prev = Get-Content $script:WocStatePath -Raw | ConvertFrom-Json
        if ($prev.HealthScore -and $Snapshot.HealthScore -lt $prev.HealthScore) {
            $changes.Add("Health score dropped: $($prev.HealthScore) → $($Snapshot.HealthScore)")
        }
        if ($prev.ValidationFails -ne $Snapshot.ValidationFails) {
            $changes.Add("Validation failures: $($prev.ValidationFails) → $($Snapshot.ValidationFails)")
        }
        if ($prev.BackupLatest -ne $Snapshot.BackupLatest) {
            $changes.Add("Backup changed: $($prev.BackupLatest) → $($Snapshot.BackupLatest)")
        }
        if ($prev.WarningCount -lt $Snapshot.WarningCount) {
            $changes.Add("New warnings: +$($Snapshot.WarningCount - $prev.WarningCount)")
        }
        $added = @($Snapshot.Tools | Where-Object { $_ -notin @($prev.Tools) })
        foreach ($a in $added) { $changes.Add("Tool added: $a") }
        if (-not $changes.Count) { $changes.Add('No significant changes since last session') }
    } catch { $changes.Add('Change tracking unavailable') }
    return @($changes)
}

function Get-WocRecommendations {
    param($Report)
    $rec = [System.Collections.Generic.List[string]]::new()
    if ($Report.Backup.Status -ne 'OK' -or $Report.Maintenance.DaysSinceBackup -gt 7) {
        $rec.Add('Create a backup — run backupconfig')
    }
    if ($Report.Maintenance.DaysSinceMaintenance -gt 7 -or -not $Report.Maintenance.DaysSinceMaintenance) {
        $rec.Add('Run maintenance — Invoke-Maintenance.ps1 -Full')
    }
    if ($Report.Maintenance.PendingUpdates -gt 0) {
        $rec.Add("Apply $($Report.Maintenance.PendingUpdates) pending update(s) — updateall")
    }
    if ($Report.Performance.HighRam) { $rec.Add('High RAM usage — close heavy apps or reboot') }
    if ($Report.Performance.HighCpu) { $rec.Add('High CPU usage — check top processes') }
    if ($Report.Performance.SlowStartup) { $rec.Add('Slow profile load — run doctor') }
    foreach ($h in $Report.Health | Where-Object Status -eq 'ERROR') {
        $rec.Add("Fix $($h.Name) — repairterminal or doctor")
    }
    if ($Report.Security | Where-Object { $_.Status -eq 'WARNING' -and $_.Name -like 'Firewall*' }) {
        $rec.Add('Review firewall — securitycheck (admin: Harden-Security.ps1)')
    }
    if ($Report.Performance.DiskFreeGB -lt 15) { $rec.Add('Low disk space — cleanup') }
    if (-not $rec.Count) { $rec.Add('No urgent actions — workstation is in good shape') }
    return @($rec | Select-Object -Unique)
}

function Get-WocHealthScore {
    param($AllChecks)
    $score = 100
    foreach ($c in $AllChecks) {
        switch ($c.Status) {
            'WARNING' { $score -= 4 }
            'ERROR'   {
                if ($c.Name -match 'Command Center|Command nettools|Command toolcheck|Command jarvis') {
                    $score -= 15
                } else {
                    $score -= 12
                }
            }
        }
    }
    return [math]::Max(0, [math]::Min(100, $score))
}

function Get-WocHealthLabel([int]$Score) {
    if ($Score -ge 90) { return 'HEALTHY' }
    if ($Score -ge 70) { return 'DEGRADED' }
    if ($Score -ge 50) { return 'ATTENTION' }
    return 'CRITICAL'
}

function Format-WocUptime([TimeSpan]$Span) {
    if ($Span.TotalDays -ge 1) { return "{0}d {1}h" -f [int]$Span.TotalDays, $Span.Hours }
    if ($Span.TotalHours -ge 1) { return "{0}h {1}m" -f [int]$Span.TotalHours, $Span.Minutes }
    return "{0}m" -f [math]::Max(1, [int]$Span.Minutes)
}

function Write-WocLine([string]$Text, [string]$Color = 'White') {
    Write-Host "  $Text" -ForegroundColor $Color
}

function Write-WocHeader {
    Write-Host ""
    Write-Host ("  ╔{0}╗" -f ('═' * ($script:WocWidth - 2))) -ForegroundColor DarkCyan
    Write-Host ("  ║  WORKSTATION OPERATIONS CENTER  ·  {0}{1}║" -f $script:WocOwner, (' ' * 22)) -ForegroundColor Cyan
    Write-Host ("  ╚{0}╝" -f ('═' * ($script:WocWidth - 2))) -ForegroundColor DarkCyan
}

function Write-WocScoreBanner {
    param([int]$Score, [string]$Label)
    $col = if ($Score -ge 90) { 'Green' } elseif ($Score -ge 70) { 'Yellow' } else { 'Red' }
    Write-Host ""
    Write-Host ("  ┌{0}┐" -f ('─' * ($script:WocWidth - 4))) -ForegroundColor DarkGray
    Write-Host ("  │  WORKSTATION HEALTH SCORE:  {0}/100  {1,-12}│" -f $Score, $Label) -ForegroundColor $col
    Write-Host ("  └{0}┘" -f ('─' * ($script:WocWidth - 4))) -ForegroundColor DarkGray
}

function Write-WocSection {
    param([string]$Title, [string]$Level = 'OK')
    $icon = switch ($Level) { 'ERROR' { '✖' } 'WARNING' { '!' } default { '●' } }
    $col  = switch ($Level) { 'ERROR' { 'Red' } 'WARNING' { 'Yellow' } default { 'Cyan' } }
    Write-Host ""
    Write-Host ("  {0} {1}" -f $icon, $Title) -ForegroundColor $col
    Write-Host ("  {0}" -f ('─' * 40)) -ForegroundColor DarkGray
}

function Write-WocCheckLine {
    param($Check)
    $icon = switch ($Check.Status) { 'ERROR' { '[ERR]' } 'WARNING' { '[WRN]' } default { '[OK ]' } }
    $col  = switch ($Check.Status) { 'ERROR' { 'Red' } 'WARNING' { 'Yellow' } default { 'DarkGray' } }
    $det  = if ($Check.Detail) { " — $($Check.Detail)" } else { '' }
    Write-Host ("  {0} {1,-22}{2}" -f $icon, $Check.Name, $det) -ForegroundColor $col
}

function Write-WocAlert {
    param([string]$Severity, [string]$Message, [string]$Action)
    $col = if ($Severity -eq 'ERROR') { 'Red' } else { 'Yellow' }
    Write-Host ""
    Write-Host "  $Severity" -ForegroundColor $col
    Write-Host "  $Message" -ForegroundColor White
    Write-Host "  Recommendation: $Action" -ForegroundColor Green
}

function Write-WocActionCenter {
    Write-WocSection 'ACTION CENTER' 'OK'
    $groups = @(
        @{ Title = 'Maintenance'; Cmds = @('cleanup', 'updateall', 'backupconfig') }
        @{ Title = 'Diagnostics'; Cmds = @('doctor', 'healthcheck', 'sysreport') }
        @{ Title = 'Development'; Cmds = @('devstart', 'workspace', 'code .') }
        @{ Title = 'Learning'; Cmds = @('learn', 'cheatsheet', 'quickstart') }
        @{ Title = 'Recovery'; Cmds = @('repairterminal', 'restoreconfig') }
        @{ Title = 'Network'; Cmds = @('networkstatus', 'nettools', 'toolcheck') }
    )
    foreach ($g in $groups) {
        Write-Host ("  [{0}]" -f $g.Title) -ForegroundColor Yellow
        Write-WocLine ($g.Cmds -join '  ·  ') 'DarkGray'
    }
    Write-Host ""
    Write-WocLine 'Reopen WOC: jarvis · dashboard · home' 'DarkGray'
    Write-WocLine 'Help: helpme · Modes: `$env:WORKSTATION_STARTUP_MODE = minimal|normal|full' 'DarkGray'
}

function Invoke-WocSelfHeal {
    <# Wave A Commit 5 — observability only; repair/install removed from diagnostics layer. #>
    param($Report)
    return @()
}

function Save-WocSessionState {
    param($Report)
    $tools = @('git','pwsh','python','code','nmap','wireshark','gh') | Where-Object { Get-Command $_ -EA SilentlyContinue }
    @{
        Timestamp        = (Get-Date).ToString('o')
        HealthScore      = $Report.Score
        ValidationFails  = $Report.ValidationFails
        WarningCount     = $Report.WarningCount
        BackupLatest     = $Report.Backup.Latest
        Tools            = @($tools)
    } | ConvertTo-Json | Set-Content $script:WocStatePath -Encoding UTF8
}

function Build-WocReport {
    $cache = Get-WocFileCache
    $health = Test-WocHealthChecks
    $security = Get-WocSecurityBlock -Cache $cache
    $backup = Get-WocBackupBlock -Cache $cache
    $dev = Get-WocDevelopmentBlock
    $perf = Get-WocPerformanceBlock -Cache $cache
    $net = Get-WocNetworkBlock -Cache $cache
    $maint = Get-WocMaintenanceBlock -Cache $cache

    $allChecks = @($health) + @($security) + @($dev)
    $score = Get-WocHealthScore -AllChecks $allChecks
    $label = Get-WocHealthLabel -Score $score
    $warnCount = @($allChecks | Where-Object Status -eq 'WARNING').Count
    $failCount = if ($cache.Val.Metrics.FailCount) { $cache.Val.Metrics.FailCount } else { 0 }

    $report = [ordered]@{
        Score = $score
        Label = $label
        Health = $health
        Performance = $perf
        Security = $security
        Backup = $backup
        Development = $dev
        Network = $net
        Maintenance = $maint
        ValidationFails = $failCount
        WarningCount = $warnCount + @($allChecks | Where-Object Status -eq 'ERROR').Count
    }

    $snapshot = [ordered]@{
        HealthScore = $score
        ValidationFails = $failCount
        WarningCount = $report.WarningCount
        BackupLatest = $backup.Latest
        Tools = @('git','pwsh','python','code','nmap','wireshark','gh') | Where-Object { Get-Command $_ -EA SilentlyContinue }
    }
    $report.Changes = Get-WocChanges -Snapshot $snapshot
    $report.Recommendations = Get-WocRecommendations -Report $report
    $report.Snapshot = $snapshot
    return $report
}

function Show-Woc {
    param(
        [switch]$Force,
        [switch]$NoHeal,
        [ValidateSet('minimal', 'normal', 'full')][string]$Mode
    )

    if (-not $Force -and $env:WORKSTATION_JARVIS -eq '0') { return }
    if (-not $Force -and $env:WORKSTATION_JARVIS_SHOWN -eq '1') { return }
    if ($env:CI) { return }
    if (-not [Environment]::UserInteractive) { return }

    if (-not $Force) { $env:WORKSTATION_JARVIS_SHOWN = '1' }
    $mode = if ($Mode) { $Mode } elseif ($Force) { 'full' } else { Get-WocMode }
    $sw = [Diagnostics.Stopwatch]::StartNew()

    $report = Build-WocReport

    Write-WocHeader
    Write-WocScoreBanner -Score $report.Score -Label $report.Label

    # Core questions — one-line answers
    Write-WocSection 'OPERATIONS SUMMARY' $(if ($report.Score -ge 90) { 'OK' } else { 'WARNING' })
    Write-WocLine "Healthy?       $(if ($report.Score -ge 90) { 'Yes' } else { 'Review needed' })" $(if ($report.Score -ge 90) { 'Green' } else { 'Yellow' })
    Write-WocLine "Broken?        $(if ($report.ValidationFails -eq 0) { 'No failed checks' } else { "$($report.ValidationFails) failure(s)" })" $(if ($report.ValidationFails -eq 0) { 'Green' } else { 'Red' })
    Write-WocLine "Missing?       $(@($report.Health | Where-Object Status -ne 'OK').Count) subsystem warning(s)" 'DarkGray'
    Write-WocLine "Maintenance?   $(if ($report.Maintenance.DaysSinceMaintenance -gt 7) { 'Due' } elseif ($report.Maintenance.DaysSinceMaintenance) { "$($report.Maintenance.DaysSinceMaintenance)d ago" } else { 'Not run' })" 'DarkGray'
    Write-WocLine "Backups?       $(if ($report.Backup.Status -eq 'OK') { 'Current' } else { 'Attention needed' })" $(if ($report.Backup.Status -eq 'OK') { 'Green' } else { 'Yellow' })
    Write-WocLine "Updates?       $(if ($report.Maintenance.PendingUpdates) { "$($report.Maintenance.PendingUpdates) pending" } else { 'Unknown / none cached' })" 'DarkGray'
    Write-WocLine "Terminal?      $(@($report.Health | Where-Object { $_.Name -match 'Profile|Font|Terminal|OMP' -and $_.Status -eq 'OK' }).Count)/4 core OK" 'DarkGray'
    Write-WocLine "Security?      $(@($report.Security | Where-Object Status -eq 'OK').Count)/$($report.Security.Count) checks OK" 'DarkGray'

    if ($mode -eq 'minimal') {
        Write-WocLine "Next: $($report.Recommendations | Select-Object -First 1)" 'Yellow'
        $sw.Stop()
        Write-Host ""
        return
    }

    # HEALTH
    $hLevel = if ($report.Health | Where-Object Status -eq 'ERROR') { 'ERROR' } elseif ($report.Health | Where-Object Status -eq 'WARNING') { 'WARNING' } else { 'OK' }
    Write-WocSection 'HEALTH' $hLevel
    $report.Health | ForEach-Object { Write-WocCheckLine $_ }

    # PERFORMANCE
    $pLevel = if ($report.Performance.HighRam -or $report.Performance.HighCpu) { 'WARNING' } else { 'OK' }
    Write-WocSection 'PERFORMANCE' $pLevel
    Write-WocLine "Profile load (cached)  $($report.Performance.ProfileMs) ms$(if($report.Performance.SlowStartup){' — SLOW'})" $(if ($report.Performance.SlowStartup) { 'Yellow' } else { 'DarkGray' })
    Write-WocLine "CPU                    $(if($null -ne $report.Performance.CpuPct){"$($report.Performance.CpuPct)%"}else{'not cached'})" 'DarkGray'
    Write-WocLine "Memory                 $(if($null -ne $report.Performance.MemPct){"$($report.Performance.MemPct)%$(if($report.Performance.HighRam){' — HIGH'})"}else{'not cached'})" $(if ($report.Performance.HighRam) { 'Yellow' } else { 'DarkGray' })
    Write-WocLine "Disk free              $($report.Performance.DiskFreeGB) GB ($($report.Performance.DiskFreePct)%)" 'DarkGray'
    Write-WocLine "Uptime / Boot          $($report.Performance.Uptime) / $($report.Performance.BootTime)" 'DarkGray'
    if ($report.Performance.TopProcesses) {
        Write-WocLine "Top processes (cached) $($report.Performance.TopProcesses -join ' · ')" 'DarkGray'
    }

    # SECURITY
    $sLevel = if ($report.Security | Where-Object Status -eq 'ERROR') { 'ERROR' } elseif ($report.Security | Where-Object Status -eq 'WARNING') { 'WARNING' } else { 'OK' }
    Write-WocSection 'SECURITY' $sLevel
    $report.Security | ForEach-Object { Write-WocCheckLine $_ }

    # BACKUPS
    Write-WocSection 'BACKUPS' $report.Backup.Status
    Write-WocLine "Latest snapshot        $($report.Backup.Latest ?? 'none')" 'DarkGray'
    Write-WocLine "Age                    $($report.Backup.DaysAgo ?? '—') days" $(if ($report.Backup.DaysAgo -gt 14) { 'Yellow' } else { 'DarkGray' })
    Write-WocLine "Snapshots              $($report.Backup.Count)" 'DarkGray'
    Write-WocLine "Size                   $($report.Backup.SizeMB) MB" 'DarkGray'
    Write-WocLine "Last restore test      $($report.Backup.RestoreTest)" 'DarkGray'
    if ($report.Backup.DaysAgo -gt 14) {
        Write-WocAlert 'WARNING' 'Backups are older than 14 days.' 'Run backupconfig'
    }

    # DEVELOPMENT
    Write-WocSection 'DEVELOPMENT' 'OK'
    $report.Development | ForEach-Object { Write-WocCheckLine $_ }

    # NETWORK
    Write-WocSection 'NETWORK' 'OK'
    Write-WocLine "Adapter                $($report.Network.Adapter) ($($report.Network.Connectivity))" 'DarkGray'
    Write-WocLine "Local IP               $($report.Network.LocalIP)" 'DarkGray'
    Write-WocLine "Public IP              $($report.Network.PublicIP)" 'DarkGray'
    Write-WocLine "Gateway                $($report.Network.Gateway)" 'DarkGray'
    Write-WocLine "DNS                    $($report.Network.DNS)" 'DarkGray'
    Write-WocLine "Profile                $($report.Network.Profile)" 'DarkGray'

    # MAINTENANCE / DAILY SUMMARY
    Write-WocSection 'MAINTENANCE' 'OK'
    Write-WocLine "Days since maintenance $($report.Maintenance.DaysSinceMaintenance ?? '—')" 'DarkGray'
    Write-WocLine "Days since backup      $($report.Maintenance.DaysSinceBackup ?? '—')" 'DarkGray'
    Write-WocLine "Days since update chk  $($report.Maintenance.DaysSinceUpdate ?? '—')" 'DarkGray'
    Write-WocLine "Days since reboot      $($report.Maintenance.DaysSinceReboot ?? '—')" 'DarkGray'

    # CHANGES
    Write-WocSection 'CHANGES SINCE LAST SESSION' 'OK'
    $report.Changes | ForEach-Object { Write-WocLine $_ 'DarkGray' }

    # RECOMMENDATIONS
    Write-WocSection "TODAY'S RECOMMENDATIONS" 'OK'
    $report.Recommendations | Select-Object -First 5 | ForEach-Object { Write-WocLine "→ $_" 'Yellow' }

    Write-WocActionCenter

    $sw.Stop()
    if ($sw.ElapsedMilliseconds -gt 1000) {
        Write-WocLine "Loaded in $($sw.ElapsedMilliseconds)ms — run Invoke-Maintenance.ps1 -Full to refresh cache" 'DarkGray'
    }
    Write-Host ""
}
