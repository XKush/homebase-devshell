#Requires -Version 7.0
<#
.SYNOPSIS
    Finish PGP setup for existing key (repair after partial pgp-setup).
#>
. "$PSScriptRoot\lib\WorkstationCommon.ps1"
. "$PSScriptRoot\lib\PgpCommon.ps1"
$secDir = 'C:\Security\pgp'
$bakDir = 'C:\Backups\Workstation\pgp'
foreach ($d in @($secDir, $bakDir)) {
    if (-not (Test-Path $d)) { New-Item -ItemType Directory -Force -Path $d | Out-Null }
}

$fpr = Get-GpgPrimaryFingerprint
if (-not $fpr) { Write-WorkstationLog 'No secret key found' 'ERROR'; exit 1 }

$uidLine = gpg --list-secret-keys --with-colons 2>$null | Where-Object { $_ -match '^uid:' } | Select-Object -First 1
$uid = if ($uidLine) { ($uidLine -split ':')[9] } else { 'unknown' }

Complete-PgpIdentityExport -Uid $uid -Fingerprint $fpr | Out-Null

Write-WorkstationLog "Fingerprint: $fpr" 'OK'
Write-WorkstationLog "UID:         $uid" 'OK'
Write-WorkstationLog "Metadata:    C:\Security\pgp\pgp-identity.json" 'OK'
