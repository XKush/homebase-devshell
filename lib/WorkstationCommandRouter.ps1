# Wave B — command routing layer (dispatch only — definitions live in registry)
# lib/WorkstationCommandRouter.ps1
#
# Prerequisite: WorkstationCommandRegistry.ps1, WorkstationOrchestrator.ps1
# Does not interpret capabilities, filter commands, or mutate environment.

function Get-WorkstationCommandMap {
    $registry = $script:WorkstationCommandRegistry
    if (-not $registry) { return @{} }
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
        [Alias('Args')]
        [hashtable]$CommandArgs = @{}
    )

    if (Get-Command New-WorkstationLifecycleEvent -ErrorAction SilentlyContinue) {
        New-WorkstationLifecycleEvent -Layer Router -Family command.execute -Phase start -Target $Name | Out-Null
    }

    $registry = $script:WorkstationCommandRegistry
    $entry = if ($registry -and $registry.ContainsKey($Name)) { $registry[$Name] } else { $null }
    if (-not $entry) {
        if (Get-Command New-WorkstationLifecycleEvent -ErrorAction SilentlyContinue) {
            New-WorkstationLifecycleEvent -Layer Router -Family command.execute -Phase fail -Target $Name | Out-Null
        }
        return [PSCustomObject]@{
            Status     = 'NotFound'
            Name       = $Name
            Registered = @($registry.Keys | Sort-Object)
        }
    }

    try {
        $result = & $entry.Handler $CommandArgs
        if (Get-Command New-WorkstationLifecycleEvent -ErrorAction SilentlyContinue) {
            New-WorkstationLifecycleEvent -Layer Router -Family command.execute -Phase success -Target $Name | Out-Null
        }
        return $result
    } catch {
        if (Get-Command New-WorkstationLifecycleEvent -ErrorAction SilentlyContinue) {
            New-WorkstationLifecycleEvent -Layer Router -Family command.execute -Phase fail -Target $Name | Out-Null
        }
        throw
    }
}
