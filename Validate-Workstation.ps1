#Requires -Version 7.0
<#
.SYNOPSIS
    Comprehensive workstation validation — run after setup or changes.
.OUTPUTS
    JSON report at C:\Logs\Workstation\validation-<timestamp>.json
#>
param(
    [switch]$Fix,
    [int]$StartupBudgetMs = 600
)

$ErrorActionPreference = 'Continue'
. "$PSScriptRoot\lib\WorkstationCommon.ps1"

$report = [ordered]@{
    Timestamp = (Get-Date).ToString('o')
    Host      = $env:COMPUTERNAME
    Passed    = [System.Collections.Generic.List[string]]::new()
    Failed    = [System.Collections.Generic.List[string]]::new()
    Warnings  = [System.Collections.Generic.List[string]]::new()
    Metrics   = [ordered]@{}
    BeforeAfter = [ordered]@{}
}

function Add-Pass($msg) { $report.Passed.Add($msg); Write-WorkstationLog "PASS: $msg" 'OK' }
function Add-Fail($msg) { $report.Failed.Add($msg); Write-WorkstationLog "FAIL: $msg" 'ERROR' }
function Add-Warn($msg) { $report.Warnings.Add($msg); Write-WorkstationLog "WARN: $msg" 'WARN' }

Write-WorkstationStep 'Validation — baseline metrics'

# Refresh PATH from registry for accurate tool detection
$machinePath = [Environment]::GetEnvironmentVariable('Path', 'Machine')
$userPath    = [Environment]::GetEnvironmentVariable('Path', 'User')
$env:Path    = "$machinePath;$userPath"

# ── 1. Installation checks ───────────────────────────────────────────────────
Write-WorkstationStep 'Tool installation'
$requiredTools = @(
    'pwsh', 'git', 'python', 'winget', 'oh-my-posh',
    'fzf', 'bat', 'eza', 'zoxide', 'fastfetch'
)
$optionalTools = @(
    @{ Name = 'code';       Exe = 'code' }
    @{ Name = 'nmap';       Exe = 'nmap' }
    @{ Name = 'wireshark';  Exe = 'wireshark'; Path = 'C:\Program Files\Wireshark\Wireshark.exe' }
    @{ Name = '7z';         Exe = '7z';         Path = 'C:\Program Files\7-Zip\7z.exe' }
    @{ Name = 'everything'; Exe = 'everything'; Path = 'C:\Program Files\Everything\Everything.exe' }
)
foreach ($tool in $requiredTools) {
    if (Get-Command $tool -ErrorAction SilentlyContinue) { Add-Pass "Tool installed: $tool" }
    else { Add-Fail "Tool missing: $tool" }
}
foreach ($tool in $optionalTools) {
    $found = Get-Command $tool.Exe -ErrorAction SilentlyContinue
    if (-not $found -and $tool.Path -and (Test-Path $tool.Path)) { $found = $true }
    if ($found) { Add-Pass "Optional tool: $($tool.Name)" }
    else { Add-Warn "Optional tool not installed: $($tool.Name)" }
}

# ── 2. PowerShell modules ────────────────────────────────────────────────────
Write-WorkstationStep 'PowerShell modules'
$requiredModules = @('PSReadLine', 'posh-git', 'Terminal-Icons')
foreach ($mod in $requiredModules) {
    $m = Get-Module -ListAvailable $mod | Sort-Object Version -Descending | Select-Object -First 1
    if ($m) { Add-Pass "Module $($m.Name) v$($m.Version)" }
    else { Add-Fail "Module missing: $mod" }
}

# ── 3. Profile integrity ─────────────────────────────────────────────────────
Write-WorkstationStep 'Profile integrity'
$canonical = 'C:\Scripts\Workstation\profile\Microsoft.PowerShell_profile.ps1'
$live      = Join-Path $HOME 'Documents\PowerShell\Microsoft.PowerShell_profile.ps1'
if (Test-Path $canonical) { Add-Pass 'Canonical profile exists' } else { Add-Fail 'Canonical profile missing' }
if (Test-Path $live) {
    Add-Pass 'Live PS7 profile exists'
    $canHash = (Get-FileHash $canonical -Algorithm SHA256).Hash
    $liveHash = (Get-FileHash $live -Algorithm SHA256).Hash
    if ($canHash -eq $liveHash) { Add-Pass 'Live profile matches canonical' }
    else { Add-Warn 'Live profile differs from canonical — re-run Install-ShellProfile.ps1' }
} else { Add-Fail 'Live PS7 profile missing' }

# ── 4. Startup benchmark ─────────────────────────────────────────────────────
Write-WorkstationStep 'PowerShell startup benchmark'
$sw = [Diagnostics.Stopwatch]::StartNew()
$null = pwsh -NoProfile -Command @"
`$env:WORKSTATION_BANNER_SHOWN='1'
`$env:CI='1'
. '$live'
"@
$sw.Stop()
$profileMs = $sw.ElapsedMilliseconds
$report.Metrics['ProfileLoadMs_Headless'] = $profileMs
if ($profileMs -le $StartupBudgetMs) { Add-Pass "Profile load (headless): ${profileMs}ms <= ${StartupBudgetMs}ms" }
else { Add-Fail "Profile load too slow: ${profileMs}ms (budget ${StartupBudgetMs}ms)" }

$sw2 = [Diagnostics.Stopwatch]::StartNew()
$null = pwsh -NoLogo -Command "exit 0"
$sw2.Stop()
$report.Metrics['PwshColdStartMs'] = $sw2.ElapsedMilliseconds
Add-Pass "pwsh cold start: $($sw2.ElapsedMilliseconds)ms"

# ── 5. Oh My Posh ────────────────────────────────────────────────────────────
Write-WorkstationStep 'Oh My Posh'
$ompConfig = 'C:\Scripts\Workstation\terminal\revios-hacker.omp.json'
if (Test-Path $ompConfig) {
    Add-Pass 'OMP theme file exists'
    try {
        $ompOut = oh-my-posh print primary --config $ompConfig 2>&1
        if ($LASTEXITCODE -eq 0 -and $ompOut) { Add-Pass 'OMP renders primary prompt' }
        else { Add-Fail "OMP render failed: $ompOut" }
    } catch { Add-Fail "OMP error: $_" }
} else { Add-Fail 'OMP config missing' }

# ── 6. Nerd Font ─────────────────────────────────────────────────────────────
Write-WorkstationStep 'Nerd Font'
$fontFace = 'CaskaydiaCove NF'
$fontInstalled = $false
foreach ($hive in @('HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts', 'HKCU:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts')) {
    if (Test-Path $hive) {
        $props = Get-ItemProperty $hive -ErrorAction SilentlyContinue
        if ($props.PSObject.Properties.Name | Where-Object { $_ -like 'CaskaydiaCove NF Regular*' -or $_ -like 'CaskaydiaCove NF *' }) {
            $fontInstalled = $true
            break
        }
    }
}
$fontFile = Get-ChildItem "$env:LOCALAPPDATA\Microsoft\Windows\Fonts" -Filter '*Caskaydia*NF*' -ErrorAction SilentlyContinue | Select-Object -First 1
if ($fontFile) { $fontInstalled = $true }
if ($fontInstalled) { Add-Pass "Nerd Font installed: $fontFace" }
else { Add-Warn "Nerd Font not detected — run: repairterminal" }

# ── 7. Windows Terminal ──────────────────────────────────────────────────────
Write-WorkstationStep 'Windows Terminal'
$wtPath = Join-Path $env:LOCALAPPDATA 'Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json'
if (Test-Path $wtPath) {
    Add-Pass 'Terminal settings.json exists'
    $wt = Get-Content $wtPath -Raw | ConvertFrom-Json
    if ($wt.defaultProfile -eq '{574e775e-4f2a-5b96-ac1e-a2962a402336}') {
        Add-Pass 'Default profile is PowerShell 7'
    } else { Add-Warn "Default profile GUID: $($wt.defaultProfile)" }
    if ($wt.profiles.defaults.colorScheme -eq 'ReviOS Hack Dark') {
        Add-Pass 'Color scheme: ReviOS Hack Dark'
    } else { Add-Warn "Color scheme: $($wt.profiles.defaults.colorScheme)" }
    $fontFace = 'CaskaydiaCove NF'
    if ($wt.profiles.defaults.font.face -ne $fontFace) {
        Add-Warn "Terminal font is '$($wt.profiles.defaults.font.face)' — should be '$fontFace' (glyph fix)"
    } else { Add-Pass "Terminal font: $fontFace" }
} else { Add-Fail 'Windows Terminal settings not found' }

# ── 8. UTF-8 ─────────────────────────────────────────────────────────────────
Write-WorkstationStep 'UTF-8 support'
$utfTest = pwsh -NoProfile -Command @"
[Console]::OutputEncoding = [Text.Encoding]::UTF8
`$s = 'test: arrow -> unicode ok'
`$s
[Console]::OutputEncoding.WebName
"@
if ($utfTest -match 'utf-8') { Add-Pass 'UTF-8 console encoding' } else { Add-Fail 'UTF-8 encoding check failed' }

# ── 9. Aliases and functions ─────────────────────────────────────────────────
Write-WorkstationStep 'Aliases and functions'
$aliasTest = pwsh -NoProfile -Command @"
`$env:WORKSTATION_BANNER_SHOWN='1'
`$env:CI='1'
. '$live'
@( 'projects', 'll', 'gs', 'Enter-Venv', 'sysinfo' ) | ForEach-Object {
  if (-not (Get-Command `$_ -EA SilentlyContinue)) { Write-Output "MISSING:`$_" }
}
"@
$missingAliases = $aliasTest | Where-Object { $_ -like 'MISSING:*' }
if (-not $missingAliases) { Add-Pass 'Core aliases/functions available after profile load' }
else { Add-Fail ($missingAliases -join ', ') }

# ── 10. PATH consistency ─────────────────────────────────────────────────────
Write-WorkstationStep 'PATH consistency'
$regPath = "$machinePath;$userPath"
$wingetLinks = Join-Path $env:LOCALAPPDATA 'Microsoft\WindowsApps'
$winGetPackages = Join-Path $env:LOCALAPPDATA 'Microsoft\WinGet\Packages'
$pathChecks = @(
    @{ Name = 'Git';           Fragment = 'Git\cmd' }
    @{ Name = 'Python';        Fragment = 'Python312' }
    @{ Name = 'WinGet links';  Fragment = 'WindowsApps' }
)
foreach ($pc in $pathChecks) {
    if ($regPath -like "*$($pc.Fragment)*") { Add-Pass "PATH contains $($pc.Name)" }
    else { Add-Warn "PATH missing fragment for $($pc.Name)" }
}

# ── 11. Folder structure ─────────────────────────────────────────────────────
Write-WorkstationStep 'Folder structure'
foreach ($dir in @('C:\Tools','C:\Scripts','C:\Projects','C:\Logs','C:\Backups','C:\Security','C:\Networking','C:\Configs','C:\Temp')) {
    if (Test-Path $dir) { Add-Pass "Directory: $dir" } else { Add-Fail "Directory missing: $dir" }
}

# ── 12. Functional smoke tests ───────────────────────────────────────────────
Write-WorkstationStep 'Functional smoke tests'
try {
    $ezaOut = eza --version 2>&1
    if ($ezaOut) { Add-Pass "eza: $($ezaOut | Select-Object -First 1)" }
} catch { Add-Fail "eza failed: $_" }
try {
    $batOut = bat --version 2>&1
    if ($batOut) { Add-Pass "bat: $($batOut | Select-Object -First 1)" }
} catch { Add-Fail "bat failed: $_" }
try {
    $ffOut = fastfetch --version 2>&1
    if ($ffOut) { Add-Pass "fastfetch: $($ffOut | Select-Object -First 1)" }
} catch { Add-Fail "fastfetch failed: $_" }
try {
    $zg = zoxide --version 2>&1
    if ($zg) { Add-Pass "zoxide: $zg" }
} catch { Add-Fail "zoxide failed: $_" }

# ── 13. Security settings (non-Defender) ─────────────────────────────────────
Write-WorkstationStep 'Security settings audit'
try {
    $uac = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' -ErrorAction Stop
    if ($uac.EnableLUA -eq 1) { Add-Pass 'UAC enabled' } else { Add-Warn 'UAC EnableLUA not set to 1 (hardening script may not have run)' }
} catch { Add-Warn 'UAC registry not configured — run Harden-Security.ps1 as admin' }

try {
    $fw = Get-NetFirewallProfile -ErrorAction Stop
    $allOn = ($fw | Where-Object { -not $_.Enabled }).Count -eq 0
    if ($allOn) { Add-Pass 'All firewall profiles enabled' } else { Add-Warn 'Some firewall profiles disabled' }
} catch { Add-Warn 'Firewall audit skipped (needs admin): $_' }

try {
    $smb1Reg = Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters' -Name SMB1 -ErrorAction SilentlyContinue
    if ($smb1Reg -and $smb1Reg.SMB1 -eq 0) {
        Add-Pass 'SMB1 disabled (registry)'
    } elseif (Test-WorkstationAdmin) {
        $smb1 = Get-WindowsOptionalFeature -Online -FeatureName SMB1Protocol -ErrorAction Stop
        if ($smb1.State -eq 'Disabled') { Add-Pass 'SMB1 disabled' }
        else { Add-Warn "SMB1 state: $($smb1.State)" }
    } else {
        Add-Warn 'SMB1 not verified — run Harden-Security.ps1 as admin'
    }
} catch {
    Add-Warn "SMB1 check: $($_.Exception.Message)"
}

# Explicit Defender policy check — must remain off/disabled if user intended
try {
    $defSvc = Get-Service -Name WinDefend -ErrorAction SilentlyContinue
    if ($defSvc -and $defSvc.Status -eq 'Running') {
        Add-Warn 'WinDefend service is running — user policy says keep disabled'
    } else {
        Add-Pass 'WinDefend not running (per user policy)'
    }
} catch { Add-Pass 'WinDefend service absent or stopped' }

# ── 14. Onboarding helpers & command center ──────────────────────────────────
Write-WorkstationStep 'Command center'
$centerScript = 'C:\Scripts\Workstation\lib\WorkstationCommandCenter.ps1'
$requiredCmds = @(
    'doctor','repairterminal','updateall','backupconfig','restoreconfig','cleanup',
    'healthcheck','workstationstatus','securitycheck','devstart','workspace',
    'cheatsheet','helpme','fixprofile','reloadprofile','sysreport','logs','networkstatus','learn',
    'nettools','toolbox','toolcheck','sysaudit',
    'jarvis','dashboard','home'
)
$helperTest = pwsh -NoProfile -Command @"
`$env:WORKSTATION_DASHBOARD='0'; `$env:WORKSTATION_DASHBOARD_SHOWN='1'; `$env:WORKSTATION_WELCOMED='1'; `$env:CI='1'
. '$live'
. '$centerScript'
@('$($requiredCmds -join "','")') | ForEach-Object { if (-not (Get-Command `$_ -EA SilentlyContinue)) { "MISSING:`$_" } }
"@
$missingHelpers = $helperTest | Where-Object { $_ -like 'MISSING:*' }
if (-not $missingHelpers) { Add-Pass 'Command center commands loaded' }
else { Add-Fail ($missingHelpers -join ', ') }

if (Test-Path 'C:\Scripts\Workstation\modules\KGreen.Workstation.psm1') { Add-Pass 'KGreen.Workstation module present' }
elseif (Test-Path 'C:\Scripts\Workstation\lib\WorkstationToolkit.ps1') { Add-Pass 'Toolkit module present (legacy)' }
else { Add-Fail 'Command center module missing' }

Write-WorkstationStep 'Network tools'
@(
    @{ Name = 'nmap'; Required = $true }
    @{ Name = 'wireshark'; Required = $true }
    @{ Name = 'tshark'; Required = $true }
    @{ Name = 'ssh'; Required = $true }
    @{ Name = 'everything'; Required = $true }
    @{ Name = 'gh'; Required = $false }
    @{ Name = 'openssl'; Required = $false }
    @{ Name = 'putty'; Required = $false }
) | ForEach-Object {
    if (Get-Command $_.Name -ErrorAction SilentlyContinue) { Add-Pass "Network tool: $($_.Name)" }
    elseif ($_.Required) { Add-Warn "Network tool missing: $($_.Name)" }
    else { Add-Pass "Optional network tool absent: $($_.Name)" }
}

if (Test-Path 'C:\Scripts\Workstation\lib\WorkstationOperationsCenter.ps1') { Add-Pass 'WOC module present' }
else { Add-Fail 'WOC module missing' }

Write-WorkstationStep 'Startup command center benchmark'
$ccBench = pwsh -NoProfile -Command @"
`$env:CI=''
`$sw = [Diagnostics.Stopwatch]::StartNew()
. 'C:\Scripts\Workstation\lib\WorkstationOperationsCenter.ps1'
Show-Woc -Mode minimal -Force -NoHeal | Out-Null
`$sw.Stop()
Write-Output `$sw.ElapsedMilliseconds
"@
$ccMs = [int]($ccBench | Select-Object -Last 1)
$report.Metrics['CommandCenterMs'] = $ccMs
if ($ccMs -le 1000) { Add-Pass "Command center render: ${ccMs}ms <= 1000ms" }
else { Add-Warn "Command center render: ${ccMs}ms (target 1000ms)" }

if (Test-Path 'C:\Logs\Workstation\font-status.json') {
    try {
        $fs = Get-Content 'C:\Logs\Workstation\font-status.json' -Raw | ConvertFrom-Json
        if ($fs.FontFace -eq 'CaskaydiaCove NF') { Add-Pass 'Font status: CaskaydiaCove NF' }
        else { Add-Warn "Font status: $($fs.FontFace)" }
    } catch { Add-Warn 'font-status.json unreadable' }
} else { Add-Warn 'Run Repair-WorkstationFonts.ps1' }

# ── 15. Git ──────────────────────────────────────────────────────────────────
Write-WorkstationStep 'Git configuration'
if (git --version 2>$null) { Add-Pass (git --version) } else { Add-Fail 'git not working' }
if (git config --global user.name 2>$null) { Add-Pass "Git user.name set" } else { Add-Warn 'Git user.name not configured' }
if (git config --global user.email 2>$null) { Add-Pass "Git user.email set" } else { Add-Warn 'Git user.email not configured' }

# ── Auto-fix pass ────────────────────────────────────────────────────────────
if ($Fix -and $report.Failed.Count -gt 0) {
    Write-WorkstationStep 'Auto-fix attempt'
    if ($report.Failed -match 'profile') {
        & "$PSScriptRoot\Install-ShellProfile.ps1" -Force
        Add-Warn 'Re-deployed shell profile'
    }
    if ($report.Failed -match 'Module missing') {
        Install-Module PSReadLine, posh-git, Terminal-Icons -Scope CurrentUser -Force -AllowClobber -Repository PSGallery
        Add-Warn 'Reinstalled PS modules'
    }
    if ($report.Failed -match 'Profile load too slow') {
        Add-Warn 'Profile optimization required — run Optimize-Profile.ps1'
    }
}

# ── Summary ──────────────────────────────────────────────────────────────────
$report.Metrics['PassCount']  = $report.Passed.Count
$report.Metrics['FailCount']  = $report.Failed.Count
$report.Metrics['WarnCount']  = $report.Warnings.Count
$report.Metrics['Complete']   = ($report.Failed.Count -eq 0)

$outDir = 'C:\Logs\Workstation'
if (-not (Test-Path $outDir)) { New-Item -ItemType Directory -Force -Path $outDir | Out-Null }
$outFile = Join-Path $outDir ("validation-{0}.json" -f (Get-Date -Format 'yyyyMMdd-HHmmss'))
$report | ConvertTo-Json -Depth 6 | Set-Content $outFile -Encoding UTF8

Write-Host ''
Write-Host '════════════════ VALIDATION REPORT ════════════════' -ForegroundColor Cyan
Write-Host "Passed:  $($report.Passed.Count)" -ForegroundColor Green
Write-Host "Failed:  $($report.Failed.Count)" -ForegroundColor $(if ($report.Failed.Count) { 'Red' } else { 'Green' })
Write-Host "Warnings: $($report.Warnings.Count)" -ForegroundColor Yellow
Write-Host "Profile load: ${profileMs}ms | pwsh cold: $($report.Metrics.PwshColdStartMs)ms"
Write-Host "Report: $outFile"
Write-Host '══════════════════════════════════════════════════' -ForegroundColor Cyan

if ($report.Failed.Count -gt 0) {
    Write-Host "`nFailed checks:" -ForegroundColor Red
    $report.Failed | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
}
if ($report.Warnings.Count -gt 0) {
    Write-Host "`nWarnings:" -ForegroundColor Yellow
    $report.Warnings | ForEach-Object { Write-Host "  - $_" -ForegroundColor Yellow }
}

exit $(if ($report.Failed.Count -eq 0) { 0 } else { 1 })
