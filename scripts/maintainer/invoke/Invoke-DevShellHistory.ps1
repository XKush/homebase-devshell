#Requires -Version 7.0
[CmdletBinding()]
param([int]$Last = 15)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '..\_Resolve-RepoRoot.ps1')
$repoRoot = Resolve-WorkstationRepoRoot -Start $PSScriptRoot
. (Join-Path $repoRoot 'lib\WorkstationCommon.ps1')
. (Join-Path $repoRoot 'lib\DevShellHealth.ps1')

Show-DevShellHealthHistory -Last $Last
exit 0
