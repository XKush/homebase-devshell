# HOME BASE path configuration — Phase 2
# C:\Scripts\Workstation\lib\HomeBasePaths.ps1

$script:HomeBaseConfigCache = $null

function Get-HomeBaseRepositoryRoot {
    if ($script:WSRoot -and (Test-Path (Join-Path $script:WSRoot 'lib\HomeBasePaths.ps1'))) {
        return $script:WSRoot.TrimEnd('\')
    }
    foreach ($envName in @('WORKSTATION_ROOT', 'HOMEBASE_DEVSHELL_ROOT')) {
        $value = [Environment]::GetEnvironmentVariable($envName)
        if ($value -and (Test-Path (Join-Path $value 'lib\HomeBasePaths.ps1'))) {
            return $value.TrimEnd('\')
        }
    }
    $libParent = Split-Path $PSScriptRoot -Parent
    if (Test-Path (Join-Path $libParent 'lib\HomeBasePaths.ps1')) {
        return (Resolve-Path $libParent).Path.TrimEnd('\')
    }
    $ossDefault = Join-Path $env:USERPROFILE '.homebase\devshell'
    if (Test-Path (Join-Path $ossDefault 'lib\HomeBasePaths.ps1')) {
        return $ossDefault.TrimEnd('\')
    }
    throw 'HomeBase repository root not found. Set WORKSTATION_ROOT or run install.ps1.'
}

function Get-HomeBaseConfigPath {
    if ($env:HOMEBASE_CONFIG -and (Test-Path $env:HOMEBASE_CONFIG)) {
        return $env:HOMEBASE_CONFIG
    }
    $root = Get-HomeBaseRepositoryRoot
    return Join-Path $root 'Config\homebase.defaults.json'
}

function Expand-HomeBasePathTemplate {
    param(
        [string]$Value,
        [hashtable]$Tokens
    )
    if ([string]::IsNullOrWhiteSpace($Value)) { return $Value }
    $result = $Value
    foreach ($key in $Tokens.Keys) {
        $result = $result -replace [regex]::Escape("{$key}"), [string]$Tokens[$key]
    }
    return $result
}

function Get-HomeBaseConfig {
    if ($script:HomeBaseConfigCache) { return $script:HomeBaseConfigCache }

    $path = Get-HomeBaseConfigPath
    if (-not (Test-Path $path)) {
        throw "HOME BASE config not found: $path"
    }

    $script:HomeBaseConfigCache = Get-Content -Path $path -Raw | ConvertFrom-Json
    return $script:HomeBaseConfigCache
}

function Reset-HomeBaseConfigCache {
    $script:HomeBaseConfigCache = $null
}

function Get-HomeBasePath {
    <#
    .SYNOPSIS
        Single accessor for HOME BASE runtime paths.
    .PARAMETER Name
        Logs, Backups, Configs, Projects, Tools, Scripts, Security, Networking, Temp, RepositoryRoot, RuntimeRoot
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet(
            'Logs', 'Backups', 'Configs', 'Projects', 'Tools', 'Scripts',
            'Security', 'Networking', 'Temp', 'RepositoryRoot', 'RuntimeRoot'
        )]
        [string]$Name
    )

    $cfg = Get-HomeBaseConfig
    $runtimeRoot = if ($env:HOMEBASE_RUNTIME) { $env:HOMEBASE_RUNTIME.TrimEnd('\') } else { $cfg.RuntimeRoot.TrimEnd('\') }
    $configuredRepo = Expand-HomeBasePathTemplate -Value ([string]$cfg.RepositoryRoot) -Tokens @{ RuntimeRoot = $runtimeRoot }
    $repoRoot = if ([string]::IsNullOrWhiteSpace($configuredRepo)) {
        Get-HomeBaseRepositoryRoot
    } else {
        $configuredRepo.TrimEnd('\')
    }

    if ($Name -eq 'RuntimeRoot') { return $runtimeRoot }
    if ($Name -eq 'RepositoryRoot') { return $repoRoot }

    $prop = $cfg.Paths.PSObject.Properties[$Name]
    if (-not $prop) {
        throw "Unknown HOME BASE path name: $Name"
    }

    return Expand-HomeBasePathTemplate -Value ([string]$prop.Value) -Tokens @{
        RuntimeRoot     = $runtimeRoot
        RepositoryRoot    = $repoRoot
    }
}

function Get-HomeBaseLegacyJunctions {
    $cfg = Get-HomeBaseConfig
    if (-not $cfg.LegacyJunctions) { return @() }
    return @($cfg.LegacyJunctions)
}

function Test-HomeBasePathLayout {
    param([switch]$CreateMissing)

    $names = @('Logs', 'Backups', 'Configs', 'Projects', 'Tools', 'Scripts')
    $results = foreach ($n in $names) {
        $p = Get-HomeBasePath -Name $n
        $exists = Test-Path $p
        if (-not $exists -and $CreateMissing) {
            New-Item -ItemType Directory -Force -Path $p | Out-Null
            $exists = $true
        }
        [PSCustomObject]@{ Name = $n; Path = $p; Exists = $exists }
    }
    return @($results)
}
