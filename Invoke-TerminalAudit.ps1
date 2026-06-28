#Requires -Version 7.0
# Phase 1 — Terminal audit (read-only)
$ErrorActionPreference = 'Continue'
. "$PSScriptRoot\lib\WorkstationCommon.ps1"
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$out = "C:\Logs\Workstation\terminal-audit-$stamp.json"
$r = [ordered]@{ Timestamp = (Get-Date).ToString('o'); Issues = [System.Collections.Generic.List[string]]::new(); Checks = [ordered]@{} }

function Issue($m) { $r.Issues.Add($m) }

# Fonts registry
$hkcu = Get-ItemProperty 'HKCU:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts' -EA SilentlyContinue
$fontNames = @($hkcu.PSObject.Properties.Name | Where-Object { $_ -match 'Caskaydia|JetBrains|Cascadia' })
$r.Checks.FontRegistry = $fontNames
$r.Checks.HasCaskaydiaNF = [bool]($fontNames | Where-Object { $_ -like 'CaskaydiaCove NF Regular*' })
$r.Checks.HasJetBrainsNF = [bool]($fontNames | Where-Object { $_ -match 'JetBrains.*Mono.*NF' })
if (-not $r.Checks.HasCaskaydiaNF) { Issue 'CaskaydiaCove NF Regular not in HKCU registry' }

# WT settings
$wtPath = Join-Path $env:LOCALAPPDATA 'Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json'
if (Test-Path $wtPath) {
    $wt = Get-Content $wtPath -Raw | ConvertFrom-Json
    $r.Checks.WTDefaultProfile = $wt.defaultProfile
    $r.Checks.WTFontFace = $wt.profiles.defaults.font.face
    $r.Checks.WTColorScheme = $wt.profiles.defaults.colorScheme
    if ($wt.profiles.defaults.font.face -ne 'CaskaydiaCove NF' -and $wt.profiles.defaults.font.face -notmatch 'JetBrains') {
        Issue "WT font face: $($wt.profiles.defaults.font.face)"
    }
} else { Issue 'Windows Terminal settings.json missing' }

# Default terminal app (Win11)
$defTerm = Get-ItemProperty 'HKCU:\Console\%%Startup' -EA SilentlyContinue
$r.Checks.DefaultTerminalDelegation = $defTerm.DelegationConsole
$r.Checks.HostName = $Host.Name
$r.Checks.TerminalProgram = $env:WT_SESSION
if ($Host.Name -eq 'ConsoleHost' -and -not $env:WT_SESSION) { Issue 'Running in legacy ConsoleHost — not Windows Terminal' }

# OMP
$ompConfig = 'C:\Scripts\Workstation\terminal\revios-hacker.omp.json'
$r.Checks.OMPConfigExists = Test-Path $ompConfig
try {
    $ompOut = oh-my-posh print primary --config $ompConfig 2>&1 | Out-String
    $r.Checks.OMPRenders = ($LASTEXITCODE -eq 0) -and ($ompOut -notmatch 'unable to create text')
    $r.Checks.OMPOutputSample = $ompOut.Substring(0, [math]::Min(200, $ompOut.Length))
    if ($ompOut -match 'unable to create text') { Issue 'OMP template error detected' }
} catch { Issue "OMP error: $_"; $r.Checks.OMPRenders = $false }

try {
    $dbg = oh-my-posh debug --config $ompConfig 2>&1 | Out-String
    $r.Checks.OMPDebug = $dbg.Substring(0, [math]::Min(1500, $dbg.Length))
} catch { $r.Checks.OMPDebug = $_.Exception.Message }

# Profiles
$profiles = @(
    'C:\Scripts\Workstation\profile\Microsoft.PowerShell_profile.ps1',
    (Join-Path $env:USERPROFILE 'Documents\PowerShell\Microsoft.PowerShell_profile.ps1'),
    (Join-Path $env:USERPROFILE 'Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1')
)
$r.Checks.Profiles = @($profiles | ForEach-Object { @{ Path = $_; Exists = (Test-Path $_) } })

# Fastfetch
try {
    $ff = fastfetch 2>&1 | Out-String
    $r.Checks.FastfetchSample = ($ff -split "`n" | Select-Object -First 25) -join "`n"
    if ($ff -match 'Windows Console|Consolas') { Issue 'Fastfetch reports ConsoleHost/Consolas' }
} catch { Issue "fastfetch failed: $_" }

# UTF-8
$r.Checks.OutputEncoding = [Console]::OutputEncoding.WebName

$r | ConvertTo-Json -Depth 8 | Set-Content $out -Encoding UTF8
Write-Host "Terminal audit: $($r.Issues.Count) issues -> $out"
$r.Issues | ForEach-Object { Write-Host "  ! $_" -ForegroundColor Yellow }
exit $(if ($r.Issues.Count -eq 0) { 0 } else { 1 })
