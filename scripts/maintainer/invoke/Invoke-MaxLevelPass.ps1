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
$root = $repoRoot
Write-Host "`n  HOME BASE — MAX LEVEL PASS`n" -ForegroundColor Cyan

# 1. PATH + OpenSSL
& (Resolve-WorkstationScript -Name 'Fix-WorkstationPath.ps1' -Start $PSScriptRoot)
& (Resolve-WorkstationScript -Name 'Install-NetworkToolkit.ps1' -Start $PSScriptRoot) -SkipOptional

# 2. Git identity
$gitArgs = @()
if ($GitEmail) { $gitArgs += '-Email', $GitEmail }
& (Resolve-WorkstationScript -Name 'Configure-GitIdentity.ps1' -Start $PSScriptRoot) @gitArgs

# 3. Git repo for workstation scripts
if (-not $SkipGitInit) {
    Push-Location $root
    if (-not (Test-Path '.git')) {
        git init -b main | Out-Null
        Write-Host "  [OK] git init $root" -ForegroundColor Green
    } else {
        Write-Host '  [skip] git repo already exists' -ForegroundColor DarkGray
    }
    Pop-Location
}

# 4. Profile deploy + benchmark
& (Resolve-WorkstationScript -Name 'Install-ShellProfile.ps1' -Start $PSScriptRoot) -Force
& (Resolve-WorkstationScript -Name 'Optimize-Profile.ps1' -Start $PSScriptRoot) -Apply

# 5. Security (admin UAC prompt)
if (-not $SkipSecurity) {
    Write-Host '  [..] Harden-Security (UAC prompt)...' -ForegroundColor Yellow
    $sec = Resolve-WorkstationScript -Name 'Harden-Security.ps1' -Start $PSScriptRoot
    Start-Process pwsh -Verb RunAs -ArgumentList @('-NoProfile', '-File', $sec, '-Force') -Wait
}

# 6. Refresh caches + verify
& (Resolve-WorkstationScript -Name 'Invoke-Maintenance.ps1' -Start $PSScriptRoot) -Full
Import-Module (Join-Path $root 'modules\KGreen.Workstation.psm1') -Force
& (Resolve-WorkstationScript -Name 'Test-WorkstationCommands.ps1' -Start $PSScriptRoot) -Quick | Out-Null
trustcheck
& (Resolve-WorkstationScript -Name 'Generate-HomeBaseCheatsheet.ps1' -Start $PSScriptRoot) | Out-Null

Write-Host "`n  MAX pass complete. Restart Windows Terminal.`n" -ForegroundColor Green
