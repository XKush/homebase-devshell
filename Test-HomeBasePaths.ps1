#Requires -Version 7.0
<#
.SYNOPSIS
    Verify Get-HomeBasePath matches legacy standard folders (Phase 2 Step 1).
#>
$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
. (Join-Path $root 'lib\HomeBasePaths.ps1')
. (Join-Path $root 'lib\WorkstationFolders.ps1')

$legacy = @{
    Logs    = 'C:\Logs\Workstation'
    Backups = 'C:\Backups\Workstation'
    Configs = 'C:\Configs\Workstation'
    Projects = 'C:\Projects'
    Tools   = 'C:\Tools'
    Scripts = 'C:\Scripts'
}

$fail = 0
foreach ($key in $legacy.Keys) {
    $got = Get-HomeBasePath -Name $key
    $ok = ($got -eq $legacy[$key])
    if (-not $ok) { $fail++ }
    Write-Host ("[{0}] {1} => {2} (expected {3})" -f $(if ($ok) { 'PASS' } else { 'FAIL' }), $key, $got, $legacy[$key])
}

$std = Get-WorkstationStandardFolders
foreach ($key in @('Logs', 'Backups', 'Configs')) {
    $ok = ($std[$key] -eq $legacy[$key])
    if (-not $ok) { $fail++ }
    Write-Host ("[{0}] StandardFolders.{1}" -f $(if ($ok) { 'PASS' } else { 'FAIL' }), $key)
}

if ($fail -gt 0) { exit 1 }
Write-Host 'Test-HomeBasePaths: all paths match legacy layout' -ForegroundColor Green
exit 0
