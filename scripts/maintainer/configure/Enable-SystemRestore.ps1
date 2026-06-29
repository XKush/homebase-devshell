#Requires -Version 7.0
#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Enable System Protection on C: and create restore point.
#>
param([switch]$Force)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '..\_Resolve-RepoRoot.ps1')
$repoRoot = Resolve-WorkstationRepoRoot -Start $PSScriptRoot
$script:WSRoot = $repoRoot
. (Join-Path $repoRoot 'lib\WorkstationCommon.ps1')
Assert-WorkstationAdmin
Assert-DefenderUntouched

Write-WorkstationStep 'Enable System Protection on C:'
try {
    Enable-ComputerRestore -Drive 'C:\' -ErrorAction Stop
    vssadmin resize shadowstorage /for=C: /on=C: /maxsize=5GB 2>$null | Out-Null
    Write-WorkstationLog 'System Protection enabled on C:' 'OK'
} catch {
    Write-WorkstationLog "Enable-ComputerRestore: $($_.Exception.Message)" 'WARN'
}

Write-WorkstationStep 'Create restore point'
try {
    Checkpoint-Computer -Description 'HOME BASE baseline restore point' -RestorePointType MODIFY_SETTINGS -ErrorAction Stop
    Write-WorkstationLog 'Restore point created' 'OK'
} catch {
    Write-WorkstationLog "Checkpoint-Computer: $($_.Exception.Message)" 'WARN'
    Write-Host '  Retry after reboot if VSS busy.' -ForegroundColor Yellow
}

Write-WorkstationStep 'Verify firewall inbound Block'
foreach ($prof in @('Domain', 'Private', 'Public')) {
    Set-NetFirewallProfile -Profile $prof -Enabled True -DefaultInboundAction Block -DefaultOutboundAction Allow -ErrorAction SilentlyContinue
    Write-WorkstationLog "Firewall $prof -> inbound Block" 'OK'
}

Write-WorkstationStep 'Restore point pass complete'
