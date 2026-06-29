#Requires -Version 7.0
# One-time OSS clean release — move all root scripts to scripts/maintainer/, remove root shims.
$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
Set-Location $repoRoot

$keepRoot = @('install.ps1', 'devshell.ps1')

$install = @(
    'Install-Workstation.ps1', 'Validate-Workstation.ps1', 'Install-ShellProfile.ps1',
    'Install-Software.ps1', 'Install-NetworkToolkit.ps1', 'Install-PgpToolkit.ps1', 'Install-TorBrowser.ps1'
)
$invokeExtra = @(
    'Backup-Configuration.ps1', 'Generate-HomeBaseCheatsheet.ps1', 'Register-MaintenanceTask.ps1',
    'Register-WorkstationTasks.ps1', 'Rollback-Workstation.ps1', 'Save-ProfileSnapshot.ps1',
    'Sync-WorkstationDocs.ps1', 'Repair-WorkstationAll.ps1'
)
$configureExtra = @(
    'Enable-SystemRestore.ps1', 'Fix-WorkstationPath.ps1', 'Harden-Security.ps1',
    'Optimize-Performance.ps1', 'Optimize-Profile.ps1', 'Repair-PgpIdentity.ps1', 'Repair-WorkstationFonts.ps1'
)
$shimOnly = @(
    'Invoke-AcceptanceTest.ps1', 'Invoke-CommandCenterAudit.ps1', 'Invoke-CommandCenterCI.ps1',
    'Invoke-EnhancementPass.ps1', 'Invoke-EnhancementReports.ps1', 'Invoke-FinalAudit.ps1',
    'Invoke-HomeBaseUpgrade.ps1', 'Invoke-Housekeeping.ps1', 'Invoke-Maintenance.ps1',
    'Invoke-MaxLevelPass.ps1', 'Invoke-OrganizationAudit.ps1', 'Invoke-PostProductionAudit.ps1',
    'Invoke-PostProductionValidation.ps1', 'Invoke-ScheduledTrustProbe.ps1', 'Invoke-SystemDiscovery.ps1',
    'Invoke-TerminalAudit.ps1', 'Invoke-TerminalRecovery.ps1', 'Invoke-WindowsTunePass.ps1',
    'Invoke-WorkstationOrganization.ps1', 'Invoke-WorkstationRevision.ps1',
    'Configure-GitIdentity.ps1', 'Configure-Network.ps1', 'Configure-PgpIdentity.ps1',
    'Configure-Privacy.ps1', 'Configure-TorSecurity.ps1',
    'Test-HomeBasePaths.ps1', 'Test-LegacyEquivalence.ps1', 'Test-ReleaseVersion.ps1',
    'Test-RestoreRehearsal.ps1', 'Test-WorkstationCommands.ps1', 'Test-WorkstationPlatformHardening.ps1',
    'Invoke-Phase2CommitGate.ps1', 'Invoke-Phase2IntegrationRehearsal.ps1', 'Invoke-Phase2Step1Baseline.ps1',
    'Save-Phase2Baseline.ps1', 'Save-PhaseBaseline.ps1', 'Get-Phase2LegacyPathReport.ps1'
)

New-Item -ItemType Directory -Force -Path scripts/maintainer/install | Out-Null

function Move-IfRoot {
    param([string]$Name, [string]$Folder)
    $src = Join-Path $repoRoot $Name
    $dest = Join-Path $repoRoot "scripts\maintainer\$Folder\$Name"
    if (-not (Test-Path $src)) { Write-Host "Skip missing: $Name"; return }
    if (Test-Path $dest) {
        Write-Host "Canonical exists, remove root: $Name"
        git rm -f $Name 2>$null
        if ($LASTEXITCODE -ne 0) { Remove-Item -Force $src -ErrorAction SilentlyContinue }
        return
    }
    git mv $Name "scripts/maintainer/$Folder/$Name"
    Write-Host "Moved $Name -> scripts/maintainer/$Folder/"
}

foreach ($n in $install) { Move-IfRoot $n 'install' }
foreach ($n in $invokeExtra) { Move-IfRoot $n 'invoke' }
foreach ($n in $configureExtra) { Move-IfRoot $n 'configure' }
foreach ($n in $shimOnly) {
    $src = Join-Path $repoRoot $n
    if (Test-Path $src) {
        Write-Host "Remove shim: $n"
        git rm -f $n 2>$null
        if ($LASTEXITCODE -ne 0) { Remove-Item -Force $src -ErrorAction SilentlyContinue }
    }
}

Write-Host ''
Write-Host 'Root .ps1 remaining:' -ForegroundColor Cyan
Get-ChildItem -File -Filter '*.ps1' | ForEach-Object { $_.Name }
