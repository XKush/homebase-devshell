# Wave C — event core (passive execution trace — append-only, in-memory only)
# lib/WorkstationEventCore.ps1
#
# Does not persist, analyze, aggregate, route, or mutate system state.
#
# Lifecycle contract (emit-only, one start + one terminal event per invocation):
#   Router:       command.execute.{start|success|fail}
#   Orchestrator: profile.init.{start|success|fail}
#   Extension:    extension.execute.{start|success|fail}

$script:WorkstationEventBuffer = @()

function Get-WorkstationEventLifecycleContract {
    return [ordered]@{
        Router       = @('command.execute.start', 'command.execute.success', 'command.execute.fail')
        Orchestrator = @('profile.init.start', 'profile.init.success', 'profile.init.fail')
        Extension    = @('extension.execute.start', 'extension.execute.success', 'extension.execute.fail')
    }
}

function New-WorkstationLifecycleEvent {
    <#
    .SYNOPSIS
        Emits a lifecycle event using the shared action naming contract.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][ValidateSet('Router', 'Orchestrator', 'Registry', 'Handler')][string]$Layer,
        [Parameter(Mandatory)][ValidateSet('command.execute', 'profile.init', 'extension.execute')][string]$Family,
        [Parameter(Mandatory)][ValidateSet('start', 'success', 'fail')][string]$Phase,
        [string]$Target = ''
    )

    $status = if ($Phase -eq 'fail') { 'fail' } else { 'success' }
    return New-WorkstationEvent -Layer $Layer -Action "$Family.$Phase" -Target $Target -Status $status
}

function New-WorkstationEvent {
    <#
    .SYNOPSIS
        Records a single execution trace event in the in-memory buffer (append-only).
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][ValidateSet('Router', 'Orchestrator', 'Registry', 'Handler')][string]$Layer,
        [Parameter(Mandatory)][string]$Action,
        [string]$Target = '',
        [ValidateSet('success', 'fail')][string]$Status = 'success'
    )

    $event = [ordered]@{
        Time   = Get-Date
        Layer  = $Layer
        Action = $Action
        Target = $Target
        Status = $Status
    }

    $script:WorkstationEventBuffer += ,$event
    return $event
}

function Test-WorkstationEventBufferContract {
    <#
    .SYNOPSIS
        Validates event buffer entries against the lifecycle action contract (read-only).
    #>
    [CmdletBinding()]
    param([int]$FromIndex = 0)

    $contract = Get-WorkstationEventLifecycleContract
    $allowed = @($contract.Router + $contract.Orchestrator + $contract.Extension)

    foreach ($event in @($script:WorkstationEventBuffer | Select-Object -Skip $FromIndex)) {
        if ($event.Action -notin $allowed) {
            throw "Non-contract action: $($event.Action)"
        }
        if ($event.Status -notin @('success', 'fail')) {
            throw "Invalid status: $($event.Status)"
        }
    }

    return (@($script:WorkstationEventBuffer).Count - $FromIndex)
}

function Test-WorkstationEventLifecyclePairs {
    <#
    .SYNOPSIS
        Validates start/terminal lifecycle pairing in the event buffer (read-only).
    #>
    [CmdletBinding()]
    param([int]$FromIndex = 0)

    $open = @{}
    foreach ($event in @($script:WorkstationEventBuffer | Select-Object -Skip $FromIndex)) {
        if ($event.Action -like '*.start') {
            $family = $event.Action -replace '\.start$',''
            $key = "$($event.Layer)|$($event.Target)|$family"
            if ($open.ContainsKey($key)) { throw "Duplicate start without terminal: $key" }
            $open[$key] = $true
        } elseif ($event.Action -like '*.success' -or $event.Action -like '*.fail') {
            $family = $event.Action -replace '\.(success|fail)$',''
            $key = "$($event.Layer)|$($event.Target)|$family"
            if (-not $open.ContainsKey($key)) { throw "Terminal without start: $key" }
            $open.Remove($key) | Out-Null
        }
    }

    if ($open.Count -gt 0) {
        throw "Unclosed lifecycle starts: $(@($open.Keys) -join ', ')"
    }

    return $true
}
