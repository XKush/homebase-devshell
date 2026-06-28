#Requires -Version 7.0
<#
.SYNOPSIS
    Restore rehearsal — verify backup integrity without applying rollback.
.DESCRIPTION
    Phase 2 quality gate. Validates latest (or specified) backup folder
    contains files required for restoreconfig / Rollback-Workstation.ps1.
    Does NOT import registry or overwrite live profile.
#>
[CmdletBinding()]
param(
    [string]$BackupFolder,
    [string]$BackupRoot = 'C:\Backups\Workstation'
)

$ErrorActionPreference = 'Stop'

if (-not $BackupFolder) {
    $latest = Get-ChildItem $BackupRoot -Directory -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -notmatch '^_' } |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1
    if (-not $latest) { throw "No backup folders in $BackupRoot" }
    $BackupFolder = $latest.FullName
}

if (-not (Test-Path $BackupFolder)) { throw "Backup not found: $BackupFolder" }

$required = @(
    @{ Name = 'manifest.json'; Required = $true }
    @{ Name = 'Microsoft.PowerShell_profile.ps1'; Required = $false }
    @{ Name = 'WindowsTerminal-settings.json'; Required = $false }
)

$results = [System.Collections.Generic.List[object]]::new()
$ok = $true

foreach ($item in $required) {
    $path = Join-Path $BackupFolder $item.Name
    $exists = Test-Path $path
    if ($item.Required -and -not $exists) { $ok = $false }
    $results.Add([PSCustomObject]@{
        File     = $item.Name
        Required = $item.Required
        Exists   = $exists
        Path     = $path
    })
}

$manifest = $null
$manifestPath = Join-Path $BackupFolder 'manifest.json'
if (Test-Path $manifestPath) {
    $manifest = Get-Content $manifestPath -Raw | ConvertFrom-Json
}

$regDir = Join-Path $BackupFolder 'registry'
$regCount = if (Test-Path $regDir) {
    (Get-ChildItem $regDir -Filter '*.reg' -ErrorAction SilentlyContinue).Count
} else { 0 }

Write-Host "[RESTORE REHEARSAL] $BackupFolder" -ForegroundColor Cyan
foreach ($r in $results) {
    $icon = if ($r.Exists) { 'PASS' } elseif ($r.Required) { 'FAIL' } else { 'SKIP' }
    $color = switch ($icon) { 'PASS' { 'Green' } 'FAIL' { 'Red' } default { 'DarkGray' } }
    Write-Host ("  [{0}] {1}" -f $icon, $r.File) -ForegroundColor $color
}
Write-Host ("  [INFO] registry exports: {0}" -f $regCount) -ForegroundColor DarkGray
if ($manifest) {
    Write-Host ("  [INFO] manifest timestamp: {0}" -f $manifest.Timestamp) -ForegroundColor DarkGray
}

if (-not $ok) {
    Write-Host 'RESTORE REHEARSAL: FAIL — backup not restorable' -ForegroundColor Red
    exit 1
}

Write-Host 'RESTORE REHEARSAL: PASS — backup verified (dry run, no restore applied)' -ForegroundColor Green
exit 0
