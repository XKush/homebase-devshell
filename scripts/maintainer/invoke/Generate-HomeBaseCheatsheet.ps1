#Requires -Version 7.0
<#
.SYNOPSIS
    Regenerate QUICKREF + COMMANDS from live catalog (wrapper).
#>
. (Join-Path $PSScriptRoot '..\_Resolve-RepoRoot.ps1')
& (Resolve-WorkstationScript -Name 'Sync-WorkstationDocs.ps1' -Start $PSScriptRoot)
