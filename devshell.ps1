#Requires -Version 7.0
<#
.SYNOPSIS
    HomeBase DevShell — product CLI (thin wrapper over locked platform v1.0.0).
#>
[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [ValidateSet('install', 'doctor', 'status', 'reload', 'trace', 'help', 'version')]
    [string]$Command = 'help',
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
    $fallback = 'C:\Scripts\Workstation'
    if (Test-Path (Join-Path $fallback 'lib\HomeBasePaths.ps1')) { return $fallback }
    throw 'HomeBase DevShell root not found. Set `$env:HOMEBASE_DEVSHELL_ROOT` or run from the repository.'
}

function Get-DevShellProductVersion {
    param([string]$Root)
    $psd1 = Join-Path $Root 'modules\KGreen.Workstation.psd1'
    if (Test-Path $psd1) { return [string](Import-PowerShellDataFile $psd1).ModuleVersion }
    return '2.0.3'
}

function Show-DevShellHelp {
    Write-Host @'

HomeBase DevShell

  devshell install   Set up your shell
  devshell doctor    Check if you are ready to work
  devshell status    See if everything loaded

  devshell help      Show this help

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
    'install' {
        & (Join-Path $repoRoot 'scripts\maintainer\install\Install-Workstation.ps1') -Force -SkipSoftware -SkipAdmin
        if ($LASTEXITCODE -and $LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    }
    'doctor' {
        & (Join-Path $repoRoot 'scripts\maintainer\install\Validate-Workstation.ps1') -StartupBudgetMs 600
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
