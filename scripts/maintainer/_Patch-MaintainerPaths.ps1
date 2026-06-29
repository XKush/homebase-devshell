#Requires -Version 7.0
# Bulk-update $repoRoot script references after OSS root cleanup
$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path

$map = @{
    'Validate-Workstation.ps1' = 'install'
    'Install-Workstation.ps1' = 'install'
    'Install-ShellProfile.ps1' = 'install'
    'Install-Software.ps1' = 'install'
    'Install-NetworkToolkit.ps1' = 'install'
    'Install-PgpToolkit.ps1' = 'install'
    'Install-TorBrowser.ps1' = 'install'
    'Backup-Configuration.ps1' = 'invoke'
    'Generate-HomeBaseCheatsheet.ps1' = 'invoke'
    'Register-MaintenanceTask.ps1' = 'invoke'
    'Register-WorkstationTasks.ps1' = 'invoke'
    'Rollback-Workstation.ps1' = 'invoke'
    'Save-ProfileSnapshot.ps1' = 'invoke'
    'Sync-WorkstationDocs.ps1' = 'invoke'
    'Repair-WorkstationAll.ps1' = 'invoke'
    'Invoke-AcceptanceTest.ps1' = 'invoke'
    'Invoke-CommandCenterAudit.ps1' = 'invoke'
    'Invoke-CommandCenterCI.ps1' = 'invoke'
    'Invoke-EnhancementPass.ps1' = 'invoke'
    'Invoke-EnhancementReports.ps1' = 'invoke'
    'Invoke-FinalAudit.ps1' = 'invoke'
    'Invoke-HomeBaseUpgrade.ps1' = 'invoke'
    'Invoke-Housekeeping.ps1' = 'invoke'
    'Invoke-Maintenance.ps1' = 'invoke'
    'Invoke-MaxLevelPass.ps1' = 'invoke'
    'Invoke-OrganizationAudit.ps1' = 'invoke'
    'Invoke-PostProductionAudit.ps1' = 'invoke'
    'Invoke-PostProductionValidation.ps1' = 'invoke'
    'Invoke-ScheduledTrustProbe.ps1' = 'invoke'
    'Invoke-SystemDiscovery.ps1' = 'invoke'
    'Invoke-TerminalAudit.ps1' = 'invoke'
    'Invoke-TerminalRecovery.ps1' = 'invoke'
    'Invoke-WindowsTunePass.ps1' = 'invoke'
    'Invoke-WorkstationOrganization.ps1' = 'invoke'
    'Invoke-WorkstationRevision.ps1' = 'invoke'
    'Configure-GitIdentity.ps1' = 'configure'
    'Configure-Network.ps1' = 'configure'
    'Configure-PgpIdentity.ps1' = 'configure'
    'Configure-Privacy.ps1' = 'configure'
    'Configure-TorSecurity.ps1' = 'configure'
    'Enable-SystemRestore.ps1' = 'configure'
    'Fix-WorkstationPath.ps1' = 'configure'
    'Harden-Security.ps1' = 'configure'
    'Optimize-Performance.ps1' = 'configure'
    'Optimize-Profile.ps1' = 'configure'
    'Repair-PgpIdentity.ps1' = 'configure'
    'Repair-WorkstationFonts.ps1' = 'configure'
    'Test-HomeBasePaths.ps1' = 'test'
    'Test-LegacyEquivalence.ps1' = 'test'
    'Test-ReleaseVersion.ps1' = 'test'
    'Test-RestoreRehearsal.ps1' = 'test'
    'Test-WorkstationCommands.ps1' = 'test'
    'Test-WorkstationPlatformHardening.ps1' = 'test'
}

$files = @(
    Get-ChildItem (Join-Path $repoRoot 'scripts\maintainer') -Recurse -Filter '*.ps1'
    Get-ChildItem (Join-Path $repoRoot 'modules') -Recurse -Filter '*.ps1'
    Get-Item (Join-Path $repoRoot 'install.ps1'), (Join-Path $repoRoot 'devshell.ps1')
)

foreach ($file in $files | Select-Object -Unique) {
    if ($file.Name -like '_*') { continue }
    $text = Get-Content -LiteralPath $file.FullName -Raw
    $orig = $text
    foreach ($name in ($map.Keys | Sort-Object { $_.Length } -Descending)) {
        $folder = $map[$name]
        $target = "scripts\maintainer\$folder\$name"
        if ($text -match [regex]::Escape($target)) { continue }
        $text = $text -replace [regex]::Escape("`$repoRoot\$name"), "`$repoRoot\$target"
        $text = $text -replace [regex]::Escape("`$root\$name"), "`$root\$target"
        $text = $text -replace [regex]::Escape("Join-Path `$repoRoot '$name'"), "Join-Path `$repoRoot '$target'"
        $text = $text -replace [regex]::Escape("Join-Path `$script:WSRoot '$name'"), "Join-Path `$script:WSRoot '$target'"
        $text = $text -replace [regex]::Escape("Join-Path (`$script:WSRoot ?? 'C:\\Scripts\\Workstation') '$name'"), "Join-Path (`$script:WSRoot ?? 'C:\\Scripts\\Workstation') '$target'"
    }
    if ($text -ne $orig) {
        Set-Content -LiteralPath $file.FullName -Value $text -Encoding UTF8 -NoNewline
        Write-Host "Patched $($file.FullName.Replace($repoRoot, ''))"
    }
}
