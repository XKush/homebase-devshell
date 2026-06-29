# Wave B — command routing layer (dispatch only — definitions live in registry)
# lib/WorkstationCommandRouter.ps1
#
# Prerequisite: WorkstationCommandRegistry.ps1, WorkstationOrchestrator.ps1
# Does not interpret capabilities, filter commands, or mutate environment.

function Get-WorkstationCommandMap {
    $registry = Get-WorkstationCommandRegistry
    $map = @{}
    foreach ($name in $registry.Keys) {
        $map[$name] = $registry[$name].Handler
    }
    return $map
}

function Invoke-WorkstationCommand {
    <#
    .SYNOPSIS
        Dispatches a registered workstation command by name (registry lookup only).
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Name,
        [hashtable]$Args = @{}
    )

    $entry = Get-WorkstationCommandByName -Name $Name
    if (-not $entry) {
        $registry = Get-WorkstationCommandRegistry
        return [PSCustomObject]@{
            Status     = 'NotFound'
            Name       = $Name
            Registered = @($registry.Keys | Sort-Object)
        }
    }

    return & $entry.Handler -Args $Args
}
