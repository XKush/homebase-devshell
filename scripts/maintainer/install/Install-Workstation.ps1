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
    [switch]$SkipValidation,
    [ValidateSet('Core', 'Full')]
    [string]$ValidationTier = 'Full',
    [ValidateSet('Quad9', 'Cloudflare', 'Mullvad', 'None')]
    [string]$DnsProvider = 'Quad9'
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '..\_Resolve-RepoRoot.ps1')
$root = Resolve-WorkstationRepoRoot -Start $PSScriptRoot
. (Join-Path $root 'lib\WorkstationCommon.ps1')

Write-Host @'

 ╔══════════════════════════════════════════════════╗
 ║  DevReady — HomeBase DevShell Setup              ║
 ║  Privacy · Performance · Hardening (no Defender)   ║
 ╚══════════════════════════════════════════════════╝

'@ -ForegroundColor Green

Assert-DefenderUntouched

# 1. Folder structure
Write-WorkstationStep 'Folder structure'
$script:WSRoot = $root
. (Join-Path $root 'lib\HomeBasePaths.ps1')
$folderNames = @('Tools', 'Scripts', 'Projects', 'Logs', 'Backups', 'Security', 'Networking', 'Configs', 'Temp')
foreach ($name in $folderNames) {
    $path = Get-HomeBasePath -Name $name
    if (-not (Test-Path $path)) {
        New-Item -ItemType Directory -Force -Path $path | Out-Null
    }
}
foreach ($parent in @(
    (Split-Path (Get-HomeBasePath -Name Logs) -Parent),
    (Split-Path (Get-HomeBasePath -Name Backups) -Parent),
    (Split-Path (Get-HomeBasePath -Name Configs) -Parent),
    (Split-Path (Get-HomeBasePath -Name Temp) -Parent)
)) {
    if ($parent -and -not (Test-Path $parent)) {
        New-Item -ItemType Directory -Force -Path $parent | Out-Null
    }
}
Write-WorkstationLog 'Folders verified' 'OK'

# 2. Backup before changes
& (Resolve-WorkstationScript -Name 'Backup-Configuration.ps1' -Start $PSScriptRoot) -Force:$Force

# 3. Software
if (-not $SkipSoftware) {
    & (Resolve-WorkstationScript -Name 'Install-Software.ps1' -Start $PSScriptRoot) -Force:$Force
}

# 4. Shell profile (user scope)
& (Resolve-WorkstationScript -Name 'Install-ShellProfile.ps1' -Start $PSScriptRoot) -Force:$Force

# 5. Admin scripts
if (-not $SkipAdmin) {
    if (Test-WorkstationAdmin) {
        & (Resolve-WorkstationScript -Name 'Optimize-Performance.ps1' -Start $PSScriptRoot) -Force:$Force
        & (Resolve-WorkstationScript -Name 'Configure-Privacy.ps1' -Start $PSScriptRoot) -Force:$Force -DnsProvider $DnsProvider
        & (Resolve-WorkstationScript -Name 'Harden-Security.ps1' -Start $PSScriptRoot) -Force:$Force
        & (Resolve-WorkstationScript -Name 'Configure-Network.ps1' -Start $PSScriptRoot) -Force:$Force
    } else {
        $elevated = Resolve-WorkstationScript -Name 'Install-Workstation.ps1' -Start $PSScriptRoot
        Write-Host @"

Admin steps skipped — re-run elevated:
  Start-Process pwsh -Verb RunAs -ArgumentList '-File $elevated -Force -SkipSoftware'

Or run individually:
  Optimize-Performance.ps1
  Configure-Privacy.ps1
  Harden-Security.ps1
  Configure-Network.ps1

"@ -ForegroundColor Yellow
    }
} else {
    Write-WorkstationLog 'Admin scripts skipped (-SkipAdmin)' 'WARN'
}

Write-WorkstationStep 'Git identity defaults'
& (Resolve-WorkstationScript -Name 'Configure-GitIdentity.ps1' -Start $PSScriptRoot)

Write-WorkstationStep 'PATH repair'
& (Resolve-WorkstationScript -Name 'Fix-WorkstationPath.ps1' -Start $PSScriptRoot)

if (-not $SkipValidation) {
    $tier = if ($SkipSoftware) { 'Core' } else { $ValidationTier }
    Write-WorkstationStep "Final validation ($tier)"
    & (Resolve-WorkstationScript -Name 'Validate-Workstation.ps1' -Start $PSScriptRoot) -Tier $tier -StartupBudgetMs 650
    if ($LASTEXITCODE -ne 0) {
        Write-WorkstationLog 'Validation reported failures — review C:\Logs\Workstation\' 'ERROR'
        exit 1
    }
} else {
    Write-WorkstationLog 'Final validation skipped (-SkipValidation)' 'WARN'
}

Write-WorkstationStep 'Setup complete'
$readme = Join-Path $root 'README.md'
Write-Host @"
Next steps:
  1. Restart Windows Terminal
  2. Run: . `$PROFILE
  3. Set git identity: git config --global user.name / user.email
  4. Review C:\Security\Alfa-Adapter-Guidelines.md
  5. Read $readme

"@ -ForegroundColor Cyan
