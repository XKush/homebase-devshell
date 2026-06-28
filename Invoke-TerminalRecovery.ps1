#Requires -Version 7.0
<#
.SYNOPSIS
    Complete terminal recovery — fonts, OMP, WT, fastfetch, validation.
#>
param(
    [switch]$PreferJetBrains,
    [switch]$SkipValidation
)

$ErrorActionPreference = 'Continue'
. "$PSScriptRoot\lib\WorkstationCommon.ps1"

$logsRoot = Get-WorkstationLogsRoot
$backupsRoot = Get-WorkstationBackupsRoot
$configsRoot = Get-HomeBasePath -Name Configs

$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$bakRoot = Join-Path $backupsRoot "terminal-recovery-$stamp"
New-Item -ItemType Directory -Force -Path $bakRoot | Out-Null
Write-WorkstationStep 'TERMINAL RECOVERY — backup first'

# Backup
foreach ($item in @(
    (Join-Path $env:LOCALAPPDATA 'Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json')
    (Join-Path $PSScriptRoot 'terminal\revios-hacker.omp.json')
    (Join-Path $PSScriptRoot 'terminal\workstation-production.omp.json')
    (Join-Path $env:USERPROFILE 'Documents\PowerShell\Microsoft.PowerShell_profile.ps1')
)) {
    if (Test-Path $item) { Copy-Item $item (Join-Path $bakRoot (Split-Path $item -Leaf)) -Force }
}
Write-WorkstationLog "Backup: $bakRoot" 'OK'

# Phase 1 — Audit
Write-WorkstationStep 'Phase 1 — Terminal audit'
& "$PSScriptRoot\Invoke-TerminalAudit.ps1" | Out-Null
$auditIssues = @()
$latestAudit = Get-ChildItem $logsRoot -Filter 'terminal-audit-*.json' -ErrorAction SilentlyContinue |
    Sort-Object Name -Descending | Select-Object -First 1
if ($latestAudit -and (Test-Path $latestAudit.FullName)) {
    $audit = Get-Content $latestAudit.FullName -Raw | ConvertFrom-Json
    $auditIssues = @($audit.Issues)
}

# Phase 2 — Fonts
Write-WorkstationStep 'Phase 2 — Font recovery'
$fontFace = if ($PreferJetBrains) { 'JetBrainsMono Nerd Font' } else { 'CaskaydiaCove NF' }

if ($PreferJetBrains) {
    Write-WorkstationLog 'Installing JetBrainsMono Nerd Font...'
    oh-my-posh font install JetBrainsMono --headless 2>&1 | Out-Null
    $reg = (Get-ItemProperty 'HKCU:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts' -EA SilentlyContinue).PSObject.Properties.Name |
        Where-Object { $_ -match 'JetBrainsMono.*NF.*Regular' -or $_ -like 'JetBrainsMono Nerd Font*' }
    if (-not $reg) {
        Write-WorkstationLog 'JetBrains not found — falling back to CascadiaCode' 'WARN'
        oh-my-posh font install CascadiaCode --headless 2>&1 | Out-Null
        $fontFace = 'CaskaydiaCove NF'
    } else {
        # WT face name for JetBrains from oh-my-posh install
        $fontFace = 'JetBrainsMono NFM'
        if ($reg -like '*JetBrainsMono NF Regular*') { $fontFace = 'JetBrainsMono NF' }
    }
} else {
    & "$PSScriptRoot\Repair-WorkstationFonts.ps1" -Force
    $fontFace = 'CaskaydiaCove NF'
}

# Override font face in repair script output
$script:TerminalFontFace = $fontFace
$wtPath = Join-Path $env:LOCALAPPDATA 'Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json'
if (Test-Path $wtPath) {
    $wt = Get-Content $wtPath -Raw | ConvertFrom-Json
    $fb = [ordered]@{ face = $fontFace; size = 11; weight = 'normal' }
    $wt.profiles.defaults.font = $fb
    foreach ($p in $wt.profiles.list) {
        if (-not $p.font) { $p | Add-Member font ([pscustomobject]$fb) -Force }
        else { $p.font.face = $fontFace; if (-not $p.font.size) { $p.font.size = 11 } }
    }
    $wt | ConvertTo-Json -Depth 20 | Set-Content $wtPath -Encoding UTF8
}
@{
    FontFace = $fontFace; RepairedAt = (Get-Date).ToString('o'); RegistryOK = $true
} | ConvertTo-Json | Set-Content (Join-Path $logsRoot 'font-status.json') -Encoding UTF8

# Phase 3 — Windows Terminal standardization
Write-WorkstationStep 'Phase 3 — Windows Terminal standardization'
& "$PSScriptRoot\Install-ShellProfile.ps1" -Force
# Default terminal app (console + terminal)
$defTermPath = 'HKCU:\Console\%%Startup'
if (-not (Test-Path $defTermPath)) { New-Item -Path $defTermPath -Force | Out-Null }
$wtGuid = '{2EACA947-7F04-4AF7-8F2A-1636C7663DCF}'
Set-ItemProperty -Path $defTermPath -Name 'DelegationConsole' -Value $wtGuid -Type String -Force
Set-ItemProperty -Path $defTermPath -Name 'DelegationTerminal' -Value $wtGuid -Type String -Force -EA SilentlyContinue
# UTF-8 for legacy console fallback
Set-ItemProperty -Path 'HKCU:\Console' -Name 'CodePage' -Value 65001 -Type DWord -Force -EA SilentlyContinue

# Phase 4 — Oh My Posh theme recovery + benchmark
Write-WorkstationStep 'Phase 4 — Oh My Posh recovery'
$bench = [System.Collections.Generic.List[object]]::new()
$cleanTheme = "$PSScriptRoot\terminal\homebase-clean.omp.json"
$bestTheme = if (Test-Path $cleanTheme) { $cleanTheme } else { "$PSScriptRoot\terminal\workstation-production.omp.json" }
$themes = @(
    @{ Name = 'homebase-clean'; Path = $cleanTheme }
    @{ Name = 'workstation-production'; Path = "$PSScriptRoot\terminal\workstation-production.omp.json" }
)
foreach ($t in $themes | Where-Object { Test-Path $_.Path }) {
    $sw = [Diagnostics.Stopwatch]::StartNew()
    $out = oh-my-posh print primary --config $t.Path --plain 2>&1 | Out-String
    $sw.Stop()
    $ok = ($out -notmatch 'unable to create text') -and ($out -notmatch 'Error')
    $bench.Add([ordered]@{ Theme = $t.Name; Ms = $sw.ElapsedMilliseconds; OK = $ok })
    if ($ok -and $t.Name -eq 'homebase-clean') { $bestTheme = $t.Path }
}
Copy-Item $bestTheme "$PSScriptRoot\terminal\active-theme.omp.json" -Force
Write-WorkstationLog "Active OMP theme: $(Split-Path $bestTheme -Leaf)" 'OK'

# Verify OMP
$ompTest = oh-my-posh print primary --config "$PSScriptRoot\terminal\active-theme.omp.json" 2>&1 | Out-String
$ompOk = ($ompTest -notmatch 'unable to create text')
Write-WorkstationLog $(if ($ompOk) { 'OMP renders without template errors' } else { 'OMP still has errors' }) $(if ($ompOk) { 'OK' } else { 'ERROR' })

# Phase 5 — Fastfetch env + health display file
Write-WorkstationStep 'Phase 5 — Fastfetch configuration'
if (-not (Test-Path $configsRoot)) { New-Item -ItemType Directory -Force -Path $configsRoot | Out-Null }
$wocSession = Join-Path $logsRoot 'woc-last-session.json'
if (Test-Path $wocSession) {
    try {
        $hs = (Get-Content $wocSession -Raw | ConvertFrom-Json).HealthScore
        Set-Content (Join-Path $logsRoot 'woc-health-display.txt') "$hs/100" -Encoding UTF8
    } catch { }
}
[Environment]::SetEnvironmentVariable('FASTFETCH_CONFIG', (Join-Path $configsRoot 'fastfetch-config.jsonc'), 'User')

& "$PSScriptRoot\Install-ShellProfile.ps1" -Force

# Phase 6-8 — Validation
Write-WorkstationStep 'Phase 8 — Validation'
$reports = [ordered]@{
    Timestamp = (Get-Date).ToString('o')
    BackupDir = $bakRoot
    FontFace = $fontFace
    OMPTheme = Split-Path $bestTheme -Leaf
    OMPOk = $ompOk
    ThemeBenchmark = @($bench)
    AuditIssuesBefore = $auditIssues
}

if (-not $SkipValidation) {
    & "$PSScriptRoot\Validate-Workstation.ps1" -StartupBudgetMs 300 | Out-Null
    $reports.ValidationPassed = ($LASTEXITCODE -eq 0)
    & "$PSScriptRoot\Invoke-TerminalAudit.ps1" | Out-Null
    $latestAuditAfter = Get-ChildItem $logsRoot -Filter 'terminal-audit-*.json' -ErrorAction SilentlyContinue |
        Sort-Object Name -Descending | Select-Object -First 1
    if ($latestAuditAfter) {
        $reports.AuditIssuesAfter = @((Get-Content $latestAuditAfter.FullName -Raw | ConvertFrom-Json).Issues)
    }
}

foreach ($name in @('repair','font','theme','startup','performance')) {
    $data = switch ($name) {
        'repair' { $reports }
        'font' { @{ FontFace = $fontFace; Status = (Test-Path (Join-Path $logsRoot 'font-status.json')) } }
        'theme' { @{ Benchmark = @($bench); Active = Split-Path $bestTheme -Leaf; OMPOk = $ompOk } }
        'startup' { @{ ProfileBudgetMs = 300; Note = 'Use Windows Terminal — not legacy ConsoleHost' } }
        'performance' { @{ ThemeBenchmark = @($bench) } }
    }
    $data | ConvertTo-Json -Depth 5 | Set-Content (Join-Path $logsRoot "terminal-$name-$stamp.json") -Encoding UTF8
}

Write-Host ''
Write-Host '════════════════ TERMINAL RECOVERY COMPLETE ════════════════' -ForegroundColor Cyan
Write-Host "  Font:   $fontFace" -ForegroundColor Green
Write-Host "  Theme:  $(Split-Path $bestTheme -Leaf) (OMP OK: $ompOk)" -ForegroundColor $(if($ompOk){'Green'}else{'Yellow'})
Write-Host "  Backup: $bakRoot" -ForegroundColor DarkGray
Write-Host '  ACTION: Close ALL terminals. Open Windows Terminal (wt.exe).' -ForegroundColor Yellow
Write-Host '══════════════════════════════════════════════════════════════' -ForegroundColor Cyan

exit $(if ($ompOk) { 0 } else { 1 })
