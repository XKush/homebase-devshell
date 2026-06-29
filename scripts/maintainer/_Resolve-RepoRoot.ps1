function Resolve-WorkstationRepoRoot {
    [CmdletBinding()]
    param(
        [string]$Start = $PSScriptRoot
    )

    if ($env:HOMEBASE_DEVSHELL_ROOT -and (Test-Path (Join-Path $env:HOMEBASE_DEVSHELL_ROOT 'lib\HomeBasePaths.ps1'))) {
        return $env:HOMEBASE_DEVSHELL_ROOT
    }

    $candidate = $Start
    for ($i = 0; $i -lt 6; $i++) {
        if (Test-Path (Join-Path $candidate 'lib\HomeBasePaths.ps1')) {
            return (Resolve-Path $candidate).Path
        }
        $parent = Split-Path $candidate -Parent
        if (-not $parent -or $parent -eq $candidate) { break }
        $candidate = $parent
    }

    if (Test-Path 'C:\Scripts\Workstation\lib\HomeBasePaths.ps1') {
        return 'C:\Scripts\Workstation'
    }

    throw "HomeBase DevShell repository root not found from: $Start"
}

function Resolve-WorkstationScript {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Name,
        [string]$Start = $PSScriptRoot
    )

    $repoRoot = Resolve-WorkstationRepoRoot -Start $Start
    foreach ($sub in @('install', 'invoke', 'configure', 'test', 'phase2')) {
        $path = Join-Path $repoRoot "scripts\maintainer\$sub\$Name"
        if (Test-Path $path) { return $path }
    }

    throw "Workstation script not found under scripts/maintainer: $Name"
}
