#Requires -Version 7.0
<#
.SYNOPSIS
    HomeBase DevShell — prepares, verifies and maintains professional Windows workstations.
#>
[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [ValidateSet('health', 'history', 'baseline', 'verify', 'install', 'doctor', 'status', 'reload', 'trace', 'help', 'version', 'init',
        'privacy', 'browser', 'tor', 'vpn', 'metadata', 'clean-meta', 'opsec', 'audit')]
    [string]$Command = 'help',
    [Parameter(Position = 1)]
    [string]$Argument,
    [ValidateSet('Core', 'Full')]
    [string]$Tier = 'Core',
    [switch]$SkipTools,
    [switch]$WithTools,
    [switch]$Fix,
    [switch]$Privacy,
    [switch]$Apply,
    [switch]$Strip,
    [switch]$Json,
    [ValidateSet('html')]
    [string]$Export,
    [string[]]$Sections,
    [ValidateSet('Chrome', 'Edge', 'Firefox', 'All')]
    [string]$Browser = 'All',
    [int]$Last = 20
)

$ErrorActionPreference = 'Stop'

function Get-DevShellRepoRoot {
    if ($env:HOMEBASE_DEVSHELL_ROOT -and (Test-Path (Join-Path $env:HOMEBASE_DEVSHELL_ROOT 'lib\HomeBasePaths.ps1'))) {
        return $env:HOMEBASE_DEVSHELL_ROOT
    }
    if (-not [string]::IsNullOrWhiteSpace($PSScriptRoot) -and (Test-Path (Join-Path $PSScriptRoot 'lib\HomeBasePaths.ps1'))) {
        return $PSScriptRoot
    }
    $ossDefault = Join-Path $env:USERPROFILE '.homebase\devshell'
    if (Test-Path (Join-Path $ossDefault 'lib\HomeBasePaths.ps1')) { return $ossDefault }
    throw 'HomeBase DevShell root not found. Set `$env:HOMEBASE_DEVSHELL_ROOT` or run from the repository.'
}

function Get-DevShellProductVersion {
    param([string]$Root)
    $psd1 = Join-Path $Root 'modules\KGreen.Workstation.psd1'
    if (Test-Path $psd1) { return [string](Import-PowerShellDataFile $psd1).ModuleVersion }
    return '3.0.0'
}

function Show-DevShellHelp {
    Write-Host @'

HomeBase DevShell — workstation readiness & privacy auditing

  devshell health      Unified dashboard (developer + privacy + browser + network)
  devshell health -Json          Machine-readable report
  devshell health -Sections developer,privacy   Subset of sections (faster)
  devshell health -Export html   HTML report in Logs folder
  devshell history     Privacy/configuration score trend
  devshell baseline    Save configuration baseline
  devshell verify      Compare current state to baseline

  devready / devshell doctor     Developer readiness (-Tier Core|Full, -Fix, -Json)
  devshell install     First-time setup (Core; -WithTools for winget stack)
  devshell init        Dry-run install plan

  Advanced (frozen API — see docs/API-STABILITY.md):
  devshell privacy | browser | vpn | tor | metadata | clean-meta

  devshell help

'@ -ForegroundColor DarkGray
}

$repoRoot = Get-DevShellRepoRoot

if ($Command -in @('status', 'reload', 'trace', 'version')) {
    . (Join-Path $repoRoot 'lib\HomeBasePaths.ps1')
    . (Join-Path $repoRoot 'lib\WorkstationCommon.ps1')
    . (Join-Path $repoRoot 'lib\ProfileEnvironment.ps1')
    . (Join-Path $repoRoot 'lib\WorkstationOrchestrator.ps1')
    . (Join-Path $repoRoot 'lib\WorkstationCommandRegistry.ps1')
    . (Join-Path $repoRoot 'lib\WorkstationCapabilityObservability.ps1')
    . (Join-Path $repoRoot 'lib\WorkstationEventCore.ps1')
    . (Join-Path $repoRoot 'lib\WorkstationPlatformContract.ps1')
    . (Join-Path $repoRoot 'lib\WorkstationExecutionTrace.ps1')
    . (Join-Path $repoRoot 'lib\WorkstationCommandRouter.ps1')
    . (Join-Path $repoRoot 'lib\WorkstationCapabilityExtensions.ps1')
    . (Join-Path $repoRoot 'lib\WorkstationExtensionEventBridge.ps1')
    . (Join-Path $repoRoot 'lib\WorkstationExtensionRuntime.ps1')
}

switch ($Command) {
    'health' {
        $healthArgs = @{ Tier = $Tier }
        if ($Json) { $healthArgs['Json'] = $true }
        if ($Export) { $healthArgs['Export'] = $Export }
        if ($Sections) { $healthArgs['SectionFilter'] = $Sections }
        if ($Argument) { $healthArgs['OutFile'] = $Argument }
        & (Join-Path $repoRoot 'scripts\maintainer\invoke\Invoke-DevShellHealth.ps1') @healthArgs
        exit $LASTEXITCODE
    }
    'history' {
        & (Join-Path $repoRoot 'scripts\maintainer\invoke\Invoke-DevShellHistory.ps1') -Last $Last
        exit $LASTEXITCODE
    }
    'baseline' {
        & (Join-Path $repoRoot 'scripts\maintainer\invoke\Invoke-DevShellBaseline.ps1')
        exit $LASTEXITCODE
    }
    'verify' {
        $verifyArgs = @{}
        if ($Json) { $verifyArgs['Json'] = $true }
        & (Join-Path $repoRoot 'scripts\maintainer\invoke\Invoke-DevShellVerify.ps1') @verifyArgs
        exit $LASTEXITCODE
    }
    'install' {
        if ($WithTools) {
            & (Join-Path $repoRoot 'scripts\maintainer\install\Install-Workstation.ps1') -Force -SkipAdmin -SkipValidation
        } else {
            & (Join-Path $repoRoot 'scripts\maintainer\install\Install-Workstation.ps1') -Force -SkipSoftware -SkipAdmin -SkipValidation
        }
        if ($LASTEXITCODE -and $LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    }
    'doctor' {
        $doctorArgs = @{
            Tier             = $Tier
            StartupBudgetMs  = 650
        }
        if ($Fix) { $doctorArgs['Fix'] = $true }
        if ($Privacy) { $doctorArgs['Privacy'] = $true }
        if ($Json) { $doctorArgs['JsonOnly'] = $true }
        & (Join-Path $repoRoot 'scripts\maintainer\install\Validate-Workstation.ps1') @doctorArgs
        exit $LASTEXITCODE
    }
    'init' {
        $planScript = Join-Path $repoRoot 'scripts\maintainer\install\Show-DevShellInitPlan.ps1'
        $planArgs = @{}
        if ($WithTools) { $planArgs['WithTools'] = $true }
        elseif ($SkipTools) { $planArgs['SkipTools'] = $true }
        else { $planArgs['SkipTools'] = $true }
        & $planScript @planArgs
        exit 0
    }
    'privacy' {
        $privacyArgs = @{}
        if ($Fix) { $privacyArgs['Fix'] = $true }
        if ($Apply) { $privacyArgs['Apply'] = $true }
        if ($Json) { $privacyArgs['Json'] = $true }
        & (Join-Path $repoRoot 'scripts\maintainer\invoke\Invoke-PrivacyAudit.ps1') @privacyArgs
        exit $LASTEXITCODE
    }
    'audit' {
        $target = if ($Argument) { $Argument } else { 'privacy' }
        if ($target -eq 'privacy') {
            $privacyArgs = @{}
            if ($Fix) { $privacyArgs['Fix'] = $true }
            if ($Apply) { $privacyArgs['Apply'] = $true }
            if ($Json) { $privacyArgs['Json'] = $true }
            & (Join-Path $repoRoot 'scripts\maintainer\invoke\Invoke-PrivacyAudit.ps1') @privacyArgs
            exit $LASTEXITCODE
        }
        Write-Host "Unknown audit: $target" -ForegroundColor Yellow
        exit 1
    }
    'browser' {
        $bArgs = @{ Browser = $Browser }
        if ($Json) { $bArgs['Json'] = $true }
        & (Join-Path $repoRoot 'scripts\maintainer\invoke\Invoke-BrowserPrivacyAudit.ps1') @bArgs
        exit $LASTEXITCODE
    }
    'tor' {
        $tArgs = @{}
        if ($Json) { $tArgs['Json'] = $true }
        & (Join-Path $repoRoot 'scripts\maintainer\invoke\Invoke-TorReadinessAudit.ps1') @tArgs
        exit $LASTEXITCODE
    }
    'vpn' {
        $vArgs = @{}
        if ($Json) { $vArgs['Json'] = $true }
        & (Join-Path $repoRoot 'scripts\maintainer\invoke\Invoke-VpnAudit.ps1') @vArgs
        exit $LASTEXITCODE
    }
    'clean-meta' {
        if (-not $Argument) {
            Write-Host 'Usage: devshell clean-meta <file>' -ForegroundColor Yellow
            exit 1
        }
        & (Join-Path $repoRoot 'scripts\maintainer\invoke\Invoke-MetadataToolkit.ps1') -Path $Argument -Strip
        exit $LASTEXITCODE
    }
    'metadata' {
        $metaArgs = @{}
        if ($Argument) { $metaArgs['Path'] = $Argument }
        if ($Strip) { $metaArgs['Strip'] = $true }
        & (Join-Path $repoRoot 'scripts\maintainer\invoke\Invoke-MetadataToolkit.ps1') @metaArgs
        exit $LASTEXITCODE
    }
    'opsec' {
        $oArgs = @{}
        if ($Json) { $oArgs['Json'] = $true }
        & (Join-Path $repoRoot 'scripts\maintainer\invoke\Invoke-OpsecCheck.ps1') @oArgs
        exit $LASTEXITCODE
    }
    'status' {
        Invoke-WorkstationProfile -RepositoryRoot $repoRoot -Force | Out-Null
        $contract = Get-WorkstationPlatformContract
        $ctx = Get-WorkstationExecutionContext
        $product = Get-DevShellProductVersion -Root $repoRoot

        Write-Host ''
        Write-Host 'HomeBase DevShell' -ForegroundColor Cyan
        Write-Host "  Product:  $product"
        Write-Host "  Platform: $($contract.ContractVersion) ($($contract.Lock.Status))"
        Write-Host "  Signed:   $($contract.Lock.SignedAt)"
        Write-Host ''
        Write-Host 'Runtime' -ForegroundColor Cyan
        Write-Host "  Bootstrap:   $($ctx.Bootstrap)"
        Write-Host "  Environment: $($ctx.Environment)"
        Write-Host "  Diagnostics: $($ctx.Diagnostics)"
        Write-Host "  Hints:       $($ctx.Hints)"
        Write-Host ''
    }
    'reload' {
        Invoke-WorkstationProfile -RepositoryRoot $repoRoot -Force | Out-Null
        $null = Invoke-WorkstationCommand -Name 'profile.reload'
        Write-Host 'Profile stack reloaded.' -ForegroundColor Green
    }
    'trace' {
        Invoke-WorkstationProfile -RepositoryRoot $repoRoot -Force | Out-Null
        $trace = Get-WorkstationExecutionTrace
        if ($trace -is [System.Array] -and $trace.Count -eq 1 -and $trace[0] -is [System.Array]) {
            $trace = $trace[0]
        }
        if (-not $trace -or $trace.Count -eq 0) {
            Write-Host 'No execution trace events recorded in this session.' -ForegroundColor DarkGray
            break
        }
        $rows = if ($trace.Count -gt $Last) { $trace[($trace.Count - $Last)..($trace.Count - 1)] } else { $trace }
        $rows | ForEach-Object { [PSCustomObject]$_ } | Format-Table Command, Layer, Capability, Status -AutoSize
    }
    'version' {
        $contract = Get-WorkstationPlatformContract
        $product = Get-DevShellProductVersion -Root $repoRoot
        Write-Output "HomeBase DevShell $product · Platform Spec $($contract.ContractVersion) ($($contract.Lock.Status))"
    }
    default { Show-DevShellHelp }
}
