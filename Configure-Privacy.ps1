#Requires -Version 7.0
<#
.SYNOPSIS
    Root shim вЂ” forwards to scripts/maintainer (backwards compatibility).
#>
$env:HOMEBASE_DEVSHELL_ROOT = $PSScriptRoot
& (Join-Path $PSScriptRoot 'scripts\maintainer\configure\Configure-Privacy.ps1') @args
if ($null -ne $LASTEXITCODE) { exit $LASTEXITCODE }
