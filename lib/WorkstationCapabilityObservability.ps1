# Wave B — capability observability (read-only introspection over registry metadata)
# lib/WorkstationCapabilityObservability.ps1
#
# Prerequisite: WorkstationCommandRegistry.ps1
# Does not execute commands, filter routing, enforce permissions, or mutate registry.

function Get-WorkstationCapabilityMatrix {
    $registry = Get-WorkstationCommandRegistry
    $grouped = @{}

    foreach ($name in ($registry.Keys | Sort-Object)) {
        $cap = [string]$registry[$name].Capability
        if (-not $grouped.ContainsKey($cap)) {
            $grouped[$cap] = [System.Collections.Generic.List[string]]::new()
        }
        $grouped[$cap].Add($name)
    }

    $matrix = [ordered]@{}
    foreach ($cap in ($grouped.Keys | Sort-Object)) {
        $matrix[$cap] = @($grouped[$cap] | Sort-Object)
    }
    return $matrix
}

function Get-WorkstationCommandsByCapability {
    param([Parameter(Mandatory)][string]$Capability)
    $matrix = Get-WorkstationCapabilityMatrix
    if (-not $matrix.Contains($Capability)) { return @() }
    return @($matrix[$Capability])
}

function Get-WorkstationCapabilityUsageReport {
    $registry = Get-WorkstationCommandRegistry
    $matrix   = Get-WorkstationCapabilityMatrix

    $commandsPerCapability = [ordered]@{}
    foreach ($cap in $matrix.Keys) {
        $commandsPerCapability[$cap] = $matrix[$cap].Count
    }

    $sourceDistribution = [ordered]@{}
    foreach ($name in ($registry.Keys | Sort-Object)) {
        $src = [string]$registry[$name].Source
        if (-not $sourceDistribution.Contains($src)) {
            $sourceDistribution[$src] = 0
        }
        $sourceDistribution[$src]++
    }

    return [ordered]@{
        Timestamp             = (Get-Date).ToString('o')
        TotalCommands         = $registry.Count
        CapabilityCount       = $matrix.Keys.Count
        CommandsPerCapability = $commandsPerCapability
        SourceDistribution    = $sourceDistribution
        Coverage              = [ordered]@{
            Capabilities = @($matrix.Keys)
            Sources      = @($sourceDistribution.Keys)
        }
        Matrix                = $matrix
    }
}
