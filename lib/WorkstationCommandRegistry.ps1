# Wave B — command registry (declarative definitions, no execution)
# lib/WorkstationCommandRegistry.ps1
#
# Prerequisite: WorkstationOrchestrator.ps1 (handlers delegate to orchestrator / C5 at dispatch time)
# Does not execute commands, filter by capability, or mutate system state.
#
# SSOT: $script:WorkstationCommandRegistry (Wave B core — not KGreen.Workstation module registry)

$script:WorkstationCommandRegistry = @{
    'profile.reload' = @{
        Handler    = {
            param([hashtable]$CommandArgs)
            $root = if ($CommandArgs -and $CommandArgs.RepositoryRoot) { [string]$CommandArgs.RepositoryRoot } else { $null }
            if ($root) {
                Invoke-WorkstationProfile -Force -RepositoryRoot $root
            } else {
                Invoke-WorkstationProfile -Force
            }
        }
        Capability = 'system.lifecycle'
        Source     = 'core'
    }
    'env.show' = @{
        Handler    = {
            param([hashtable]$CommandArgs)
            Get-WorkstationExecutionContext
        }
        Capability = 'system.inspect'
        Source     = 'core'
    }
    'diag.boot' = @{
        Handler    = {
            param([hashtable]$CommandArgs)
            if (-not (Get-Command Test-WorkstationBootEnvironment -ErrorAction SilentlyContinue)) {
                return [PSCustomObject]@{
                    Status = 'Unavailable'
                    Detail = 'C5 BootCheck not loaded'
                }
            }
            Test-WorkstationBootEnvironment
        }
        Capability = 'diagnostics.read'
        Source     = 'diagnostics'
    }
}

function Get-WorkstationCommandRegistry {
    return $script:WorkstationCommandRegistry
}

function Get-WorkstationCommandByName {
    param([Parameter(Mandatory)][string]$Name)
    $registry = $script:WorkstationCommandRegistry
    if (-not $registry -or -not $registry.ContainsKey($Name)) { return $null }
    return $registry[$Name]
}

function Get-WorkstationCommandCapabilities {
    $registry = $script:WorkstationCommandRegistry
    if (-not $registry) { $registry = @{} }

    return [ordered]@{
        Commands = @(
            $registry.Keys | Sort-Object | ForEach-Object {
                [ordered]@{
                    Name       = $_
                    Capability = [string]$registry[$_].Capability
                    Source     = [string]$registry[$_].Source
                }
            }
        )
        Capabilities = @($registry.Values | ForEach-Object { $_.Capability } | Sort-Object -Unique)
        Sources      = @($registry.Values | ForEach-Object { $_.Source } | Sort-Object -Unique)
    }
}
