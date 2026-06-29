#Requires -Version 7.0
<#
.SYNOPSIS
    Safe automated maintenance — logs, backups, health report.
#>
param(
    [switch]$Full,
    [switch]$WhatIf
)

. (Join-Path $PSScriptRoot '..\_Resolve-RepoRoot.ps1')
$repoRoot = Resolve-WorkstationRepoRoot -Start $PSScriptRoot

$ErrorActionPreference = 'Continue'
. "$repoRoot\lib\WorkstationCommon.ps1"

Write-WorkstationStep 'Maintenance started'

# 1. Health report
Write-WorkstationStep 'Health check'
& "$repoRoot\Validate-Workstation.ps1" -StartupBudgetMs 650 | Out-Null
$healthOk = ($LASTEXITCODE -eq 0)

# 2. Log cleanup
Write-WorkstationStep 'Log rotation'
& "$repoRoot\Invoke-Housekeeping.ps1" -WhatIf:$WhatIf

# 3. Config backup (weekly)
$lastBackup = Get-ChildItem 'C:\Backups\Workstation' -Directory -ErrorAction SilentlyContinue |
    Sort-Object Name -Descending | Select-Object -First 1
$backupAge = if ($lastBackup) { ((Get-Date) - $lastBackup.CreationTime).TotalDays } else { 999 }
if ($Full -or $backupAge -gt 7) {
    Write-WorkstationStep 'Configuration backup'
    & "$repoRoot\Backup-Configuration.ps1" -Force
}

# 4. Disk space + memory snapshot (for dashboard cache)
Write-WorkstationStep 'System metrics cache'
$disk = Get-PSDrive C
$freeGB = [math]::Round($disk.Free / 1GB, 1)
$memPct = 0
try {
    $os = Get-CimInstance Win32_OperatingSystem
    $memPct = [math]::Round((1 - $os.FreePhysicalMemory / $os.TotalVisibleMemorySize) * 100)
    $uptimeH = [math]::Round(((Get-Date) - $os.LastBootUpTime).TotalHours, 1)
} catch { $uptimeH = 0 }
Write-WorkstationLog "C: free ${freeGB} GB"
if ($freeGB -lt 10) { Write-WorkstationLog 'Low disk space on C:' 'WARN' }

# 5. PATH dedupe check
$userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
$segments = $userPath -split ';' | Where-Object { $_ }
$dupes = $segments | Group-Object | Where-Object Count -gt 1
if ($dupes) {
    Write-WorkstationLog 'Duplicate PATH entries detected — run Fix-WorkstationPath.ps1' 'WARN'
}

Write-WorkstationStep 'Maintenance complete'
# 5. Jarvis cache + security flags for dashboard
Write-WorkstationStep 'Jarvis cache update'
$secFlags = @()
try {
    $inbound = Get-NetFirewallProfile -EA Stop | Where-Object { $_.DefaultInboundAction -ne 'Block' }
    if ($inbound) { $secFlags += 'inbound-open' }
    $def = Get-Service WinDefend -EA SilentlyContinue
    if ($def -and $def.Status -eq 'Running') { $secFlags += 'defender-on' }
} catch { $secFlags += 'audit-skipped' }

$pendingUpdates = $null
$cpuPct = $null
$publicIP = $null
$networkUp = $null
if ($Full) {
    try {
        $wu = winget upgrade --include-unknown 2>&1 | Select-String 'upgrades available'
        if ($wu -match '(\d+)') { $pendingUpdates = [int]$Matches[1] }
    } catch { }
    try {
        $cpuPct = (Get-CimInstance Win32_Processor -OperationTimeoutSec 3 | Measure-Object LoadPercentage -Average).Average
    } catch { }
    try {
        $publicIP = (Invoke-RestMethod -Uri 'https://api.ipify.org?format=json' -TimeoutSec 5).ip
    } catch { }
}
try {
    $networkUp = @(Get-NetAdapter -EA SilentlyContinue | Where-Object Status -eq 'Up').Count
} catch { }

$diskUsedPct = $null
if ($disk -and ($disk.Used + $disk.Free)) {
    $diskUsedPct = [math]::Round(100 * $disk.Used / ($disk.Used + $disk.Free), 1)
}

@{
    Timestamp       = (Get-Date).ToString('o')
    HealthOk        = $healthOk
    FreeGB          = $freeGB
    MemPct          = $memPct
    UptimeH         = $uptimeH
    SecurityFlags   = $secFlags
    PendingUpdates  = $pendingUpdates
    CpuPct          = $cpuPct
    PublicIP        = $publicIP
    NetworkUp       = $networkUp
    DiskUsedPct     = $diskUsedPct
} | ConvertTo-Json | Set-Content (Join-Path 'C:\Logs\Workstation' 'maintenance-last.json') -Encoding UTF8

@{
    Timestamp   = (Get-Date).ToString('o')
    CpuPct      = $cpuPct
    MemPct      = $memPct
    PublicIP    = $publicIP
    NetworkUp   = $networkUp
    DiskUsedPct = $diskUsedPct
    FreeGB      = $freeGB
    SecurityFlags = $secFlags
    PendingUpdates = $pendingUpdates
} | ConvertTo-Json | Set-Content (Join-Path 'C:\Logs\Workstation' 'startup-cache.json') -Encoding UTF8

# WOC extended cache (populated during maintenance — WOC reads this at startup)
$topProc = @()
$netProfile = $null
$secChecks = @()
$networkCached = $null
$backupSummary = $null
$daysSinceReboot = $null
$bootTimeStr = $null

try {
    $topProc = @(Get-Process -EA SilentlyContinue | Sort-Object CPU -Descending | Select-Object -First 3 |
        ForEach-Object { "{0}({1}% CPU)" -f $_.Name, [math]::Round($_.CPU, 1) })
} catch { }

try {
    Get-NetFirewallProfile -EA Stop | ForEach-Object {
        $st = if ($_.Enabled -and $_.DefaultInboundAction -eq 'Block') { 'OK' }
              elseif ($_.Enabled) { 'WARNING' } else { 'ERROR' }
        $secChecks += @{ Name = "Firewall $($_.Name)"; Status = $st; Detail = "inbound=$($_.DefaultInboundAction)" }
    }
} catch { $secChecks += @{ Name = 'Firewall'; Status = 'WARNING'; Detail = 'audit skipped' } }

try {
    $uac = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' -EA Stop
    $secChecks += @{ Name = 'UAC'; Status = $(if ($uac.EnableLUA -eq 1) { 'OK' } else { 'ERROR' }); Detail = 'enabled' }
} catch { }

try {
    $adapters = @(Get-NetAdapter -EA SilentlyContinue | Where-Object Status -eq 'Up')
    $ip = Get-NetIPAddress -AddressFamily IPv4 -EA SilentlyContinue |
        Where-Object { $_.IPAddress -notlike '127.*' -and $_.PrefixOrigin -ne 'WellKnown' } | Select-Object -First 1
    $dns = (Get-DnsClientServerAddress -AddressFamily IPv4 -EA SilentlyContinue |
        Where-Object ServerAddresses | Select-Object -First 1).ServerAddresses
    $gw = (Get-NetRoute -DestinationPrefix '0.0.0.0/0' -EA SilentlyContinue | Select-Object -First 1).NextHop
    $np = Get-NetConnectionProfile -EA SilentlyContinue | Select-Object -First 1
    if ($np) { $netProfile = "$($np.NetworkCategory) — $($np.Name)" }
    $networkCached = @{
        Adapter = ($adapters | Select-Object -First 1 -ExpandProperty Name)
        AdapterCount = $adapters.Count
        LocalIP = $ip.IPAddress
        PublicIP = $publicIP
        DNS = ($dns -join ', ')
        Gateway = $gw
        Connectivity = if ($adapters.Count) { 'connected' } else { 'offline' }
        Profile = if ($np) { "$($np.NetworkCategory) ($($np.Name))" } else { $netProfile }
    }
} catch { }

$bakRoot = 'C:\Backups\Workstation'
$bakDirs = @(Get-ChildItem $bakRoot -Directory -EA SilentlyContinue | Sort-Object Name -Descending)
$bakLatest = $bakDirs | Select-Object -First 1
if ($bakLatest) {
    $bakDays = [math]::Round(((Get-Date) - $bakLatest.CreationTime).TotalDays, 1)
    $bakSize = [math]::Round((Get-ChildItem $bakLatest.FullName -Recurse -File -EA SilentlyContinue | Measure-Object Length -Sum).Sum / 1MB, 1)
    $backupSummary = @{
        Count = $bakDirs.Count; Latest = $bakLatest.Name; DaysAgo = $bakDays
        SizeMB = $bakSize; Status = if ($bakDays -gt 14) { 'WARNING' } else { 'OK' }
        RestoreTest = 'never recorded'
    }
}

try {
    $os = Get-CimInstance Win32_OperatingSystem
    $bootTimeStr = $os.LastBootUpTime.ToString('yyyy-MM-dd HH:mm')
    $daysSinceReboot = [math]::Round(((Get-Date) - $os.LastBootUpTime).TotalDays, 1)
} catch { }

@{
    Timestamp        = (Get-Date).ToString('o')
    CpuPct           = $cpuPct
    MemPct           = $memPct
    PublicIP         = $publicIP
    NetworkUp        = $networkUp
    NetworkProfile   = $netProfile
    TopProcesses     = $topProc
    BootTime         = $bootTimeStr
    LastUpdateCheck  = if ($Full) { (Get-Date).ToString('o') } else { $null }
    DaysSinceReboot  = $daysSinceReboot
    SecurityChecks   = $secChecks
    BackupSummary    = $backupSummary
    NetworkCached    = $networkCached
} | ConvertTo-Json -Depth 6 | Set-Content (Join-Path 'C:\Logs\Workstation' 'woc-cache.json') -Encoding UTF8

exit $(if ($healthOk) { 0 } else { 1 })
