#Requires -Version 7.0
<#
.SYNOPSIS
    Privacy configuration — delegates to Repair-PrivacySettings (SSOT). Never enables Defender.
#>
param(
    [switch]$Force,
    [ValidateSet('Quad9', 'Cloudflare', 'Mullvad', 'None')]
    [string]$DnsProvider = 'Quad9'
)

. (Join-Path $PSScriptRoot '..\_Resolve-RepoRoot.ps1')
$repoRoot = Resolve-WorkstationRepoRoot -Start $PSScriptRoot

$ErrorActionPreference = 'Stop'
. "$repoRoot\lib\WorkstationCommon.ps1"
Assert-WorkstationAdmin
Assert-DefenderUntouched

if (-not (Confirm-WorkstationAction -Message 'Apply privacy settings?' -Force:$Force)) { return }

Write-WorkstationStep 'Privacy configuration (admin)'
Write-WorkstationLog 'Windows Update not disabled — security patches continue' 'OK'

& (Join-Path $repoRoot 'scripts\maintainer\configure\Repair-PrivacySettings.ps1') -Force -RepoRoot $repoRoot -DnsProvider $DnsProvider

Write-WorkstationStep 'Privacy configuration complete'
