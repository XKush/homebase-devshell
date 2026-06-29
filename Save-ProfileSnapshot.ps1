#Requires -Version 7.0
<#
.SYNOPSIS
    Capture Profile-layer runtime snapshot for Wave A baseline and passports.
.PARAMETER OutputPath
    JSON output path. Default: Logs/Phase2/profile-snapshot-{label}.json
.PARAMETER Label
    Suffix for default filename (e.g. pre, post, commit-pending).
#>
[CmdletBinding()]
param(
    [string]$OutputPath,
    [string]$Label = (Get-Date -Format 'yyyyMMdd-HHmmss'),
    [string]$Wave = 'Profile'
)

$ErrorActionPreference = 'Stop'
$wsRoot = $PSScriptRoot
. (Join-Path $wsRoot 'lib\HomeBasePaths.ps1')

$logsRoot = Get-HomeBasePath -Name Logs
$phaseDir = Join-Path $logsRoot 'Phase2'
if (-not (Test-Path $phaseDir)) { New-Item -ItemType Directory -Force -Path $phaseDir | Out-Null }

if (-not $OutputPath) {
    $OutputPath = Join-Path $phaseDir ("profile-snapshot-{0}.json" -f $Label)
}

$canonicalProfile = Join-Path $wsRoot 'profile\Microsoft.PowerShell_profile.ps1'
$ompTheme = Join-Path $wsRoot 'terminal\active-theme.omp.json'

$envSnapshot = [ordered]@{}
foreach ($key in @('HOMEBASE_CONFIG', 'HOMEBASE_RUNTIME', 'WORKSTATION_ROOT', 'WORKSTATION_LANG',
    'WORKSTATION_TRUST_MODE', 'WORKSTATION_STARTUP_MODE', 'PROFILE_LOADED', 'FASTFETCH_CONFIG',
    'PROJECTS_HOME', 'CONFIGS_HOME', 'TOOLS_HOME', 'NETWORKING_HOME', 'WS_TEMP')) {
    $envSnapshot[$key] = [string](Get-Item -Path "Env:$key" -ErrorAction SilentlyContinue).Value
}

$imported = @(Get-Module | ForEach-Object { [ordered]@{
    Name    = $_.Name
    Version = $_.Version.ToString()
    Path    = $_.Path
}})

$ompAvailable = [bool](Get-Command oh-my-posh -ErrorAction SilentlyContinue)
$ompThemeExists = Test-Path $ompTheme

$snapshot = [ordered]@{
    Timestamp         = (Get-Date).ToString('o')
    Wave              = $Wave
    ProfilePath       = $PROFILE
    ProfileExists     = Test-Path $PROFILE
    ProfileCanonical  = $canonicalProfile
    CanonicalExists   = Test-Path $canonicalProfile
    ProfileSynced     = $false
    Env               = $envSnapshot
    ImportedModules   = $imported
    WorkingDirectory  = (Get-Location).Path
    OhMyPosh          = [ordered]@{
        Available   = $ompAvailable
        ThemePath   = $ompTheme
        ThemeExists = $ompThemeExists
    }
    GitCommit         = if (Test-Path (Join-Path $wsRoot '.git')) {
        (git -C $wsRoot rev-parse --short HEAD 2>$null)
    } else { $null }
}

if ($snapshot.ProfileExists -and $snapshot.CanonicalExists) {
    try {
        $deployed = (Get-FileHash $PROFILE -Algorithm SHA256).Hash
        $canonical = (Get-FileHash $canonicalProfile -Algorithm SHA256).Hash
        $snapshot.ProfileSynced = ($deployed -eq $canonical)
    } catch {
        $snapshot.ProfileSynced = $false
    }
}

$snapshot | ConvertTo-Json -Depth 8 | Set-Content -Path $OutputPath -Encoding UTF8
Write-Host "Profile snapshot saved: $OutputPath" -ForegroundColor Green
return $OutputPath
