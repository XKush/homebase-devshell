# Wave B — command routing layer (static dispatch map, no business logic)
# lib/WorkstationCommandRouter.ps1
#
# Prerequisite: WorkstationOrchestrator.ps1 (Invoke-WorkstationProfile, Get-WorkstationExecutionContext)
# Does not dot-source bootstrap layers (C1–C4) or mutate environment.

$script:WorkstationCommandMap = @{
    'profile.reload' = {
        param([hashtable]$Args)
        $root = if ($Args -and $Args.RepositoryRoot) { [string]$Args.RepositoryRoot } else { $null }
        if ($root) {
            Invoke-WorkstationProfile -Force -RepositoryRoot $root
        } else {
            Invoke-WorkstationProfile -Force
        }
    }
    'env.show' = {
        param([hashtable]$Args)
        Get-WorkstationExecutionContext
    }
    'diag.boot' = {
        param([hashtable]$Args)
        if (-not (Get-Command Test-WorkstationBootEnvironment -ErrorAction SilentlyContinue)) {
            return [PSCustomObject]@{
                Status = 'Unavailable'
                Detail = 'C5 BootCheck not loaded'
            }
        }
        Test-WorkstationBootEnvironment
    }
}

function Get-WorkstationCommandMap {
    return $script:WorkstationCommandMap
}

function Invoke-WorkstationCommand {
    <#
    .SYNOPSIS
        Dispatches a registered workstation command by name (static map only).
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Name,
        [hashtable]$Args = @{}
    )

    $map = Get-WorkstationCommandMap
    if (-not $map.ContainsKey($Name)) {
        return [PSCustomObject]@{
            Status     = 'NotFound'
            Name       = $Name
            Registered = @($map.Keys | Sort-Object)
        }
    }

    return & $map[$Name] -Args $Args
}
