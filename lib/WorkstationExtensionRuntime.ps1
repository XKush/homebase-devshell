# Wave D — extension runtime (controlled execution boundary — no core control)
# lib/WorkstationExtensionRuntime.ps1
#
# Prerequisite: WorkstationCapabilityExtensions.ps1, WorkstationExtensionEventBridge.ps1
# Does not route commands, orchestrate lifecycle, or mutate core state.

function New-WorkstationExtensionExecutionContext {
    param(
        [string]$Command,
        [hashtable]$Arguments = @{}
    )

    $capabilities = if (Get-Command Get-WorkstationCommandCapabilities -ErrorAction SilentlyContinue) {
        Get-WorkstationCommandCapabilities
    } else {
        [ordered]@{ Commands = @(); Capabilities = @(); Sources = @() }
    }

    $environment = [ordered]@{}
    if ($global:WorkstationExecutionContext) {
        foreach ($key in $global:WorkstationExecutionContext.Keys) {
            $environment[$key] = $global:WorkstationExecutionContext[$key]
        }
    }

    return [ordered]@{
        Command      = [string]$Command
        Arguments    = $Arguments
        Capabilities = $capabilities
        Environment  = $environment
    }
}

function Invoke-WorkstationExtension {
    <#
    .SYNOPSIS
        Executes a registered extension EntryPoint with a read-only execution context snapshot.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Name,
        [string]$Command = '',
        [Alias('Args')]
        [hashtable]$Arguments = @{}
    )

    $extension = Get-WorkstationExtension -Name $Name
    if (-not $extension) {
        return [PSCustomObject]@{
            Status = 'NotFound'
            Name   = $Name
        }
    }

    $ctx = New-WorkstationExtensionExecutionContext -Command $Command -Arguments $Arguments

    if (Get-Command New-WorkstationExtensionEvent -ErrorAction SilentlyContinue) {
        New-WorkstationExtensionEvent -Name $Name -Phase start | Out-Null
    }

    try {
        $result = & $extension.EntryPoint $ctx
        if (Get-Command New-WorkstationExtensionEvent -ErrorAction SilentlyContinue) {
            New-WorkstationExtensionEvent -Name $Name -Phase success | Out-Null
        }
        return $result
    } catch {
        if (Get-Command New-WorkstationExtensionEvent -ErrorAction SilentlyContinue) {
            New-WorkstationExtensionEvent -Name $Name -Phase fail | Out-Null
        }
        throw
    }
}
