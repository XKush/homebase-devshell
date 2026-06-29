#Requires -Version 7.0
<#
.SYNOPSIS
    Metadata toolkit — view or strip EXIF/metadata (requires exiftool).
#>
[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string]$Path,
    [switch]$Strip,
    [switch]$Json
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '..\_Resolve-RepoRoot.ps1')
$repoRoot = Resolve-WorkstationRepoRoot -Start $PSScriptRoot
. (Join-Path $repoRoot 'lib\WorkstationCommon.ps1')

function Find-ExifTool {
    if (Get-Command exiftool -ErrorAction SilentlyContinue) { return 'exiftool' }
    foreach ($p in @(
        'C:\Tools\exiftool\exiftool.exe'
        "${env:ProgramFiles}\exiftool\exiftool.exe"
        (Join-Path $env:LOCALAPPDATA 'Microsoft\WinGet\Links\exiftool.exe')
    )) {
        if ($p -and (Test-Path $p)) { return $p }
    }
    return $null
}

$exif = Find-ExifTool
if (-not $exif) {
    Write-Host 'exiftool not found.' -ForegroundColor Yellow
    Write-Host '  Install: winget install -e --id OliverBetz.ExifTool' -ForegroundColor DarkGray
    Write-Host '  Then: devshell metadata photo.jpg' -ForegroundColor DarkGray
    exit 1
}

if ([string]::IsNullOrWhiteSpace($Path)) {
    Write-Host @'

Metadata toolkit

  devshell metadata <file>         View EXIF/metadata
  devshell metadata <file> -Strip  Remove metadata (writes *_clean copy)

Safe source: winget OliverBetz.ExifTool

'@ -ForegroundColor DarkGray
    exit 0
}

if (-not (Test-Path $Path)) {
    Write-Error "File not found: $Path"
}

if ($Strip) {
    $dir = Split-Path $Path -Parent
    $base = [System.IO.Path]::GetFileNameWithoutExtension($Path)
    $ext = [System.IO.Path]::GetExtension($Path)
    $out = Join-Path $dir "${base}_clean$ext"
    Write-Host "Stripping metadata → $out" -ForegroundColor Cyan
    & $exif -all= -o $out $Path
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    Write-Host 'Done. Publish the _clean copy only.' -ForegroundColor Green
    exit 0
}

Write-Host "Metadata: $Path" -ForegroundColor Cyan
Write-Host ''
& $exif $Path
exit $LASTEXITCODE
