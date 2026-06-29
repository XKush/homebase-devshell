#Requires -Version 7.0
<#
.SYNOPSIS
    Master orchestrator — ReviOS professional workstation setup.
.NOTES
    Microsoft Defender AV is NEVER enabled, installed, or reactivated by this suite.
#>
param(
    [switch]$Force,
    [switch]$SkipSoftware,
    [switch]$SkipAdmin,
    [ValidateSet('Quad9', 'Cloudflare', 'Mullvad', 'None')]
    [string]$DnsProvider = 'Quad9'
)

$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
. "$root\lib\WorkstationCommon.ps1"

Write-Host @'

 ╔══════════════════════════════════════════════════╗
 ║  ReviOS Professional Workstation Setup         ║
 ║  Privacy · Performance · Hardening (no Defender) ║
 ╚══════════════════════════════════════════════════╝

'@ -ForegroundColor Green

Assert-DefenderUntouched

# 1. Folder structure
Write-WorkstationStep 'Folder structure'
foreach ($d in @('C:\Tools','C:\Scripts','C:\Projects','C:\Logs','C:\Backups','C:\Security')) {
    New-Item -ItemType Directory -Force -Path $d | Out-Null
}
Write-WorkstationLog 'Folders verified' 'OK'

# 2. Backup before changes
& "$root\Backup-Configuration.ps1" -Force:$Force

# 3. Software
if (-not $SkipSoftware) {
    & "$root\Install-Software.ps1" -Force:$Force
}

# 4. Shell profile (user scope)
& "$root\Install-ShellProfile.ps1" -Force:$Force

# 5. Admin scripts
if (-not $SkipAdmin) {
    if (Test-WorkstationAdmin) {
        & "$root\Optimize-Performance.ps1" -Force:$Force
        & "$root\Configure-Privacy.ps1" -Force:$Force -DnsProvider $DnsProvider
        & "$root\Harden-Security.ps1" -Force:$Force
        & "$root\Configure-Network.ps1" -Force:$Force
    } else {
        Write-Host @'

Admin steps skipped — re-run elevated:
  Start-Process pwsh -Verb RunAs -ArgumentList '-File C:\Scripts\Workstation\Install-Workstation.ps1 -Force -SkipSoftware'

Or run individually:
  Optimize-Performance.ps1
  Configure-Privacy.ps1
  Harden-Security.ps1
  Configure-Network.ps1

'@ -ForegroundColor Yellow
    }
} else {
    Write-WorkstationLog 'Admin scripts skipped (-SkipAdmin)' 'WARN'
}

Write-WorkstationStep 'Git identity defaults'
& "$root\Configure-GitIdentity.ps1"

Write-WorkstationStep 'PATH repair'
& "$root\Fix-WorkstationPath.ps1"

Write-WorkstationStep 'Final validation'
& "$root\Validate-Workstation.ps1" -StartupBudgetMs 600
if ($LASTEXITCODE -ne 0) {
    Write-WorkstationLog 'Validation reported failures — review C:\Logs\Workstation\' 'ERROR'
    exit 1
}

Write-WorkstationStep 'Setup complete'
Write-Host @'
Next steps:
  1. Restart Windows Terminal
  2. Run: . `$PROFILE
  3. Set git identity: git config --global user.name / user.email
  4. Review C:\Security\Alfa-Adapter-Guidelines.md
  5. Read C:\Scripts\Workstation\README.md

'@ -ForegroundColor Cyan
