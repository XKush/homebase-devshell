#Requires -Version 7.0
<#
.SYNOPSIS
    Phase 2 — Safe workstation organization (backup before every change).
#>
param(
    [switch]$Force,
    [switch]$WhatIf
)

$ErrorActionPreference = 'Continue'
. "$PSScriptRoot\lib\WorkstationCommon.ps1"

$logsRoot = Get-WorkstationLogsRoot
$backupsRoot = Get-WorkstationBackupsRoot
$repoRoot = Get-HomeBasePath -Name RepositoryRoot

$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$logDir = $logsRoot
$bakDir = Join-Path $backupsRoot "organization-$stamp"
$actions = [System.Collections.Generic.List[object]]::new()

function Log-Action([string]$Action, [string]$Detail, [string]$Result = 'OK') {
    $entry = [ordered]@{ Time = (Get-Date).ToString('o'); Action = $Action; Detail = $Detail; Result = $Result }
    $actions.Add($entry)
    Write-WorkstationLog "$Action — $Detail" $(if ($Result -eq 'OK') { 'OK' } else { 'WARN' })
}

Write-WorkstationStep 'Workstation organization — backup first'
if (-not $WhatIf) {
    New-Item -ItemType Directory -Force -Path $bakDir | Out-Null
    Log-Action 'Backup' "Created $bakDir"
}

# ── Create standard structure ──────────────────────────────────────────────────
$structure = @{
    'C:\Tools'              = @('Portable', 'Scripts')
    'C:\Scripts'            = @('Workstation', 'Networking', 'Maintenance')
    'C:\Projects'           = @('_Templates')
    'C:\Security'           = @('Audits', 'Policies')
    'C:\Networking'         = @('Tools', 'Captures', 'Scripts', 'Docs')
    'C:\Logs'               = @('Workstation', 'Networking', 'Maintenance')
    'C:\Backups'            = @('Workstation', 'Configs')
    'C:\Configs'            = @('Workstation', 'Terminal', 'Network')
    'C:\Temp'               = @('Scratch', 'Installers')
    'C:\Downloads\Archive'  = @('Installers', 'Old', 'Shortcuts')
}

foreach ($root in $structure.Keys) {
    if (-not (Test-Path $root) -and -not $WhatIf) {
        New-Item -ItemType Directory -Force -Path $root | Out-Null
        Log-Action 'CreateFolder' $root
    }
    foreach ($sub in $structure[$root]) {
        $full = Join-Path $root $sub
        if (-not (Test-Path $full) -and -not $WhatIf) {
            New-Item -ItemType Directory -Force -Path $full | Out-Null
            Log-Action 'CreateFolder' $full
        }
    }
}

# ── README stubs (navigation) ─────────────────────────────────────────────────
$readmes = @{
    'C:\Tools\README.txt'       = 'Portable tools and utilities. Installed apps live in Program Files.'
    'C:\Scripts\README.txt'     = "Automation scripts. Workstation: $repoRoot"
    'C:\Projects\README.txt'    = 'All development projects. Use: new-project Name'
    'C:\Security\README.txt'    = 'Security audit outputs and policy notes.'
    'C:\Networking\README.txt'  = 'Network captures, docs, scripts. Commands: nettools, networkstatus'
    'C:\Logs\README.txt'        = "System logs. Workstation logs: $logsRoot"
    'C:\Backups\README.txt'     = 'Configuration backups. Use: backupconfig'
    'C:\Configs\README.txt'     = 'Exported configs (terminal, git, network).'
    'C:\Temp\README.txt'        = 'Safe scratch space. Cleaned by Invoke-Housekeeping.ps1'
}
foreach ($rp in $readmes.Keys) {
    if (-not (Test-Path $rp) -and -not $WhatIf) {
        Set-Content $rp $readmes[$rp] -Encoding UTF8
        Log-Action 'CreateReadme' $rp
    }
}

# ── Archive Downloads installers ─────────────────────────────────────────────
$dlArchive = 'C:\Downloads\Archive\Installers'
$downloads = Join-Path $env:USERPROFILE 'Downloads'
if (Test-Path $downloads) {
    Get-ChildItem $downloads -File -EA SilentlyContinue |
        Where-Object { $_.Extension -match '\.(exe|msi|msix|zip|7z)$' -and $_.LastWriteTime -lt (Get-Date).AddDays(-7) } |
        ForEach-Object {
            $dest = Join-Path $dlArchive $_.Name
            if ($WhatIf) { Log-Action 'WouldArchive' $_.FullName; return }
            if (-not (Test-Path $dest)) {
                Copy-Item $_.FullName (Join-Path $bakDir $_.Name) -Force
                Move-Item $_.FullName $dest -Force
                Log-Action 'ArchiveInstaller' "$($_.Name) -> $dlArchive"
            }
        }
}

# ── Archive broken desktop shortcuts ───────────────────────────────────────────
$shell = New-Object -ComObject WScript.Shell
$shortcutArchive = 'C:\Downloads\Archive\Shortcuts'
foreach ($scan in @((Join-Path $env:USERPROFILE 'Desktop'), $downloads)) {
    if (-not (Test-Path $scan)) { continue }
    Get-ChildItem $scan -Filter '*.lnk' -EA SilentlyContinue | ForEach-Object {
        try {
            $lnk = $shell.CreateShortcut($_.FullName)
            if ($lnk.TargetPath -and -not (Test-Path $lnk.TargetPath)) {
                $dest = Join-Path $shortcutArchive $_.Name
                if ($WhatIf) { Log-Action 'WouldArchiveShortcut' $_.FullName; return }
                Copy-Item $_.FullName (Join-Path $bakDir $_.Name) -Force
                Move-Item $_.FullName $dest -Force
                Log-Action 'ArchiveBrokenShortcut' $_.FullName
            }
        } catch { }
    }
}

# ── Link Sysinternals shortcuts into C:\Networking\Tools ─────────────────────
$sysDir = @(
    'C:\Program Files\Sysinternals',
    (Join-Path $env:USERPROFILE 'Downloads\SysinternalsSuite'),
    'C:\Tools\Sysinternals'
) | Where-Object { Test-Path $_ } | Select-Object -First 1

if ($sysDir -and -not $WhatIf) {
    foreach ($tool in @('procexp64.exe','procmon64.exe','tcpview64.exe')) {
        $src = Join-Path $sysDir $tool
        if (Test-Path $src) {
            $link = Join-Path 'C:\Networking\Tools' ($tool -replace '\.exe$','.lnk')
            if (-not (Test-Path $link)) {
                $s = $shell.CreateShortcut($link)
                $s.TargetPath = $src
                $s.WorkingDirectory = $sysDir
                $s.Save()
                Log-Action 'SysinternalsLink' $link
            }
        }
    }
}

# ── PATH dedupe ────────────────────────────────────────────────────────────────
if (-not $WhatIf) {
    & "$PSScriptRoot\Fix-WorkstationPath.ps1" | Out-Null
    Log-Action 'PathDedupe' 'Fix-WorkstationPath.ps1'
}

# ── Environment variables ──────────────────────────────────────────────────────
$envVars = @{
    PROJECTS_HOME   = 'C:\Projects'
    WORKSTATION_ROOT = $repoRoot
    NETWORKING_HOME = 'C:\Networking'
    CONFIGS_HOME    = 'C:\Configs'
    TOOLS_HOME      = 'C:\Tools'
    WS_TEMP         = 'C:\Temp\Scratch'
}
foreach ($kv in $envVars.GetEnumerator()) {
    $cur = [Environment]::GetEnvironmentVariable($kv.Key, 'User')
    if ($cur -ne $kv.Value -and -not $WhatIf) {
        [Environment]::SetEnvironmentVariable($kv.Key, $kv.Value, 'User')
        Log-Action 'SetEnvVar' "$($kv.Key)=$($kv.Value)"
    }
}

# ── Report ───────────────────────────────────────────────────────────────────
$reportPath = Join-Path $logDir "organization-actions-$stamp.json"
@{
    Timestamp = (Get-Date).ToString('o')
    BackupDir = $bakDir
    WhatIf    = [bool]$WhatIf
    Actions   = @($actions)
} | ConvertTo-Json -Depth 5 | Set-Content $reportPath -Encoding UTF8

Write-WorkstationStep 'Organization complete'
Write-Host "  Actions: $($actions.Count) | Report: $reportPath" -ForegroundColor DarkGray
Write-Host "  Backup:  $bakDir" -ForegroundColor DarkGray
