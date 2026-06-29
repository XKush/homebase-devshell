#Requires -Version 7.0
<#
.SYNOPSIS
    Comprehensive workstation validation — run after setup or changes.
.OUTPUTS
    JSON report at {LogsRoot}/validation-<timestamp>.json (via Get-HomeBasePath)
#>
param(
    [switch]$Fix,
    [switch]$FixPassCompleted,
    [switch]$Privacy,
    [ValidateSet('Core', 'Full')]
    [string]$Tier = 'Full',
    [int]$StartupBudgetMs = 650
)

$isFull = ($Tier -eq 'Full')

$ErrorActionPreference = 'Continue'
. (Join-Path $PSScriptRoot '..\_Resolve-RepoRoot.ps1')
$repoRoot = Resolve-WorkstationRepoRoot -Start $PSScriptRoot
. (Join-Path $repoRoot 'lib\WorkstationCommon.ps1')
$logsRoot       = Get-WorkstationLogsRoot
$modulePath     = Join-Path $repoRoot 'modules\KGreen.Workstation.psm1'
$canonical      = Join-Path $repoRoot 'profile\Microsoft.PowerShell_profile.ps1'
$ompConfig      = Join-Path $repoRoot 'terminal\revios-hacker.omp.json'
$centerScript   = Join-Path $repoRoot 'lib\WorkstationCommandCenter.ps1'
$wocScript      = Join-Path $repoRoot 'lib\WorkstationOperationsCenter.ps1'
$menuAuditPath  = Join-Path $repoRoot 'Test-MenuAudit.ps1'
$toolkitLegacy  = Join-Path $repoRoot 'lib\WorkstationToolkit.ps1'
$fontStatusPath = Join-Path $logsRoot 'font-status.json'
$structureDirs  = @(
    (Get-HomeBasePath -Name Tools)
    (Get-HomeBasePath -Name Scripts)
    (Get-HomeBasePath -Name Projects)
    (Split-Path (Get-HomeBasePath -Name Logs) -Parent)
    (Split-Path (Get-HomeBasePath -Name Backups) -Parent)
    (Get-HomeBasePath -Name Security)
    (Get-HomeBasePath -Name Networking)
    (Split-Path (Get-HomeBasePath -Name Configs) -Parent)
    (Split-Path (Get-HomeBasePath -Name Temp) -Parent)
)

$report = [ordered]@{
    Timestamp = (Get-Date).ToString('o')
    Host      = $env:COMPUTERNAME
    Tier      = $Tier
    Passed    = [System.Collections.Generic.List[string]]::new()
    Failed    = [System.Collections.Generic.List[string]]::new()
    Warnings  = [System.Collections.Generic.List[string]]::new()
    Metrics   = [ordered]@{ Tier = $Tier }
    BeforeAfter = [ordered]@{}
}

function Add-Pass($msg) { $report.Passed.Add($msg); Write-WorkstationLog "PASS: $msg" 'OK' }
function Add-Fail($msg) { $report.Failed.Add($msg); Write-WorkstationLog "FAIL: $msg" 'ERROR' }
function Add-Warn($msg) { $report.Warnings.Add($msg); Write-WorkstationLog "WARN: $msg" 'WARN' }

function Get-DevReadyFixHints {
    param([System.Collections.Generic.List[string]]$Failed)

    $hints = [System.Collections.Generic.List[string]]::new()
    $seen = @{}

    foreach ($f in $Failed) {
        $candidates = @(
            if ($f -match 'git') {
                'Install Git for Windows (https://git-scm.com/download/win), then run: devshell install'
            }
            if ($f -match 'pwsh|PowerShell') {
                'Install PowerShell 7+ (https://aka.ms/powershell), open a new terminal, run: devshell install'
            }
            if ($f -match 'profile|OMP|Windows Terminal|encoding|UTF-8') {
                'Run: devshell doctor -Fix — or devshell install, then open a new terminal'
            }
            if ($f -match 'command-health|Command center|module missing|WOC module') {
                'Run: devshell doctor -Fix — if it persists, see docs/TROUBLESHOOTING.md'
            }
            if ($f -match 'Tool missing') {
                'Core needs pwsh + git. Run: devshell doctor -Fix (or devshell install -WithTools for full stack)'
            }
            if ($f -match 'Directory missing') {
                'Run: devshell doctor -Fix — creates standard folders from Config'
            }
            if ($f -match 'PATH') {
                'Run: devshell doctor -Fix — repairs PATH entries'
            }
        ) | Where-Object { $_ }

        foreach ($h in $candidates) {
            if (-not $seen.ContainsKey($h) -and $hints.Count -lt 3) {
                $seen[$h] = $true
                $hints.Add($h)
            }
        }
    }

    if ($hints.Count -eq 0 -and $Failed.Count -gt 0) {
        $hints.Add('Run: devshell doctor -Fix — or devshell install. See docs/TROUBLESHOOTING.md')
    }
    return $hints
}

if ($Privacy) {
    . (Join-Path $repoRoot 'lib\PrivacyAudit.ps1')
    $product = '0.0.0'
    $psd1Path = Join-Path $repoRoot 'modules\KGreen.Workstation.psd1'
    if (Test-Path $psd1Path) { $product = [string](Import-PowerShellDataFile $psd1Path).ModuleVersion }
    Write-WorkstationStep 'Privacy doctor'
    $privacyReport = Get-PrivacyAuditReport -Scope System -RepoRoot $repoRoot -ProductVersion $product
    Write-PrivacyAuditReport -Report $privacyReport | Out-Null
    $reportPath = Save-PrivacyAuditReport -Report $privacyReport
    Write-Host 'Privacy readiness' -ForegroundColor Cyan
    $col = if ($privacyReport.Score -ge 85) { 'Green' } elseif ($privacyReport.Score -ge 65) { 'Yellow' } else { 'Red' }
    Write-Host "$($privacyReport.Score)/100 — $($privacyReport.RiskLevel)" -ForegroundColor $col
    if ($privacyReport.WarnCount -gt 0) {
        Write-Host ''
        Write-Host 'Try: devshell privacy -Fix (safe repairs only)' -ForegroundColor DarkGray
    }
    $exitCode = if ($privacyReport.Score -ge 65) { 0 } else { 1 }
    $global:LASTEXITCODE = $exitCode
    exit $exitCode
}

Write-WorkstationStep 'Validation — baseline metrics'

# Refresh PATH from registry for accurate tool detection
$machinePath = [Environment]::GetEnvironmentVariable('Path', 'Machine')
$userPath    = [Environment]::GetEnvironmentVariable('Path', 'User')
$env:Path    = "$machinePath;$userPath"

# ── 1. Installation checks ───────────────────────────────────────────────────
Write-WorkstationStep 'Tool installation'
$coreTools = @('pwsh', 'git')
$fullOnlyTools = @(
    'python', 'winget', 'oh-my-posh',
    'fzf', 'bat', 'eza', 'zoxide', 'fastfetch'
)
$requiredTools = $coreTools + $(if ($isFull) { $fullOnlyTools } else { @() })
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
if ($isFull) {
    foreach ($tool in $optionalTools) {
        $found = Get-Command $tool.Exe -ErrorAction SilentlyContinue
        if (-not $found -and $tool.Path -and (Test-Path $tool.Path)) { $found = $true }
        if ($found) { Add-Pass "Optional tool: $($tool.Name)" }
        else { Add-Warn "Optional tool not installed: $($tool.Name)" }
    }
}

# ── 2. PowerShell modules ────────────────────────────────────────────────────
Write-WorkstationStep 'PowerShell modules'
$coreModules = @('PSReadLine')
$fullModules = @('posh-git', 'Terminal-Icons')
foreach ($mod in $coreModules) {
    $m = Get-Module -ListAvailable $mod | Sort-Object Version -Descending | Select-Object -First 1
    if ($m) { Add-Pass "Module $($m.Name) v$($m.Version)" }
    else { Add-Fail "Module missing: $mod" }
}
foreach ($mod in $(if ($isFull) { $fullModules } else { @() })) {
    $m = Get-Module -ListAvailable $mod | Sort-Object Version -Descending | Select-Object -First 1
    if ($m) { Add-Pass "Module $($m.Name) v$($m.Version)" }
    else { Add-Fail "Module missing: $mod" }
}
if (-not $isFull) {
    foreach ($mod in $fullModules) {
        $m = Get-Module -ListAvailable $mod | Sort-Object Version -Descending | Select-Object -First 1
        if ($m) { Add-Pass "Optional module $($m.Name) v$($m.Version)" }
        else { Add-Warn "Optional module not installed: $mod (Full tier)" }
    }
}

# ── 3. Profile integrity ─────────────────────────────────────────────────────
Write-WorkstationStep 'Profile integrity'
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
else { Add-Warn "Profile load slow: ${profileMs}ms (budget ${StartupBudgetMs}ms) — run optimize-profile" }

$sw2 = [Diagnostics.Stopwatch]::StartNew()
$null = pwsh -NoLogo -Command "exit 0"
$sw2.Stop()
$report.Metrics['PwshColdStartMs'] = $sw2.ElapsedMilliseconds
Add-Pass "pwsh cold start: $($sw2.ElapsedMilliseconds)ms"

# ── 5. Oh My Posh (Full tier) ────────────────────────────────────────────────
if ($isFull) { Write-WorkstationStep 'Oh My Posh' }
if ($isFull) {
if (Test-Path $ompConfig) {
    Add-Pass 'OMP theme file exists'
    try {
        $ompOut = oh-my-posh print primary --config $ompConfig 2>&1
        if ($LASTEXITCODE -eq 0 -and $ompOut) { Add-Pass 'OMP renders primary prompt' }
        else { Add-Fail "OMP render failed: $ompOut" }
    } catch { Add-Fail "OMP error: $_" }
} else { Add-Fail 'OMP config missing' }
}

# ── 6. Nerd Font (Full tier) ─────────────────────────────────────────────────
if ($isFull) { Write-WorkstationStep 'Nerd Font' }
if ($isFull) {
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
}

# ── 7. Windows Terminal (Full tier) ──────────────────────────────────────────
if ($isFull) { Write-WorkstationStep 'Windows Terminal' }
if ($isFull) {
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
}

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
$coreAliases = @('projects', 'gs', 'sysinfo')
$fullAliases = @('ll', 'Enter-Venv')
$aliasNames = $coreAliases + $(if ($isFull) { $fullAliases } else { @() })
$aliasTest = pwsh -NoProfile -Command @"
`$env:WORKSTATION_BANNER_SHOWN='1'
`$env:CI='1'
. '$live'
@('$($aliasNames -join "','")') | ForEach-Object {
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
foreach ($dir in $structureDirs) {
    if (Test-Path $dir) { Add-Pass "Directory: $dir" } else { Add-Fail "Directory missing: $dir" }
}

# ── 12. Functional smoke tests (Full tier) ───────────────────────────────────
if ($isFull) { Write-WorkstationStep 'Functional smoke tests' }
if ($isFull) {
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
}

# ── 13. Security settings (non-Defender, Full tier) ───────────────────────────
if ($isFull) { Write-WorkstationStep 'Security settings audit' }
if ($isFull) {
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
}

# ── 13b. SHADOW OPS readiness (Full tier) ─────────────────────────────────────
if ($isFull) { Write-WorkstationStep 'SHADOW OPS readiness' }
if ($isFull) {
if (Test-Path $modulePath) {
    $secTest = pwsh -NoProfile -Command @"
Import-Module '$modulePath' -Force
`$r = Get-SecurityReadinessReport
Write-Output "PGP:`$(`$r.PgpReady)"
Write-Output "TOR:`$(`$r.TorReady)"
Write-Output "HARD:`$(`$r.Hardened)"
Write-Output "LVL:`$(`$r.Level)"
"@
    if ($secTest -match 'PGP:True') { Add-Pass 'PGP key configured' } else { Add-Warn 'PGP not ready — pgp-repair' }
    if ($secTest -match 'TOR:True') { Add-Pass 'Tor Browser present' } else { Add-Warn 'Tor Browser missing — tor-setup' }
    if ($secTest -match 'HARD:True') { Add-Pass 'Tor profile hardened' } else { Add-Warn 'Tor not hardened — tor-harden' }
    if ($secTest -match 'LVL:READY') { Add-Pass 'SHADOW OPS readiness: READY' }
    elseif ($secTest -match 'LVL:PARTIAL') { Add-Warn 'SHADOW OPS readiness: PARTIAL' }
    else { Add-Warn 'SHADOW OPS readiness: SETUP' }
} else {
    Add-Warn 'SHADOW OPS check skipped — module missing'
}
}

# ── 14. Module + command health (Core) / full command center (Full) ───────────
Write-WorkstationStep 'Command center'
if ($isFull) {
    $requiredCmds = @(
        'doctor','repairterminal','updateall','backupconfig','restoreconfig','cleanup',
        'healthcheck','workstationstatus','securitycheck','devstart','workspace',
        'cheatsheet','helpme','fixprofile','reloadprofile','sysreport','logs','networkstatus','learn',
        'nettools','toolbox','toolcheck','sysaudit',
        'jarvis','dashboard','home','menu','go','scan','trustcheck','sec','revise','organize','downloads','komandy','palette'
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
} else {
    $coreCmds = @('doctor', 'home', 'go', 'reloadprofile', 'fixprofile')
    $helperTest = pwsh -NoProfile -Command @"
`$env:WORKSTATION_DASHBOARD='0'; `$env:WORKSTATION_DASHBOARD_SHOWN='1'; `$env:WORKSTATION_WELCOMED='1'; `$env:CI='1'
. '$live'
@('$($coreCmds -join "','")') | ForEach-Object { if (-not (Get-Command `$_ -EA SilentlyContinue)) { "MISSING:`$_" } }
"@
    $missingHelpers = $helperTest | Where-Object { $_ -like 'MISSING:*' }
    if (-not $missingHelpers) { Add-Pass 'Core commands loaded after profile' }
    else { Add-Fail ($missingHelpers -join ', ') }
}

if (Test-Path $modulePath) { Add-Pass 'KGreen.Workstation module present' }
elseif (Test-Path $toolkitLegacy) { Add-Pass 'Toolkit module present (legacy)' }
else { Add-Fail 'Command center module missing' }

$healthPath = Join-Path $logsRoot 'command-health.json'
if (Test-Path $healthPath) {
    try {
        $hc = Get-Content $healthPath -Raw | ConvertFrom-Json
        $report.Metrics['CommandHealthBroken'] = $hc.Broken
        if ($hc.Broken -gt 0) {
            Add-Fail "command-health: $($hc.Broken) broken"
        } else {
            Add-Pass "command-health: $($hc.Passed)/$($hc.TotalCommands) OK"
        }
    } catch { Add-Fail 'command-health.json unreadable' }
} else {
    Add-Fail 'command-health.json missing — run Test-WorkstationCommands -Quick'
}

if ($isFull) { Write-WorkstationStep 'go menu integrity' }
if ($isFull) {
if (Test-Path $menuAuditPath) {
    $menuOut = pwsh -NoLogo -NoProfile -File $menuAuditPath 2>&1 | Out-String
    if ($LASTEXITCODE -eq 0) { Add-Pass 'go menu audit OK' }
    else { Add-Fail "go menu audit: $($menuOut.Trim())" }
} else {
    Add-Warn 'Test-MenuAudit.ps1 missing'
}

$menuDeepPath = Join-Path $repoRoot 'Test-MenuDeepAudit.ps1'
if (Test-Path $menuDeepPath) {
    $deepOut = pwsh -NoLogo -NoProfile -File $menuDeepPath 2>&1 | Out-String
    if ($LASTEXITCODE -eq 0) { Add-Pass 'menu deep audit OK' }
    else { Add-Fail "menu deep audit: $($deepOut.Trim())" }
}

$anonAuditPath = Join-Path $repoRoot 'Test-AnonymityKitAudit.ps1'
if (Test-Path $anonAuditPath) {
    $anonOut = pwsh -NoLogo -NoProfile -File $anonAuditPath 2>&1 | Out-String
    if ($LASTEXITCODE -eq 0) { Add-Pass 'anon kit audit OK' }
    else { Add-Fail "anon kit audit: $($anonOut.Trim())" }
} else {
    Add-Warn 'Test-AnonymityKitAudit.ps1 missing'
}
}

if ($isFull) { Write-WorkstationStep 'Network tools' }
if ($isFull) {
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
}

if (Test-Path $wocScript) { Add-Pass 'WOC module present' }
else { Add-Fail 'WOC module missing' }

if ($isFull) { Write-WorkstationStep 'Startup command center benchmark' }
if ($isFull) {
$ccBench = pwsh -NoProfile -Command @"
`$env:CI=''
`$sw = [Diagnostics.Stopwatch]::StartNew()
. '$wocScript'
Show-Woc -Mode minimal -Force -NoHeal | Out-Null
`$sw.Stop()
Write-Output `$sw.ElapsedMilliseconds
"@
$ccMs = [int]($ccBench | Select-Object -Last 1)
$report.Metrics['CommandCenterMs'] = $ccMs
if ($ccMs -le 1000) { Add-Pass "Command center render: ${ccMs}ms <= 1000ms" }
else { Add-Warn "Command center render: ${ccMs}ms (target 1000ms)" }
}

if ($isFull -and (Test-Path $fontStatusPath)) {
    try {
        $fs = Get-Content $fontStatusPath -Raw | ConvertFrom-Json
        if ($fs.FontFace -eq 'CaskaydiaCove NF') { Add-Pass 'Font status: CaskaydiaCove NF' }
        else { Add-Warn "Font status: $($fs.FontFace)" }
    } catch { Add-Warn 'font-status.json unreadable' }
} elseif ($isFull) { Add-Warn 'Run Repair-WorkstationFonts.ps1' }

# ── 15. Git ──────────────────────────────────────────────────────────────────
Write-WorkstationStep 'Git configuration'
if (git --version 2>$null) { Add-Pass (git --version) } else { Add-Fail 'git not working' }
if (git config --global user.name 2>$null) { Add-Pass "Git user.name set" } else { Add-Warn 'Git user.name not configured' }
if (git config --global user.email 2>$null) { Add-Pass "Git user.email set" } else { Add-Warn 'Git user.email not configured' }

# ── Auto-fix pass ────────────────────────────────────────────────────────────
if ($Fix -and -not $FixPassCompleted -and $report.Failed.Count -gt 0) {
    & (Join-Path $PSScriptRoot 'Repair-DevReadyEnvironment.ps1') -Tier $Tier -FailedChecks @($report.Failed)
    Write-Host ''
    Write-Host 'Re-checking after auto-repair...' -ForegroundColor Cyan
    & $PSCommandPath -Tier $Tier -StartupBudgetMs $StartupBudgetMs -FixPassCompleted
    return
}

# ── Summary ──────────────────────────────────────────────────────────────────
$report.Metrics['PassCount']  = $report.Passed.Count
$report.Metrics['FailCount']  = $report.Failed.Count
$report.Metrics['WarnCount']  = $report.Warnings.Count
$report.Metrics['Complete']   = ($report.Failed.Count -eq 0)

$outDir = $logsRoot
if (-not (Test-Path $outDir)) { New-Item -ItemType Directory -Force -Path $outDir | Out-Null }
$outFile = Join-Path $outDir ("validation-{0}.json" -f (Get-Date -Format 'yyyyMMdd-HHmmss'))
$report | ConvertTo-Json -Depth 6 | Set-Content $outFile -Encoding UTF8

Write-Host ''
Write-Host '════════════════ VALIDATION REPORT ════════════════' -ForegroundColor Cyan
Write-Host "Tier:    $Tier" -ForegroundColor DarkGray
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

Write-Host ''
if ($report.Failed.Count -eq 0) {
    Write-Host 'Ready to work.' -ForegroundColor Green
} else {
    Write-Host 'Not ready yet.' -ForegroundColor Red
    $hints = Get-DevReadyFixHints -Failed $report.Failed
    if ($hints.Count -gt 0) {
        Write-Host 'Try this:' -ForegroundColor Yellow
        $hints | ForEach-Object { Write-Host "  → $_" -ForegroundColor DarkGray }
    }
}

$exitCode = if ($report.Failed.Count -eq 0) { 0 } else { 1 }
$global:LASTEXITCODE = $exitCode
if ($MyInvocation.InvocationName -eq '.') { exit $exitCode }
return
