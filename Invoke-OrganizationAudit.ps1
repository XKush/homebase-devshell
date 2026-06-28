#Requires -Version 7.0
<#
.SYNOPSIS
    Phase 1 — Complete workstation organization audit (read-only).
#>
param([string]$OutputDir = 'C:\Logs\Workstation')

$ErrorActionPreference = 'Continue'
. "$PSScriptRoot\lib\WorkstationCommon.ps1"

$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
if (-not (Test-Path $OutputDir)) { New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null }

Write-WorkstationStep 'Organization audit — scanning workstation'

$report = [ordered]@{
    Timestamp = (Get-Date).ToString('o')
    Issues    = [System.Collections.Generic.List[string]]::new()
    Findings  = [ordered]@{}
    Plan      = [System.Collections.Generic.List[string]]::new()
}

function Add-Issue([string]$Msg) { $report.Issues.Add($Msg) }
function Add-Plan([string]$Msg)  { $report.Plan.Add($Msg) }

# ── Standard folders ─────────────────────────────────────────────────────────
$standard = @(
    'C:\Tools', 'C:\Scripts', 'C:\Projects', 'C:\Security', 'C:\Networking',
    'C:\Logs', 'C:\Backups', 'C:\Configs', 'C:\Temp',
    'C:\Downloads\Archive', 'C:\Logs\Workstation', 'C:\Logs\Networking',
    'C:\Backups\Workstation', 'C:\Configs\Workstation', 'C:\Networking\Tools'
)
$missing = @($standard | Where-Object { -not (Test-Path $_) })
$report.Findings.StandardFolders = @{ Expected = $standard; Missing = $missing }
foreach ($m in $missing) { Add-Issue "Missing folder: $m"; Add-Plan "Create $m" }

# ── PATH clutter ─────────────────────────────────────────────────────────────
$userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
$machinePath = [Environment]::GetEnvironmentVariable('Path', 'Machine')
$userSegs = @($userPath -split ';' | Where-Object { $_ })
$machineSegs = @($machinePath -split ';' | Where-Object { $_ })
$userDupes = @($userSegs | Group-Object | Where-Object Count -gt 1 | ForEach-Object { $_.Name })
$machineDupes = @($machineSegs | Group-Object | Where-Object Count -gt 1 | ForEach-Object { $_.Name })
$report.Findings.Path = @{
    UserSegments    = $userSegs.Count
    MachineSegments = $machineSegs.Count
    UserDuplicates  = $userDupes
    MachineDuplicates = $machineDupes
}
if ($userDupes)   { Add-Issue "PATH user duplicates: $($userDupes.Count)"; Add-Plan 'Run Fix-WorkstationPath.ps1' }
if ($machineDupes){ Add-Issue "PATH machine duplicates: $($machineDupes.Count)" }

# ── Duplicate profile files ──────────────────────────────────────────────────
$profiles = @(
    'C:\Scripts\Workstation\profile\Microsoft.PowerShell_profile.ps1',
    (Join-Path $env:USERPROFILE 'Documents\PowerShell\Microsoft.PowerShell_profile.ps1'),
    (Join-Path $env:USERPROFILE 'Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1'),
    (Join-Path $env:USERPROFILE 'PowerShell\profile.ps1')
)
$hashes = @{}
$profileDupes = [System.Collections.Generic.List[string]]::new()
foreach ($p in $profiles) {
    if (-not (Test-Path $p)) { continue }
    $h = (Get-FileHash $p -Algorithm SHA256).Hash
    if ($hashes.ContainsKey($h)) { $profileDupes.Add("$p duplicates $($hashes[$h])") }
    else { $hashes[$h] = $p }
}
$report.Findings.ProfileFiles = @{ Paths = $profiles; DuplicateNotes = @($profileDupes) }

# ── Empty folders (workstation roots only) ───────────────────────────────────
$empty = [System.Collections.Generic.List[string]]::new()
foreach ($root in @('C:\Tools','C:\Scripts','C:\Projects','C:\Security','C:\Networking','C:\Logs','C:\Backups','C:\Configs','C:\Temp')) {
    if ((Test-Path $root) -and -not (Get-ChildItem $root -Force -EA SilentlyContinue)) {
        $empty.Add($root)
    }
}
$report.Findings.EmptyFolders = @($empty)

# ── Desktop / Downloads clutter ───────────────────────────────────────────────
$desktop = Join-Path $env:USERPROFILE 'Desktop'
$downloads = Join-Path $env:USERPROFILE 'Downloads'
$clutter = [ordered]@{}
foreach ($label in @('Desktop','Downloads')) {
    $path = if ($label -eq 'Desktop') { $desktop } else { $downloads }
    if (-not (Test-Path $path)) { continue }
    $items = Get-ChildItem $path -Force -EA SilentlyContinue
    $installers = @($items | Where-Object { $_.Extension -match '\.(exe|msi|msix|zip|7z)$' })
    $shortcuts = @($items | Where-Object { $_.Extension -eq '.lnk' })
    $old = @($items | Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-90) -and -not $_.PSIsContainer })
    $clutter[$label] = @{
        TotalItems   = @($items).Count
        Installers   = @($installers | Select-Object Name, Length, LastWriteTime)
        Shortcuts    = @($shortcuts | Select-Object Name)
        OldFiles90d  = @($old | Select-Object Name, LastWriteTime)
    }
    if ($installers.Count -gt 0) { Add-Plan "Archive $($installers.Count) installer(s) from $label" }
    if ($shortcuts.Count -gt 5)  { Add-Issue "$label has $($shortcuts.Count) shortcuts — review clutter" }
}
$report.Findings.Clutter = $clutter

# ── Old logs ─────────────────────────────────────────────────────────────────
$logRoots = @('C:\Logs\Workstation', 'C:\Logs')
$oldLogs = [System.Collections.Generic.List[object]]::new()
foreach ($lr in $logRoots) {
    if (-not (Test-Path $lr)) { continue }
    Get-ChildItem $lr -Recurse -File -EA SilentlyContinue |
        Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-60) -and $_.Length -gt 0 } |
        ForEach-Object { $oldLogs.Add([ordered]@{ Path = $_.FullName; SizeKB = [math]::Round($_.Length/1KB,1); Age = ((Get-Date)-$_.LastWriteTime).Days }) }
}
$report.Findings.OldLogs = @($oldLogs | Select-Object -First 50)
if ($oldLogs.Count -gt 10) { Add-Plan 'Rotate logs older than 60 days via Invoke-Housekeeping.ps1' }

# ── Obsolete backups ─────────────────────────────────────────────────────────
$bakRoot = 'C:\Backups\Workstation'
$backups = @()
if (Test-Path $bakRoot) {
    $backups = Get-ChildItem $bakRoot -Directory -EA SilentlyContinue | Sort-Object Name
    $report.Findings.Backups = @{
        Count = @($backups).Count
        Oldest = ($backups | Select-Object -First 1).Name
        Newest = ($backups | Select-Object -Last 1).Name
        Excess = @($backups | Select-Object -Skip 8 | Select-Object -ExpandProperty Name)
    }
    if ($backups.Count -gt 8) { Add-Plan "Rotate backups — keep latest 8 ($($backups.Count) present)" }
}

# ── Temp files ───────────────────────────────────────────────────────────────
$tempDirs = @('C:\Temp', $env:TEMP, (Join-Path $env:LOCALAPPDATA 'Temp'))
$tempStats = @{}
foreach ($td in $tempDirs | Select-Object -Unique) {
    if (-not (Test-Path $td)) { continue }
    $files = Get-ChildItem $td -Recurse -File -EA SilentlyContinue
    $tempStats[$td] = @{
        Files = @($files).Count
        SizeMB = [math]::Round((@($files | Measure-Object Length -Sum).Sum / 1MB), 1)
    }
}
$report.Findings.TempFiles = $tempStats
$bigTemp = $tempStats.GetEnumerator() | Where-Object { $_.Value.SizeMB -gt 100 }
if ($bigTemp) { Add-Plan 'Clean temp files via Invoke-Housekeeping.ps1 (with report)' }

# ── Broken shortcuts ─────────────────────────────────────────────────────────
$broken = [System.Collections.Generic.List[object]]::new()
$shell = New-Object -ComObject WScript.Shell
foreach ($scan in @($desktop, $downloads)) {
    if (-not (Test-Path $scan)) { continue }
    Get-ChildItem $scan -Filter '*.lnk' -EA SilentlyContinue | ForEach-Object {
        try {
            $lnk = $shell.CreateShortcut($_.FullName)
            if ($lnk.TargetPath -and -not (Test-Path $lnk.TargetPath)) {
                $broken.Add([ordered]@{ Shortcut = $_.FullName; Target = $lnk.TargetPath })
            }
        } catch { }
    }
}
$report.Findings.BrokenShortcuts = @($broken)
foreach ($b in $broken) { Add-Issue "Broken shortcut: $($b.Shortcut)"; Add-Plan "Archive broken shortcut: $($b.Shortcut)" }

# ── Duplicate scripts (hash) ─────────────────────────────────────────────────
$scriptRoots = @('C:\Scripts\Workstation', 'C:\Scripts')
$scriptHashes = @{}
$dupScripts = [System.Collections.Generic.List[string]]::new()
foreach ($sr in $scriptRoots) {
    if (-not (Test-Path $sr)) { continue }
    Get-ChildItem $sr -Recurse -Filter '*.ps1' -EA SilentlyContinue | ForEach-Object {
        $h = (Get-FileHash $_.FullName -Algorithm SHA256).Hash
        if ($scriptHashes.ContainsKey($h) -and $scriptHashes[$h] -ne $_.FullName) {
            $dupScripts.Add("$($_.FullName) == $($scriptHashes[$h])")
        } else { $scriptHashes[$h] = $_.FullName }
    }
}
$report.Findings.DuplicateScripts = @($dupScripts)

# ── Tool duplicates (multiple installs) ──────────────────────────────────────
$toolNames = @('git','python','pwsh','nmap','wireshark','rg','code')
$toolPaths = @{}
$toolDupes = [System.Collections.Generic.List[string]]::new()
foreach ($t in $toolNames) {
    $cmds = @(Get-Command $t -All -EA SilentlyContinue)
    if ($cmds.Count -gt 1) { $toolDupes.Add("$t : $($cmds.Source -join ' | ')") }
    elseif ($cmds) { $toolPaths[$t] = $cmds[0].Source }
}
$report.Findings.ToolPaths = $toolPaths
$report.Findings.DuplicateTools = @($toolDupes)

# ── Scheduled tasks ───────────────────────────────────────────────────────────
$wsTask = Get-ScheduledTask -TaskName 'ReviOS-Workstation-Maintenance' -EA SilentlyContinue
$report.Findings.ScheduledTask = if ($wsTask) { $wsTask.TaskName } else { $null }
if (-not $wsTask) { Add-Issue 'ReviOS-Workstation-Maintenance not registered'; Add-Plan 'Register-MaintenanceTask.ps1 (admin)' }

# ── Unused configs ───────────────────────────────────────────────────────────
$oldConfigs = @()
$configScan = @(
    (Join-Path $env:LOCALAPPDATA 'Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState'),
    'C:\Configs'
)
foreach ($cs in $configScan) {
    if (-not (Test-Path $cs)) { continue }
    Get-ChildItem $cs -Filter '*.bak' -Recurse -EA SilentlyContinue | ForEach-Object {
        $oldConfigs += $_.FullName
    }
}
$report.Findings.OrphanConfigBackups = @($oldConfigs | Select-Object -First 20)

# ── Summary plan ─────────────────────────────────────────────────────────────
if (-not $report.Plan.Count) { Add-Plan 'No changes required — workstation already organized' }

$outJson = Join-Path $OutputDir "organization-audit-$stamp.json"
$outPlan = Join-Path $OutputDir "organization-plan-$stamp.md"

$report | ConvertTo-Json -Depth 8 | Set-Content $outJson -Encoding UTF8

$md = @"
# Organization Audit — KGreen
**Generated:** $($report.Timestamp)

## Issues ($($report.Issues.Count))
$(
    if ($report.Issues.Count) { ($report.Issues | ForEach-Object { "- $_" }) -join "`n" }
    else { '- None' }
)

## Plan (execute via Invoke-WorkstationOrganization.ps1)
$(
    ($report.Plan | ForEach-Object { "- $_" }) -join "`n"
)

## Clutter summary
- Desktop items: $($clutter.Desktop.TotalItems)
- Downloads items: $($clutter.Downloads.TotalItems)
- Empty workstation folders: $($empty.Count)
- Broken shortcuts: $($broken.Count)

Full JSON: ``$outJson``
"@
Set-Content $outPlan $md -Encoding UTF8

Write-Host ""
Write-Host "Organization audit: $($report.Issues.Count) issues, $($report.Plan.Count) planned actions" -ForegroundColor $(if ($report.Issues.Count -eq 0) { 'Green' } else { 'Yellow' })
Write-Host "  $outJson" -ForegroundColor DarkGray
Write-Host "  $outPlan" -ForegroundColor DarkGray

exit $(if ($report.Issues.Count -eq 0) { 0 } else { 1 })
