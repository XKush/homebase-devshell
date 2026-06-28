#Requires -Version 7.0
<#
.SYNOPSIS
    Full command center architectural audit — inventory, validation, reports.
#>
param(
    [switch]$Repair,
    [switch]$SkipExecute
)

$wsRoot = 'C:\Scripts\Workstation'
$reportDir = 'C:\Logs\Workstation'
$ts = Get-Date -Format 'yyyyMMdd-HHmmss'

if (-not (Test-Path $reportDir)) { New-Item -ItemType Directory -Force -Path $reportDir | Out-Null }

Write-Host "`n╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  COMMAND CENTER ARCHITECTURE AUDIT — KGreen                  ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan

# Phase 1 — ensure module loaded
$modulePath = Join-Path $wsRoot 'modules\KGreen.Workstation.psm1'
if (-not (Test-Path $modulePath)) {
    Write-Host "ERROR: Module missing at $modulePath" -ForegroundColor Red
    exit 1
}

Import-Module $modulePath -DisableNameChecking -Force
$registry = Get-WorkstationCommandRegistry

Write-Host "PHASE 1 — Command Inventory" -ForegroundColor Yellow
$inventory = Get-WorkstationCommandHealth
$inventory | Format-Table Name, Backend, Module, Exists, BackendExists, Loads, Help, Status -AutoSize
$invPath = Join-Path $reportDir "command-inventory-$ts.json"
$inventory | ConvertTo-Json -Depth 4 | Set-Content $invPath -Encoding UTF8
Write-Host "  Saved: $invPath`n" -ForegroundColor DarkGray

# Phase 2 — validation
Write-Host "PHASE 2 — Safe Validation" -ForegroundColor Yellow
$testArgs = @{}
if ($SkipExecute) { $testArgs.ReportOnly = $true }
& (Join-Path $wsRoot 'Test-WorkstationCommands.ps1') @testArgs
$testExit = $LASTEXITCODE
$healthPath = Join-Path $reportDir 'command-health.json'
$health = if (Test-Path $healthPath) { Get-Content $healthPath -Raw | ConvertFrom-Json } else { $null }

# Phase 3 — self-heal
if ($Repair -and $health -and ($health.Broken -gt 0 -or $health.ExecuteFailures -gt 0)) {
    Write-Host "`nPHASE 3 — Self-Heal" -ForegroundColor Yellow
    & (Join-Path $wsRoot 'Install-ShellProfile.ps1') -Force -ErrorAction SilentlyContinue
    Import-Module $modulePath -DisableNameChecking -Force
    & (Join-Path $wsRoot 'Test-WorkstationCommands.ps1')
    $health = Get-Content $healthPath -Raw | ConvertFrom-Json
}

# Phase 4/5 — architecture report
Write-Host "`nPHASE 4/5 — Architecture" -ForegroundColor Yellow
$arch = [ordered]@{
    Timestamp = (Get-Date).ToString('o')
    Profile   = 'C:\Scripts\Workstation\profile\Microsoft.PowerShell_profile.ps1'
    Module    = $modulePath
    Components = @(
        'Private/Common.ps1 — logging, registry, Invoke-WorkstationCmd'
        'Shell.ps1 — navigation, git, python, sysinfo'
        'Diagnostics.ps1 — doctor, healthcheck, sysreport'
        'Network.ps1 — nettools, toolcheck, toolbox, sysaudit'
        'Maintenance.ps1 — cleanup, backupconfig, updateall'
        'Learning.ps1 — help, learn, cheatsheet, quickstart'
        'Recovery.ps1 — repairterminal, restoreconfig, reloadprofile'
        'Workspace.ps1 — workspace, devstart, logs, securitycheck'
        'Dashboard.ps1 — jarvis, WOC integration'
    )
    DependencyGraph = @{
        Profile = @('KGreen.Workstation.psm1')
        KGreen_Workstation = @('Common', 'Shell', 'Diagnostics', 'Network', 'Maintenance', 'Learning', 'Recovery', 'Workspace', 'Dashboard')
        Dashboard = @('lib\WorkstationOperationsCenter.ps1')
        Diagnostics = @('Validate-Workstation.ps1', 'Invoke-SystemDiscovery.ps1')
        Network = @('Install-NetworkToolkit.ps1', 'Invoke-OrganizationAudit.ps1')
        Recovery = @('Invoke-TerminalRecovery.ps1', 'Rollback-Workstation.ps1', 'Install-ShellProfile.ps1')
    }
    RootCauseFixed = 'Lazy dot-source inside Ensure-WorkstationToolkit loaded backends in local scope — all backends now in module script scope'
}
$archPath = Join-Path $reportDir "architecture-report-$ts.json"
$arch | ConvertTo-Json -Depth 5 | Set-Content $archPath -Encoding UTF8
Write-Host "  Saved: $archPath`n" -ForegroundColor DarkGray

# Phase 8 — final acceptance
Write-Host "PHASE 8 — Final Acceptance" -ForegroundColor Yellow
$broken = @($inventory | Where-Object { -not $_.Loads })
$accept = [ordered]@{
    Timestamp = (Get-Date).ToString('o')
    AllCommandsExist = ($broken.Count -eq 0)
    AllExecute = if ($health) { $health.ExecuteFailures -eq 0 } else { $false }
    ModulePresent = (Test-Path $modulePath)
    TestFramework = (Test-Path (Join-Path $wsRoot 'Test-WorkstationCommands.ps1'))
    BrokenCommands = @($broken | ForEach-Object { $_.Name })
    HealthReport = $healthPath
    InventoryReport = $invPath
    ArchitectureReport = $archPath
    Accepted = ($broken.Count -eq 0) -and ($testExit -eq 0)
}
$acceptPath = Join-Path $reportDir "final-validation-$ts.json"
$accept | ConvertTo-Json -Depth 5 | Set-Content $acceptPath -Encoding UTF8

Write-Host "  Inventory:     $invPath"
Write-Host "  Health:        $healthPath"
Write-Host "  Architecture:  $archPath"
Write-Host "  Final:         $acceptPath"
Write-Host ""
if ($accept.Accepted) {
    Write-Host "  ACCEPTED — Command center operational." -ForegroundColor Green
    exit 0
} else {
    Write-Host "  NOT ACCEPTED — $($broken.Count) broken, review reports." -ForegroundColor Red
    exit 1
}
