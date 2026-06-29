#Requires -Version 7.0
<#
.SYNOPSIS
    HomeBase DevShell one-line bootstrap installer.
.EXAMPLE
    irm https://raw.githubusercontent.com/XKush/homebase-devshell/v2.0.0/install.ps1 | iex
.EXAMPLE
    pwsh -File install.ps1
#>
param(
    [string]$InstallPath = (Join-Path $env:USERPROFILE '.homebase\devshell'),
    [string]$RepoUrl = 'https://github.com/XKush/homebase-devshell.git',
    [switch]$SkipClone
)

$ErrorActionPreference = 'Stop'

function Test-DevShellRepo {
    param([string]$Path)
    return Test-Path (Join-Path $Path 'lib\HomeBasePaths.ps1')
}

function Get-BootstrapRepoRoot {
    if (Test-DevShellRepo -Path $PSScriptRoot) { return $PSScriptRoot }
    if ($env:HOMEBASE_DEVSHELL_ROOT -and (Test-DevShellRepo -Path $env:HOMEBASE_DEVSHELL_ROOT)) {
        return $env:HOMEBASE_DEVSHELL_ROOT
    }
    return $null
}

Write-Host ''
Write-Host 'HomeBase DevShell v2.0.0 — install' -ForegroundColor Cyan
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
        Write-Host "Cloning repository to $InstallPath ..." -ForegroundColor DarkGray
        git clone $RepoUrl $InstallPath
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
Write-Host "Repository: $repoRoot" -ForegroundColor DarkGray

Write-Host ''
Write-Host '==> Bootstrap (folders + profile, user scope)' -ForegroundColor Cyan
& (Join-Path $repoRoot 'Install-Workstation.ps1') -Force -SkipSoftware -SkipAdmin
if ($LASTEXITCODE -and $LASTEXITCODE -ne 0) {
    Write-Host ''
    Write-Host 'FAIL: Bootstrap reported errors. See output above and C:\Logs\Workstation\' -ForegroundColor Red
    exit $LASTEXITCODE
}

Write-Host ''
Write-Host '==> Health check (devshell doctor)' -ForegroundColor Cyan
& (Join-Path $repoRoot 'devshell.ps1') doctor
$doctorExit = $LASTEXITCODE

Write-Host ''
if ($doctorExit -eq 0) {
    Write-Host 'SUCCESS: HomeBase DevShell is ready.' -ForegroundColor Green
    Write-Host ''
    Write-Host 'Next steps:' -ForegroundColor Cyan
    Write-Host '  1. Restart Windows Terminal' -ForegroundColor DarkGray
    Write-Host "  2. pwsh -File `"$repoRoot\devshell.ps1`" status" -ForegroundColor DarkGray
    exit 0
}

Write-Host 'FAIL: Health check did not pass.' -ForegroundColor Red
Write-Host 'Review C:\Logs\Workstation\validation-*.json and re-run after fixes.' -ForegroundColor DarkGray
exit $doctorExit
