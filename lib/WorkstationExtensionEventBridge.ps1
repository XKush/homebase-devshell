# Wave D — extension event bridge (wiring only — maps extension lifecycle to Event Core)
# lib/WorkstationExtensionEventBridge.ps1
#
# Prerequisite: WorkstationEventCore.ps1
# Does not analyze, route, store events separately, or mutate execution flow.

function New-WorkstationExtensionEvent {
    <#
    .SYNOPSIS
        Maps extension runtime lifecycle phases to Event Core entries (emit-only bridge).
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][ValidateSet('start', 'success', 'fail')][string]$Phase
    )

    if (-not (Get-Command New-WorkstationLifecycleEvent -ErrorAction SilentlyContinue)) {
        return $null
    }

    return New-WorkstationLifecycleEvent -Layer Handler -Family extension.execute -Phase $Phase -Target $Name
}
