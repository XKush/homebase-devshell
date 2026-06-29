# Wave C — execution trace view (read-only correlation over events + registry metadata)
# lib/WorkstationExecutionTrace.ps1
#
# Prerequisite: WorkstationEventCore.ps1, WorkstationCommandRegistry.ps1
# Does not emit events, mutate buffers, score, filter, or execute commands.

function Get-WorkstationExecutionTrace {
    <#
    .SYNOPSIS
        Builds a read-only trace by joining event buffer entries with registry capability metadata.
    .OUTPUTS
        Ordered list of trace records: Time, Command, Layer, Capability, Status.
    #>
    [CmdletBinding()]
    param()

    $registry = $script:WorkstationCommandRegistry
    if (-not $registry) { $registry = @{} }

    $extensions = $script:WorkstationExtensions
    if (-not $extensions) { $extensions = @{} }

    $trace = [System.Collections.Generic.List[object]]::new()

    foreach ($event in @($script:WorkstationEventBuffer)) {
        $target = [string]$event.Target
        $action = [string]$event.Action
        $command = ''
        $capability = ''

        if ($target -and $registry.ContainsKey($target)) {
            $command = $target
            $capability = [string]$registry[$target].Capability
        } elseif ($action -like 'command.execute.*' -and $target) {
            $command = $target
        } elseif ($action -like 'extension.execute.*' -and $target) {
            $command = $target
            if ($extensions.ContainsKey($target)) {
                $capability = [string]$extensions[$target].Capability
            }
        }

        $timeValue = $event.Time
        if ($timeValue -is [datetime]) {
            $timeValue = $timeValue.ToString('o')
        } else {
            $timeValue = [string]$timeValue
        }

        $trace.Add([ordered]@{
            Time       = $timeValue
            Command    = $command
            Layer      = [string]$event.Layer
            Capability = $capability
            Status     = [string]$event.Status
        })
    }

    return ,[object[]]@($trace.ToArray())
    # Assign directly: $rows = Get-WorkstationExecutionTrace — do not use @(...) wrapper.
}
