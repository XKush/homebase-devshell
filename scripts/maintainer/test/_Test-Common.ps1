# Shared helpers for maintainer smoke tests.
# Dot-source: . (Join-Path $PSScriptRoot '_Test-Common.ps1')

function Get-TestWorkstationRoot {
    param([string]$Start = $PSScriptRoot)
    . (Join-Path $PSScriptRoot '..\_Resolve-RepoRoot.ps1')
    return Resolve-WorkstationRepoRoot -Start $Start
}

function Get-TestProductVersion {
    param([Parameter(Mandatory)][string]$Root)
    . (Join-Path $Root 'lib\DevShellProduct.ps1')
    return Get-DevShellProductVersionFromRoot -RepoRoot $Root
}

function Invoke-TestHealthJson {
    param(
        [Parameter(Mandatory)][string]$Root,
        [string[]]$SectionFilter,
        [switch]$SkipHistory
    )
    $invoke = Join-Path $Root 'scripts\maintainer\invoke\Invoke-DevShellHealth.ps1'
    $args = @{ Json = $true; Tier = 'Core' }
    if ($SectionFilter) { $args['SectionFilter'] = $SectionFilter }
    if ($SkipHistory) { $args['SkipHistory'] = $true }
    $out = pwsh -NoProfile -File $invoke @args 2>&1 | Out-String
    if ($out -notmatch 'healthSchemaVersion') {
        throw 'health -Json missing healthSchemaVersion'
    }
    try {
        return $out.Trim() | ConvertFrom-Json
    } catch {
        throw "health -Json invalid JSON: $_"
    }
}
