#Requires -Version 7.0
<#
.SYNOPSIS
    HomeBase DevShell one-line bootstrap installer.
.EXAMPLE
    irm https://raw.githubusercontent.com/XKush/homebase-devshell/v2.0.3/install.ps1 | iex
.EXAMPLE
    pwsh -File install.ps1
#>
param(
    [string]$InstallPath = (Join-Path $env:USERPROFILE '.homebase\devshell'),
    [string]$RepoUrl = 'https://github.com/XKush/homebase-devshell.git',
    [switch]$SkipClone
)

$ErrorActionPreference = 'Stop'
$script:DevShellReleaseTag = 'v2.0.3'

function Test-DevShellRepo {
    param([string]$Path)
    if ([string]::IsNullOrWhiteSpace($Path)) { return $false }
    return Test-Path (Join-Path $Path 'lib\HomeBasePaths.ps1')
}

function Get-BootstrapRepoRoot {
    if (-not [string]::IsNullOrWhiteSpace($PSScriptRoot) -and (Test-DevShellRepo -Path $PSScriptRoot)) {
        return $PSScriptRoot
    }
    if ($env:HOMEBASE_DEVSHELL_ROOT -and (Test-DevShellRepo -Path $env:HOMEBASE_DEVSHELL_ROOT)) {
        return $env:HOMEBASE_DEVSHELL_ROOT
    }
    return $null
}

function Initialize-DevShellInstallPaths {
    param([Parameter(Mandatory)][string]$RepoRoot)

    $configPath = Join-Path $RepoRoot 'Config\homebase.defaults.json'
    if (Test-Path $configPath) {
        $cfg = Get-Content $configPath -Raw | ConvertFrom-Json
        $escaped = $RepoRoot.TrimEnd('\').Replace('\', '\\')
        if ([string]$cfg.RepositoryRoot -ne $escaped) {
            $cfg.RepositoryRoot = $escaped
            $cfg | ConvertTo-Json -Depth 5 | Set-Content $configPath -Encoding UTF8
        }
    }

    [Environment]::SetEnvironmentVariable('WORKSTATION_ROOT', $RepoRoot, 'User')
    $env:WORKSTATION_ROOT = $RepoRoot
    $env:HOMEBASE_DEVSHELL_ROOT = $RepoRoot
}

Write-Host ''
Write-Host 'HomeBase DevShell — install' -ForegroundColor Cyan
Write-Host 'Install. Check. Done.' -ForegroundColor DarkGray
Write-Host ''

if ($PSVersionTable.PSVersion.Major -lt 7) {
    Write-Host 'FAIL: PowerShell 7+ is required (https://aka.ms/powershell)' -ForegroundColor Red
    exit 1
}

$repoRoot = Get-BootstrapRepoRoot

if (-not $repoRoot -and -not $SkipClone) {
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        Write-Host 'FAIL: git is not installed or not on PATH.' -ForegroundColor Red
        Write-Host 'Install Git, clone the repository manually, then re-run install.ps1 from that folder.' -ForegroundColor DarkGray
        exit 1
    }
    if (-not (Test-Path $InstallPath)) {
        New-Item -ItemType Directory -Force -Path $InstallPath | Out-Null
    }
    if (Test-DevShellRepo -Path $InstallPath) {
        Write-Host "Using existing checkout: $InstallPath" -ForegroundColor DarkGray
    } else {
        Write-Host "Cloning $script:DevShellReleaseTag to $InstallPath ..." -ForegroundColor DarkGray
        git clone --branch $script:DevShellReleaseTag --depth 1 $RepoUrl $InstallPath
        if ($LASTEXITCODE -ne 0) {
            Write-Host 'FAIL: git clone failed.' -ForegroundColor Red
            Write-Host "Try: git clone $RepoUrl $InstallPath" -ForegroundColor DarkGray
            exit 1
        }
    }
    $repoRoot = $InstallPath
}

if (-not $repoRoot -or -not (Test-DevShellRepo -Path $repoRoot)) {
    Write-Host 'FAIL: HomeBase DevShell repository not found.' -ForegroundColor Red
    Write-Host 'Clone the repo, cd into it, and run: pwsh -File install.ps1' -ForegroundColor DarkGray
    Write-Host 'Or set `$env:HOMEBASE_DEVSHELL_ROOT` to your checkout path.' -ForegroundColor DarkGray
    exit 1
}

$env:HOMEBASE_DEVSHELL_ROOT = $repoRoot
Initialize-DevShellInstallPaths -RepoRoot $repoRoot
Write-Host "Repository: $repoRoot" -ForegroundColor DarkGray

Write-Host ''
Write-Host '==> Bootstrap (folders + profile, user scope)' -ForegroundColor Cyan
& (Join-Path $repoRoot 'scripts\maintainer\install\Install-Workstation.ps1') -Force -SkipSoftware -SkipAdmin
if ($LASTEXITCODE -and $LASTEXITCODE -ne 0) {
    Write-Host ''
    Write-Host 'FAIL: Bootstrap reported errors. See output above and C:\Logs\Workstation\' -ForegroundColor Red
    exit $LASTEXITCODE
}

Write-Host ''
Write-Host '==> Command health cache' -ForegroundColor Cyan
$cmdTest = Join-Path $repoRoot 'scripts\maintainer\test\Test-WorkstationCommands.ps1'
if (Test-Path $cmdTest) {
    & $cmdTest -Quick
} else {
    Write-Host 'WARN: Test-WorkstationCommands.ps1 missing — run scan after first login' -ForegroundColor Yellow
}

Write-Host ''
Write-Host '==> Health check (devshell doctor)' -ForegroundColor Cyan
& (Join-Path $repoRoot 'devshell.ps1') doctor
$doctorExit = $LASTEXITCODE

Write-Host ''
if ($doctorExit -eq 0) {
    Write-Host 'Ready to work.' -ForegroundColor Green
    Write-Host ''
    Write-Host 'Next: close this terminal, open a new one, and run doctor anytime.' -ForegroundColor DarkGray
    Write-Host "  pwsh -File `"$repoRoot\devshell.ps1`" doctor" -ForegroundColor DarkGray
    exit 0
}

Write-Host 'Not ready yet. Fix what doctor shows, then run install again.' -ForegroundColor Red
Write-Host "  pwsh -File `"$repoRoot\devshell.ps1`" install" -ForegroundColor DarkGray
exit $doctorExit
