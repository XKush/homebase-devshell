#Requires -Version 7.0
<#
.SYNOPSIS
    Phase 5 — Safe automated housekeeping with pre-clean report.
#>
param(
    [int]$LogKeepDays = 60,
    [int]$BackupKeepCount = 8,
    [int]$TempKeepDays = 14,
    [int]$LargeFileMB = 500,
    [switch]$WhatIf,
    [switch]$IncludeTemp
)

$ErrorActionPreference = 'Continue'
. "$PSScriptRoot\lib\WorkstationCommon.ps1"

$logsRoot = Get-WorkstationLogsRoot
$backupsRoot = Get-WorkstationBackupsRoot

$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$reportDir = $logsRoot
$bakDir = Join-Path $backupsRoot "housekeeping-$stamp"
$report = [ordered]@{
    Timestamp = (Get-Date).ToString('o')
    WhatIf    = [bool]$WhatIf
    Actions   = [System.Collections.Generic.List[object]]::new()
    Skipped   = [System.Collections.Generic.List[string]]::new()
}

function Log([string]$Action, [string]$Detail, [long]$Bytes = 0) {
    $report.Actions.Add([ordered]@{ Action = $Action; Detail = $Detail; Bytes = $Bytes })
    $msg = if ($Bytes) { "$Action — $Detail ($([math]::Round($Bytes/1MB,1)) MB)" } else { "$Action — $Detail" }
    Write-WorkstationLog $msg $(if ($WhatIf) { 'INFO' } else { 'OK' })
}

Write-WorkstationStep 'Housekeeping — generating pre-clean report'

if (-not $WhatIf) { New-Item -ItemType Directory -Force -Path $bakDir | Out-Null }

# ── 1. Old validation logs (keep latest 15) ───────────────────────────────────
$valDir = $logsRoot
if (Test-Path $valDir) {
    $old = Get-ChildItem $valDir -Filter 'validation-*.json' | Sort-Object Name -Descending | Select-Object -Skip 15
    foreach ($f in $old) {
        if ($WhatIf) { Log 'WouldRemove' $f.Name $f.Length; continue }
        Copy-Item $f.FullName (Join-Path $bakDir $f.Name) -Force -EA SilentlyContinue
        Remove-Item $f.FullName -Force
        Log 'RemoveOldValidation' $f.Name $f.Length
    }
}

# ── 2. Rotate audit/discovery JSON (keep 20 each pattern) ─────────────────────
foreach ($pat in @('organization-audit-*','discovery-*','post-audit-*','tools-inventory-*','housekeeping-*')) {
    $old = Get-ChildItem $valDir -Filter $pat -EA SilentlyContinue | Sort-Object Name -Descending | Select-Object -Skip 20
    foreach ($f in $old) {
        if ($WhatIf) { Log 'WouldRemove' $f.Name $f.Length; continue }
        Remove-Item $f.FullName -Force -EA SilentlyContinue
        Log 'RotateReport' $f.Name $f.Length
    }
}

# ── 3. Truncate workstation.log ───────────────────────────────────────────────
$log = Join-Path $valDir 'workstation.log'
if ((Test-Path $log) -and ((Get-Item $log).Length -gt 3MB)) {
    if ($WhatIf) { Log 'WouldTruncate' 'workstation.log' (Get-Item $log).Length }
    else {
        Copy-Item $log (Join-Path $bakDir 'workstation.log.bak') -Force
        Get-Content $log -Tail 1500 | Set-Content $log -Encoding UTF8
        Log 'TruncateLog' 'workstation.log (kept 1500 lines)' 0
    }
}

# ── 4. Backup rotation ────────────────────────────────────────────────────────
$bakRoot = $backupsRoot
if (Test-Path $bakRoot) {
    $dirs = Get-ChildItem $bakRoot -Directory -EA SilentlyContinue |
        Where-Object { $_.Name -match '^\d{8}-' } |
        Sort-Object Name -Descending
    foreach ($d in ($dirs | Select-Object -Skip $BackupKeepCount)) {
        if ($WhatIf) { Log 'WouldRemoveBackup' $d.Name; continue }
        # Never delete without backup manifest — move to Archive subfolder first
        $archive = Join-Path $bakRoot '_Archive'
        if (-not (Test-Path $archive)) { New-Item -ItemType Directory -Path $archive -Force | Out-Null }
        $dest = Join-Path $archive $d.Name
        if (-not (Test-Path $dest)) {
            Move-Item $d.FullName $dest -Force
            Log 'ArchiveBackup' $d.Name
        }
    }
}

# ── 5. Temp cleanup (safe extensions only) ────────────────────────────────────
if ($IncludeTemp) {
    $cutoff = (Get-Date).AddDays(-$TempKeepDays)
    $tempRoots = @('C:\Temp\Scratch', 'C:\Temp')
    $safeExt = @('.tmp','.log','.cache','.bak','.old')
    foreach ($tr in $tempRoots) {
        if (-not (Test-Path $tr)) { continue }
        Get-ChildItem $tr -Recurse -File -EA SilentlyContinue |
            Where-Object { $_.LastWriteTime -lt $cutoff -and ($_.Extension -in $safeExt -or $_.Name -like '~*') } |
            ForEach-Object {
                if ($WhatIf) { Log 'WouldRemoveTemp' $_.FullName $_.Length; return }
                Remove-Item $_.FullName -Force -EA SilentlyContinue
                Log 'RemoveTemp' $_.Name $_.Length
            }
    }
} else {
    $report.Skipped.Add('Temp cleanup skipped (use -IncludeTemp)')
}

# ── 6. Empty folder cleanup (workstation temp only) ─────────────────────────
foreach ($emptyRoot in @('C:\Temp\Scratch')) {
    if (-not (Test-Path $emptyRoot)) { continue }
    Get-ChildItem $emptyRoot -Directory -Recurse -EA SilentlyContinue |
        Where-Object { -not (Get-ChildItem $_.FullName -Force -EA SilentlyContinue) } |
        ForEach-Object {
            if ($WhatIf) { Log 'WouldRemoveEmptyDir' $_.FullName; return }
            Remove-Item $_.FullName -Force -EA SilentlyContinue
            Log 'RemoveEmptyDir' $_.FullName
        }
}

# ── 7. Large forgotten files report (no delete) ───────────────────────────────
$largeFiles = [System.Collections.Generic.List[object]]::new()
foreach ($scan in @('C:\Temp', 'C:\Downloads', (Join-Path $env:USERPROFILE 'Desktop'))) {
    if (-not (Test-Path $scan)) { continue }
    Get-ChildItem $scan -Recurse -File -EA SilentlyContinue |
        Where-Object { $_.Length -gt ($LargeFileMB * 1MB) } |
        ForEach-Object {
            $largeFiles.Add([ordered]@{
                Path = $_.FullName; SizeMB = [math]::Round($_.Length/1MB,1)
                AgeDays = [math]::Round(((Get-Date)-$_.LastWriteTime).TotalDays,0)
            })
        }
}
$report.LargeFiles = @($largeFiles | Sort-Object SizeMB -Descending | Select-Object -First 25)

# ── 8. PATH dedupe ────────────────────────────────────────────────────────────
if (-not $WhatIf) {
    & "$PSScriptRoot\Fix-WorkstationPath.ps1" | Out-Null
    Log 'PathDedupe' 'Fix-WorkstationPath.ps1'
}

# ── Report ────────────────────────────────────────────────────────────────────
$reportPath = Join-Path $reportDir "housekeeping-$stamp.json"
$report | ConvertTo-Json -Depth 6 | Set-Content $reportPath -Encoding UTF8

Write-WorkstationStep 'Housekeeping complete'
Write-Host "  Actions: $($report.Actions.Count) | Skipped: $($report.Skipped.Count)" -ForegroundColor DarkGray
Write-Host "  Report:  $reportPath" -ForegroundColor DarkGray
if ($largeFiles.Count) {
    Write-Host "  Large files found: $($largeFiles.Count) (report only, not deleted)" -ForegroundColor Yellow
}
