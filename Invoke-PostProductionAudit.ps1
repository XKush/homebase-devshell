#Requires -Version 7.0
# Phase 1 post-production read-only audit
$ErrorActionPreference = 'Continue'
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$out = "C:\Logs\Workstation\post-audit-$stamp.json"
$r = [ordered]@{ Timestamp=(Get-Date).ToString('o'); Issues=[System.Collections.Generic.List[string]]::new(); Checks=[ordered]@{} }

function Issue($m){ $r.Issues.Add($m) }

# Fonts
$hkcu = Get-ItemProperty 'HKCU:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts' -EA SilentlyContinue
$cask = @($hkcu.PSObject.Properties.Name | Where-Object { $_ -match 'Caskaydia' })
$r.Checks.FontRegistryHKCU = $cask
if (-not $cask) { Issue 'No Caskaydia font in HKCU registry' }
$fontDir = Join-Path $env:LOCALAPPDATA 'Microsoft\Windows\Fonts'
$r.Checks.FontFiles = @(Get-ChildItem $fontDir -Filter '*Caskaydia*' -EA SilentlyContinue | Select-Object -ExpandProperty Name)

# WT font name vs registry
$wtPath = Join-Path $env:LOCALAPPDATA 'Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json'
$wt = Get-Content $wtPath -Raw | ConvertFrom-Json
$wtFont = $wt.profiles.defaults.font.face
$r.Checks.WTFontFace = $wtFont
$exact = $cask | Where-Object { $_ -like 'CaskaydiaCove NF Regular*' }
if (-not $exact) { Issue 'CaskaydiaCove NF Regular not in registry' }
if ($wtFont -ne 'CaskaydiaCove NF') { Issue "WT font '$wtFont' should be 'CaskaydiaCove NF'" }

# Profile sync
$c='C:\Scripts\Workstation\profile\Microsoft.PowerShell_profile.ps1'
$l=Join-Path $env:USERPROFILE 'Documents\PowerShell\Microsoft.PowerShell_profile.ps1'
$r.Checks.ProfileMatch = (Get-FileHash $c).Hash -eq (Get-FileHash $l).Hash
if (-not $r.Checks.ProfileMatch) { Issue 'Profile canonical != live' }

# Startup
$sw=[Diagnostics.Stopwatch]::StartNew()
pwsh -NoProfile -Command "& { `$env:CI='1'; `$env:WORKSTATION_DASHBOARD='0'; `$env:WORKSTATION_JARVIS='0'; . '$l' }" | Out-Null
$sw.Stop()
$r.Checks.ProfileLoadMs = $sw.ElapsedMilliseconds
if ($sw.ElapsedMilliseconds -gt 300) { Issue "Profile load $($sw.ElapsedMilliseconds)ms > 300ms target" }

# OMP glyph test
try {
  $ompOut = oh-my-posh print primary --config 'C:\Scripts\Workstation\terminal\revios-hacker.omp.json' 2>&1
  $r.Checks.OMPRenders = [bool]$ompOut
  if ($ompOut -match '[\uE000-\uF8FF]' ) { $r.Checks.OMPHasPrivateUse = $true }
} catch { Issue "OMP render failed: $_" }

# Scheduled task (workstation-specific only)
$task = Get-ScheduledTask -TaskName 'ReviOS-Workstation-Maintenance' -EA SilentlyContinue
$r.Checks.ScheduledTask = if ($task) { @{ TaskName = $task.TaskName; State = $task.State } } else { $null }
if (-not $task) { Issue 'ReviOS-Workstation-Maintenance task not registered (run Register-MaintenanceTask.ps1 as admin)' }

# Backups
$bak = Get-ChildItem 'C:\Backups\Workstation' -Directory -EA SilentlyContinue
$r.Checks.BackupCount = @($bak).Count
if (-not $bak) { Issue 'No backups found' }
$rb = 'C:\Scripts\Workstation\Rollback-Workstation.ps1'
$r.Checks.RollbackScript = Test-Path $rb

$r | ConvertTo-Json -Depth 6 | Set-Content $out -Encoding UTF8
Write-Host "Post-audit: $($r.Issues.Count) issues -> $out"
$r.Issues | ForEach-Object { Write-Host "  ! $_" -ForegroundColor Yellow }
exit $(if ($r.Issues.Count -eq 0) { 0 } else { 1 })
