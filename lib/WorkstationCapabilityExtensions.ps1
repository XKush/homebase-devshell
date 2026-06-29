# Wave D — capability extensions (plugin boundary — no core control)
# lib/WorkstationCapabilityExtensions.ps1
#
# Prerequisite: Wave A–C core layers loaded separately
# Does not execute extensions, route commands, emit events, or mutate core state.

$script:WorkstationExtensions = @{}

function Register-WorkstationExtension {
    <#
    .SYNOPSIS
        Registers a side-capability extension in the extension registry (not the command registry).
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][string]$Version,
        [Parameter(Mandatory)][string]$Capability,
        [Parameter(Mandatory)][scriptblock]$EntryPoint,
        [string[]]$Dependencies = @()
    )

    if ($script:WorkstationExtensions.ContainsKey($Name)) {
        throw "Extension already registered: $Name"
    }

    $definition = [ordered]@{
        Name         = $Name
        Version      = $Version
        Capability   = $Capability
        EntryPoint   = $EntryPoint
        Dependencies = @($Dependencies | ForEach-Object { [string]$_ })
    }

    $script:WorkstationExtensions[$Name] = $definition
    return $definition
}

function Get-WorkstationExtension {
    param([Parameter(Mandatory)][string]$Name)

    if (-not $script:WorkstationExtensions.ContainsKey($Name)) { return $null }
    return $script:WorkstationExtensions[$Name]
}

function Get-WorkstationExtensionsByCapability {
    param([Parameter(Mandatory)][string]$Capability)

    $matches = [System.Collections.Generic.List[object]]::new()
    foreach ($name in ($script:WorkstationExtensions.Keys | Sort-Object)) {
        $ext = $script:WorkstationExtensions[$name]
        if ([string]$ext.Capability -eq $Capability) {
            $matches.Add($ext)
        }
    }
    return ,[object[]]@($matches)
}
