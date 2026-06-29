#Requires -Version 7.0
<#
.SYNOPSIS
    MAX level pass — OpenSSL, PATH, git, profile, git repo, security, verify.
#>
param(
    [switch]$SkipSecurity,
    [switch]$SkipGitInit,
    [string]$GitEmail
)

. (Join-Path $PSScriptRoot '..\_Resolve-RepoRoot.ps1')
$repoRoot = Resolve-WorkstationRepoRoot -Start $PSScriptRoot

$ErrorActionPreference = 'Continue'
$root = 'C:\Scripts\Workstation'
Write-Host "`n  HOME BASE — MAX LEVEL PASS`n" -ForegroundColor Cyan

# 1. PATH + OpenSSL
& (Join-Path $root 'Fix-WorkstationPath.ps1')
& (Join-Path $root 'Install-NetworkToolkit.ps1') -SkipOptional

# 2. Git identity
$gitArgs = @()
if ($GitEmail) { $gitArgs += '-Email', $GitEmail }
& (Join-Path $root 'Configure-GitIdentity.ps1') @gitArgs

# 3. Git repo for workstation scripts
if (-not $SkipGitInit) {
    Push-Location $root
    if (-not (Test-Path '.git')) {
        git init -b main | Out-Null
        Write-Host '  [OK] git init C:\Scripts\Workstation' -ForegroundColor Green
    } else {
        Write-Host '  [skip] git repo already exists' -ForegroundColor DarkGray
    }
    Pop-Location
}

# 4. Profile deploy + benchmark
& (Join-Path $root 'Install-ShellProfile.ps1') -Force
& (Join-Path $root 'Optimize-Profile.ps1') -Apply

# 5. Security (admin UAC prompt)
if (-not $SkipSecurity) {
    Write-Host '  [..] Harden-Security (UAC prompt)...' -ForegroundColor Yellow
    $sec = Join-Path $root 'Harden-Security.ps1'
    Start-Process pwsh -Verb RunAs -ArgumentList @('-NoProfile', '-File', $sec, '-Force') -Wait
}

# 6. Refresh caches + verify
& (Join-Path $root 'Invoke-Maintenance.ps1') -Full
Import-Module (Join-Path $root 'modules\KGreen.Workstation.psm1') -Force
& (Join-Path $root 'Test-WorkstationCommands.ps1') -Quick | Out-Null
trustcheck
& (Join-Path $root 'Generate-HomeBaseCheatsheet.ps1') | Out-Null

Write-Host "`n  MAX pass complete. Restart Windows Terminal.`n" -ForegroundColor Green
