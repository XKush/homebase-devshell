# Wave B — profile orchestration layer (coordination only, no system mutation)
# lib/WorkstationOrchestrator.ps1
#
# Prerequisite (script-scope dot-source, e.g. profile bootstrap):
#   C1 HomeBasePaths → C2 WorkstationCommon → C4 ProfileEnvironment
# This file does not dot-source or Import-Module those layers itself.

function New-WorkstationExecutionContext {
    [ordered]@{
        Bootstrap   = 'Pending'
        Environment = 'Pending'
        Diagnostics = 'Pending'
        Hints       = 'Pending'
        Timestamp   = Get-Date
    }
}

function Resolve-WorkstationOrchestratorRoot {
    param([string]$RepositoryRoot)
    if ($RepositoryRoot) { return $RepositoryRoot }
    if ($script:WSRoot) { return $script:WSRoot }
    if ($env:WORKSTATION_ROOT) { return $env:WORKSTATION_ROOT }
    if (Get-Command Get-WorkstationRepositoryRoot -ErrorAction SilentlyContinue) {
        return Get-WorkstationRepositoryRoot
    }
    if (Get-Command Get-HomeBasePath -ErrorAction SilentlyContinue) {
        return Get-HomeBasePath -Name RepositoryRoot
    }
    return 'C:\Scripts\Workstation'
}

function Test-WorkstationPathSsotLayer {
    try {
        if (-not (Get-Command Get-HomeBasePath -ErrorAction SilentlyContinue)) {
            return $false
        }
        $null = Get-HomeBasePath -Name RepositoryRoot
        return $true
    } catch {
        Write-Verbose "Path SSOT check failed: $($_.Exception.Message)"
        return $false
    }
}

function Invoke-WorkstationModuleBootstrapLayer {
    param([string]$Root)
    if (-not (Get-Command Import-WorkstationProfileModule -ErrorAction SilentlyContinue)) {
        return $false
    }
    return [bool](Import-WorkstationProfileModule -Root $Root)
}

function Invoke-WorkstationEnvironmentLayer {
    if (-not (Get-Command Initialize-WorkstationProfileEnvironment -ErrorAction SilentlyContinue)) {
        return $false
    }
    Initialize-WorkstationProfileEnvironment | Out-Null
    return [bool]$env:WORKSTATION_ROOT -and [bool]($script:WorkstationRoots ?? $global:WorkstationRoots)
}

function Get-WorkstationDiagnosticsLayerStatus {
    param([string]$Root)

    if (-not (Get-Module KGreen.Workstation)) {
        return 'Unavailable'
    }

    foreach ($cmd in @('doctor', 'Get-SystemTrustReport', 'healthcheck')) {
        if (-not (Get-Command $cmd -ErrorAction SilentlyContinue)) {
            return 'ERROR'
        }
    }

    $status = 'OK'
    $canon = Join-Path $Root 'profile\Microsoft.PowerShell_profile.ps1'
    $live  = Join-Path $env:USERPROFILE 'Documents\PowerShell\Microsoft.PowerShell_profile.ps1'
    if ((Test-Path $canon) -and (Test-Path $live)) {
        if ((Get-FileHash $canon).Hash -ne (Get-FileHash $live).Hash) {
            $status = 'WARNING'
        }
    }

    return $status
}

function Get-WorkstationHintsLayerStatus {
    param([string]$Root)

    if (Get-Command Get-WorkstationHelpCatalog -ErrorAction SilentlyContinue) {
        try {
            $null = Get-WorkstationHelpCatalog
            return 'Loaded'
        } catch {
            return 'Unavailable'
        }
    }

    $hintsPath = Join-Path $Root 'modules\locale\ru\Hints.ru.ps1'
    $helpPath  = Join-Path $Root 'modules\Private\Help.ru.ps1'
    if ((Test-Path $hintsPath) -and (Test-Path $helpPath)) {
        return 'Available'
    }

    return 'Unavailable'
}

function Invoke-WorkstationProfile {
    <#
    .SYNOPSIS
        Coordinates profile layer startup in fixed order: C1 → C2 → C4 → C5 → C3 (passive).
        Aggregates execution context only; does not repair, install, or mutate diagnostics output.
    .OUTPUTS
        Execution context hashtable (also stored in $global:WorkstationExecutionContext).
    #>
    [CmdletBinding()]
    param(
        [string]$RepositoryRoot,
        [switch]$Force
    )

    if (-not $Force -and $global:WorkstationExecutionContext -and $script:WorkstationProfileOrchestrated) {
        return $global:WorkstationExecutionContext
    }

    $root = Resolve-WorkstationOrchestratorRoot -RepositoryRoot $RepositoryRoot

    if (Get-Command New-WorkstationLifecycleEvent -ErrorAction SilentlyContinue) {
        New-WorkstationLifecycleEvent -Layer Orchestrator -Family profile.init -Phase start -Target $root | Out-Null
    }

    $ctx  = New-WorkstationExecutionContext

    # C1 — Path SSOT (read-only verify)
    $ssotOk = Test-WorkstationPathSsotLayer

    # C2 — Module bootstrap via SSOT entry point (Import-WorkstationProfileModule)
    $moduleOk = $false
    if ($ssotOk) {
        $moduleOk = Invoke-WorkstationModuleBootstrapLayer -Root $root
    }
    $ctx.Bootstrap = if ($ssotOk -and $moduleOk) { 'OK' } elseif ($ssotOk) { 'WARNING' } else { 'ERROR' }

    # C4 — Environment state (declarative layer; idempotent init)
    $envOk = $false
    if ($ssotOk) {
        $envOk = Invoke-WorkstationEnvironmentLayer
    }
    $ctx.Environment = if ($envOk) { 'OK' } else { 'ERROR' }

    # C5 — Diagnostics (read-only truth layer)
    $ctx.Diagnostics = if ($moduleOk) {
        Get-WorkstationDiagnosticsLayerStatus -Root $root
    } else {
        'Unavailable'
    }

    # C3 — Hints (passive availability; no content logic)
    $ctx.Hints = Get-WorkstationHintsLayerStatus -Root $root
    $ctx.Timestamp = Get-Date

    $script:WorkstationProfileOrchestrated = $true
    $global:WorkstationExecutionContext = $ctx

    if (Get-Command New-WorkstationLifecycleEvent -ErrorAction SilentlyContinue) {
        $lifecyclePhase = if ($ctx.Bootstrap -eq 'ERROR' -or $ctx.Environment -eq 'ERROR') { 'fail' } else { 'success' }
        New-WorkstationLifecycleEvent -Layer Orchestrator -Family profile.init -Phase $lifecyclePhase -Target $root | Out-Null
    }

    return $ctx
}

function Get-WorkstationExecutionContext {
    if ($global:WorkstationExecutionContext) {
        return $global:WorkstationExecutionContext
    }
    return New-WorkstationExecutionContext
}
