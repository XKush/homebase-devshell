# Windows status — privacy, performance, security snapshot

function Get-RegistryDword {
    param([string]$Path, [string]$Name)
    try {
        $v = Get-ItemProperty -Path $Path -Name $Name -ErrorAction Stop
        return $v.$Name
    } catch { return $null }
}

function Get-WindowsStatusReport {
    $report = [ordered]@{
        Timestamp = (Get-Date).ToString('o')
        Privacy   = [ordered]@{}
        Performance = [ordered]@{}
        Security  = [ordered]@{}
        Maintenance = [ordered]@{}
        Score     = 100
        Warnings  = [System.Collections.Generic.List[string]]::new()
    }

    $tel = Get-RegistryDword 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection' 'AllowTelemetry'
    $report.Privacy.Telemetry = if ($tel -eq 0) { 'minimal/disabled' } elseif ($null -eq $tel) { 'default' } else { "level $tel" }
    $report.Privacy.AdvertisingId = Get-RegistryDword 'HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo' 'Enabled'
    if ($report.Privacy.AdvertisingId -ne 0 -and $null -ne $report.Privacy.AdvertisingId) {
        $report.Warnings.Add('Advertising ID enabled')
        $report.Score -= 5
    }

    $dns = Get-DnsClientServerAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue |
        Where-Object { $_.ServerAddresses } | Select-Object -First 1
    $report.Privacy.Dns = if ($dns) { ($dns.ServerAddresses -join ', ') + " ($($dns.InterfaceAlias))" } else { 'unknown' }

    foreach ($svc in @('SysMain', 'WSearch', 'DiagTrack')) {
        $s = Get-Service -Name $svc -ErrorAction SilentlyContinue
        if ($s) { $report.Performance[$svc] = $s.StartType.ToString() }
    }

    try {
        $startup = @(Get-CimInstance Win32_StartupCommand -ErrorAction Stop)
        $report.Performance.StartupApps = $startup.Count
        if ($startup.Count -gt 8) {
            $report.Warnings.Add("$($startup.Count) startup apps — review Task Manager")
            $report.Score -= 4
        }
    } catch { $report.Performance.StartupApps = 'unknown' }

    try {
        $fw = Get-NetFirewallProfile -ErrorAction Stop
        $report.Security.FirewallProfiles = @($fw | ForEach-Object {
            "$($_.Name): inbound=$($_.DefaultInboundAction) enabled=$($_.Enabled)"
        })
        $openInbound = @($fw | Where-Object { $_.DefaultInboundAction -ne 'Block' })
        if ($openInbound.Count) {
            $report.Warnings.Add('Firewall inbound not Block on: ' + ($openInbound.Name -join ', '))
            $report.Score -= 8
        }
    } catch { $report.Security.FirewallProfiles = @('audit skipped') }

    $def = Get-Service WinDefend -ErrorAction SilentlyContinue
    $report.Security.Defender = if ($def) { $def.Status.ToString() } else { 'absent' }

    $uac = Get-RegistryDword 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' 'EnableLUA'
    $report.Security.UAC = if ($uac -eq 1) { 'enabled' } else { 'disabled/warn' }
    if ($uac -ne 1) { $report.Warnings.Add('UAC not enabled'); $report.Score -= 10 }

    try {
        $rp = Get-ComputerRestorePoint -ErrorAction Stop | Sort-Object CreationTime -Descending | Select-Object -First 1
        if ($rp) {
            $report.Maintenance.LastRestorePoint = $rp.CreationTime.ToString('yyyy-MM-dd')
            $days = ((Get-Date) - $rp.CreationTime).TotalDays
            if ($days -gt 30) {
                $report.Warnings.Add('Restore point older than 30 days')
                $report.Score -= 3
            }
        } else {
            $report.Warnings.Add('No restore points — enable System Protection on C:')
            $report.Score -= 5
        }
    } catch { $report.Maintenance.LastRestorePoint = 'unknown' }

    $backups = Get-ChildItem 'C:\Backups\Workstation' -Directory -ErrorAction SilentlyContinue |
        Sort-Object Name -Descending | Select-Object -First 1
    $report.Maintenance.LatestConfigBackup = if ($backups) { $backups.Name } else { 'none' }

    try {
        $wu = winget upgrade --include-unknown 2>&1 | Out-String
        if ($wu -match '(\d+)\s+upgrade') { $report.Maintenance.PendingWingetUpgrades = [int]$Matches[1] }
        elseif ($wu -match 'No installed package') { $report.Maintenance.PendingWingetUpgrades = 0 }
    } catch { $report.Maintenance.PendingWingetUpgrades = 'unknown' }

    if ($report.Maintenance.PendingWingetUpgrades -is [int] -and $report.Maintenance.PendingWingetUpgrades -gt 5) {
        $report.Warnings.Add("$($report.Maintenance.PendingWingetUpgrades) winget upgrades pending")
        $report.Score -= 3
    }

    $report.Score = [math]::Max(0, [math]::Min(100, $report.Score))
    $report.WarningCount = $report.Warnings.Count
    return [PSCustomObject]$report
}

function Show-WindowsStatus {
    param([switch]$Quiet)

    $r = Get-WindowsStatusReport
    if ($Quiet) { return $r }

    $P = if (Get-Command Get-HackerPalette -ErrorAction SilentlyContinue) { Get-HackerPalette } else { @{ Cyan = 'Cyan'; Muted = 'DarkGray'; Warn = 'Yellow'; TrustOk = 'Green'; Alert = 'Red' } }

    if (Get-Command Write-HackerSection -ErrorAction SilentlyContinue) {
        Write-Host ''
        Write-HackerSection -Tag 'WIN' -Title 'WINDOWS STATUS — privacy · perf · security' -Color $P.Cyan
        $scoreCol = if ($r.Score -ge 90) { $P.TrustOk } elseif ($r.Score -ge 70) { $P.Warn } else { $P.Alert }
        Write-HackerStat 'SCORE' (Format-HackerBar -Percent $r.Score -Label $(if ($r.Score -ge 90) { 'NOMINAL' } elseif ($r.Score -ge 70) { 'DEGRADED' } else { 'ATTENTION' })) -Color $scoreCol
        Write-HackerStat 'TELEMETRY' $r.Privacy.Telemetry -Color $P.Muted
        Write-HackerStat 'DNS' $r.Privacy.Dns -Color $P.Muted
        Write-HackerStat 'STARTUP' "$($r.Performance.StartupApps) apps" -Color $P.Muted
        Write-HackerStat 'DEFENDER' $r.Security.Defender -Color $P.Muted
        Write-HackerStat 'UAC' $r.Security.UAC -Color $(if ($r.Security.UAC -eq 'enabled') { $P.TrustOk } else { $P.Alert })
        Write-HackerStat 'BACKUP' ($r.Maintenance.LatestConfigBackup ?? 'none') -Color $P.Muted
        if ($r.Maintenance.PendingWingetUpgrades -ne 'unknown') {
            Write-HackerStat 'UPDATES' "$($r.Maintenance.PendingWingetUpgrades) winget" -Color $P.Muted
        }
        if ($r.Warnings.Count) {
            Write-Host ''
            $r.Warnings | ForEach-Object { Write-HackerLine "[!!] $_" -Color $P.Warn }
        }
        Write-HackerLine '>> Configure-Privacy · Optimize-Performance · Invoke-WindowsTunePass.ps1' -Color $P.Muted
        Write-Host ''
    } else {
        Write-Host "`n  Windows Status — score $($r.Score)/100" -ForegroundColor Cyan
        $r.Warnings | ForEach-Object { Write-Host "  ! $_" -ForegroundColor Yellow }
        Write-Host ''
    }
    return $r
}

function windowsstatus {
    param([switch]$Help, [switch]$Quiet)
    if (Test-ShowCommandHelp -Name 'windowsstatus' -Help:$Help) { return }
    Invoke-WorkstationCmd 'windowsstatus' { Show-WindowsStatus -Quiet:$Quiet }
}
