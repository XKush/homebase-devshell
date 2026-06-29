#Requires -Version 7.0
<#
.SYNOPSIS
    Comprehensive final audit — generates JSON + markdown reports.
.NOTES
    Does NOT enable Microsoft Defender.
#>
param([switch]$ApplyFixes)

$ErrorActionPreference = 'Continue'
. "$repoRoot\lib\WorkstationCommon.ps1"
Assert-DefenderUntouched

$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$reportDir = 'C:\Logs\Workstation'
$audit = [ordered]@{
    Timestamp    = (Get-Date).ToString('o')
    Owner        = 'KGreen'
    Host         = $env:COMPUTERNAME
    Risks        = [System.Collections.Generic.List[object]]::new()
    Missing      = [System.Collections.Generic.List[string]]::new()
    Optimizations = [System.Collections.Generic.List[string]]::new()
    Passed       = [System.Collections.Generic.List[string]]::new()
    Metrics      = [ordered]@{}
}

function Add-Risk($Severity, $Item, $Recommendation) {
    $audit.Risks.Add([ordered]@{ Severity = $Severity; Item = $Item; Recommendation = $Recommendation })
}
function Add-Missing($Item) { $audit.Missing.Add($Item) }
function Add-Opt($Item) { $audit.Optimizations.Add($Item) }
function Add-OK($Item) { $audit.Passed.Add($Item) }

Write-WorkstationStep 'FINAL AUDIT — KGreen Workstation'

# ── Performance benchmarks ───────────────────────────────────────────────────
$liveProfile = Join-Path $HOME 'Documents\PowerShell\Microsoft.PowerShell_profile.ps1'
$sw = [Diagnostics.Stopwatch]::StartNew()
pwsh -NoProfile -Command "`$env:CI='1'; `$env:WORKSTATION_WELCOMED='1'; . '$liveProfile'" | Out-Null
$sw.Stop()
$audit.Metrics.ProfileLoadMs = $sw.ElapsedMilliseconds

$sw2 = [Diagnostics.Stopwatch]::StartNew(); pwsh -NoLogo -Command 'exit 0' | Out-Null; $sw2.Stop()
$audit.Metrics.PwshColdMs = $sw2.ElapsedMilliseconds

if ($audit.Metrics.ProfileLoadMs -le 600) { Add-OK "Profile startup $($audit.Metrics.ProfileLoadMs)ms" }
else { Add-Risk 'Medium' 'Slow profile' 'Run Optimize-Profile.ps1 -Apply' }

# ── Run validation suite ─────────────────────────────────────────────────────
& "$repoRoot\scripts\maintainer\install\Validate-Workstation.ps1" -StartupBudgetMs 650 | Out-Null
$audit.Metrics.ValidationExitCode = $LASTEXITCODE
if ($LASTEXITCODE -eq 0) { Add-OK 'Validate-Workstation: all checks passed' }
else { Add-Risk 'High' 'Validation failures' 'Run doctor; review C:\Logs\Workstation\validation-*.json' }

# ── Security ─────────────────────────────────────────────────────────────────
try {
    $uac = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' -ErrorAction Stop
    if ($uac.EnableLUA -eq 1) { Add-OK 'UAC enabled' } else { Add-Risk 'High' 'UAC disabled' 'Enable UAC via Harden-Security.ps1' }
} catch { Add-Risk 'Medium' 'UAC unknown' 'Run Harden-Security.ps1 as admin' }

$fw = Get-NetFirewallProfile -ErrorAction SilentlyContinue
foreach ($p in $fw) {
    if (-not $p.Enabled) { Add-Risk 'High' "Firewall $($p.Name) disabled" 'Enable all profiles' }
    elseif ($p.DefaultInboundAction -ne 'Block') {
        Add-Risk 'Medium' "Firewall $($p.Name) inbound=$($p.DefaultInboundAction)" 'Run Harden-Security.ps1 for block-inbound default'
    } else { Add-OK "Firewall $($p.Name) hardened" }
}

$smb1 = Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters' -Name SMB1 -ErrorAction SilentlyContinue
if ($smb1 -and $smb1.SMB1 -eq 0) { Add-OK 'SMB1 disabled' } else { Add-Risk 'Medium' 'SMB1' 'Run Harden-Security.ps1' }

$tel = Get-ItemProperty 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection' -Name AllowTelemetry -ErrorAction SilentlyContinue
if ($tel -and $tel.AllowTelemetry -eq 0) { Add-OK 'Telemetry minimized' } else { Add-Opt 'Run Configure-Privacy.ps1 for telemetry reduction' }

$defSvc = Get-Service WinDefend -ErrorAction SilentlyContinue
if ($defSvc -and $defSvc.Status -eq 'Running') {
    Add-Risk 'Info' 'WinDefend running' 'User policy: keep disabled — verify intentional'
} else { Add-OK 'WinDefend not running (user policy)' }

# ── Git / identity ───────────────────────────────────────────────────────────
$gitName = git config --global user.name 2>$null
if ($gitName -eq 'KGreen') { Add-OK 'Git identity: KGreen' }
elseif ($gitName) { Add-Opt "Git name is '$gitName' — set: git config --global user.name KGreen" }
else { Add-Missing 'Git user.name' }

# ── PATH analysis ────────────────────────────────────────────────────────────
$up = [Environment]::GetEnvironmentVariable('Path', 'User')
$mp = [Environment]::GetEnvironmentVariable('Path', 'Machine')
$all = ($up + ';' + $mp) -split ';' | Where-Object { $_ }
$dupes = $all | Group-Object | Where-Object Count -gt 1
if ($dupes) { Add-Opt "Duplicate PATH entries: $($dupes.Count) — run Fix-WorkstationPath.ps1" } else { Add-OK 'PATH has no duplicates' }

# ── Recommended tools ────────────────────────────────────────────────────────
$recommended = @(
    @{ Cmd = 'rg'; Name = 'ripgrep'; Winget = 'BurntSushi.ripgrep.MSVC' }
    @{ Cmd = 'code'; Name = 'VS Code'; Winget = 'Microsoft.VisualStudioCode' }
    @{ Cmd = 'pipx'; Name = 'pipx'; Winget = $null }
)

. (Join-Path $PSScriptRoot '..\_Resolve-RepoRoot.ps1')
$repoRoot = Resolve-WorkstationRepoRoot -Start $PSScriptRoot
foreach ($t in $recommended) {
    if (Get-Command $t.Cmd -ErrorAction SilentlyContinue) { Add-OK "$($t.Name) available" }
    else { Add-Missing $t.Name }
}

# ── Storage ──────────────────────────────────────────────────────────────────
$disk = Get-PSDrive C
$audit.Metrics.DiskFreeGB = [math]::Round($disk.Free / 1GB, 1)
if ($audit.Metrics.DiskFreeGB -lt 15) { Add-Risk 'Medium' 'Low disk space' "Only $($audit.Metrics.DiskFreeGB) GB free on C:" }

$bakSize = (Get-ChildItem 'C:\Backups' -Recurse -File -EA SilentlyContinue | Measure-Object Length -Sum).Sum
$audit.Metrics.BackupSizeMB = [math]::Round($bakSize / 1MB, 1)
Add-OK "Backups: $($audit.Metrics.BackupSizeMB) MB"

# ── Startup ──────────────────────────────────────────────────────────────────
$startup = Get-CimInstance Win32_StartupCommand -ErrorAction SilentlyContinue
foreach ($s in $startup) {
    Add-OK "Startup: $($s.Name)"
    if ($s.Name -eq 'Steam') { Add-Opt 'Steam startup — disable in Task Manager if unused' }
}

# ── Beginner DX ──────────────────────────────────────────────────────────────
$helpers = @('help','cheatsheet','devinfo','doctor','updateall','backupconfig','repairterminal','cleanlogs','new-project')
$helperPath = "$repoRoot\lib\WorkstationHelpers.ps1"
if (Test-Path $helperPath) { Add-OK 'WorkstationHelpers.ps1 present' } else { Add-Missing 'WorkstationHelpers.ps1' }

# ── Auto-fixes ─────────────────────────────────────────────────────────────
if ($ApplyFixes) {
    Write-WorkstationStep 'Applying safe fixes'
    git config --global user.name 'KGreen' 2>$null
    $email = git config --global user.email 2>$null
    if (-not $email -or ($email -match '@local\.workstation$' -and $email -ne 'kgreen@local.workstation')) {
        git config --global user.email 'kgreen@local.workstation'
    }
    & "$repoRoot\scripts\maintainer\configure\Fix-WorkstationPath.ps1"
    & "$repoRoot\scripts\maintainer\install\Install-ShellProfile.ps1" -Force | Out-Null
    Add-OK 'Applied: git identity, PATH fix, profile redeploy'
}

# ── Write reports ────────────────────────────────────────────────────────────
$jsonPath = Join-Path $reportDir "audit-final-$stamp.json"
$mdPath   = Join-Path $reportDir "audit-final-$stamp.md"
$audit | ConvertTo-Json -Depth 5 | Set-Content $jsonPath -Encoding UTF8

$md = @"
# Final Workstation Audit — KGreen
**Date:** $(Get-Date -Format 'yyyy-MM-dd HH:mm')
**Host:** $($env:COMPUTERNAME)

## Metrics
| Metric | Value |
|--------|-------|
| Profile load | $($audit.Metrics.ProfileLoadMs) ms |
| pwsh cold start | $($audit.Metrics.PwshColdMs) ms |
| Disk free (C:) | $($audit.Metrics.DiskFreeGB) GB |
| Backup size | $($audit.Metrics.BackupSizeMB) MB |
| Validation | $(if ($audit.Metrics.ValidationExitCode -eq 0) { 'PASS' } else { 'FAIL' }) |

## Passed ($($audit.Passed.Count))
$($audit.Passed | ForEach-Object { "- $_" } | Out-String)

## Risks ($($audit.Risks.Count))
$($audit.Risks | ForEach-Object { "- **[$($_.Severity)]** $($_.Item) — $($_.Recommendation)" } | Out-String)

## Missing ($($audit.Missing.Count))
$($audit.Missing | ForEach-Object { "- $_" } | Out-String)

## Optimizations ($($audit.Optimizations.Count))
$($audit.Optimizations | ForEach-Object { "- $_" } | Out-String)

## Maintenance plan
- Daily: ``doctor`` if something feels wrong
- Weekly: ``Invoke-Maintenance.ps1`` or ``updateall``
- Monthly: ``backupconfig`` + review ``C:\Logs\Workstation``

## Recovery
``````powershell
backupconfig
Start-Process pwsh -Verb RunAs -ArgumentList '-File C:\Scripts\Workstation\Rollback-Workstation.ps1 -Force'
``````
"@
Set-Content $mdPath $md -Encoding UTF8

Write-Host "`nAudit written:" -ForegroundColor Cyan
Write-Host "  $mdPath"
Write-Host "  $jsonPath"
Write-Host "`nRisks: $($audit.Risks.Count) | Missing: $($audit.Missing.Count) | Passed: $($audit.Passed.Count)" -ForegroundColor $(if ($audit.Risks | Where-Object Severity -in 'High','Medium') { 'Yellow' } else { 'Green' })

exit $(if ($audit.Metrics.ValidationExitCode -eq 0 -and -not ($audit.Risks | Where-Object Severity -eq 'High')) { 0 } else { 1 })
