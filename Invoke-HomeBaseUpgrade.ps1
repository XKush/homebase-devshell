#Requires -Version 7.0
# Tier 1–3 upgrade pass — run once after updates

param([switch]$SkipOpenSSL, [switch]$SkipTasks)

$root = 'C:\Scripts\Workstation'
Write-Host "`n  HOME BASE UPGRADE PASS`n" -ForegroundColor Cyan

# Profile sync
& (Join-Path $root 'Install-ShellProfile.ps1') -Force

# Maintenance + cache refresh
& (Join-Path $root 'Invoke-Maintenance.ps1') -Full

# OpenSSL optional
if (-not $SkipOpenSSL -and -not (Get-Command openssl -EA SilentlyContinue)) {
    Write-Host "  Installing OpenSSL..." -ForegroundColor Yellow
    winget install -e --id ShiningLight.OpenSSL.Light --accept-package-agreements --accept-source-agreements --disable-interactivity
}

# Git identity hint
$email = git config --global user.email 2>$null
if (-not $email -or $email -match 'local\.workstation|example\.com|placeholder') {
    Write-Host "  [hint] Set git email: git config --global user.email you@domain.com" -ForegroundColor Yellow
}

Import-Module (Join-Path $root 'modules\KGreen.Workstation.psm1') -Force
& (Join-Path $root 'Test-WorkstationCommands.ps1') -Quick | Out-Null
trustcheck

if (-not $SkipTasks) {
    try { & (Join-Path $root 'Register-WorkstationTasks.ps1') -Force } catch { Write-Host "  [warn] tasks need admin: $_" -ForegroundColor Yellow }
}

& (Join-Path $root 'Generate-HomeBaseCheatsheet.ps1') | Out-Null

Write-Host "`n  Upgrade pass complete. Open new WT tab.`n" -ForegroundColor Green
