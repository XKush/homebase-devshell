#Requires -Version 7.0
<#
.SYNOPSIS
    Build devready-vX.Y.Z.zip and SHA256 sidecar for GitHub Releases.
.PARAMETER Version
    Semver without v prefix (e.g. 2.2.0). Defaults to psd1 ModuleVersion.
#>
[CmdletBinding()]
param(
    [string]$Version,
    [string]$OutputDir,
    [switch]$UpdateManifests
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '..\_Resolve-RepoRoot.ps1')
$root = Resolve-WorkstationRepoRoot -Start $PSScriptRoot

$psd1 = Join-Path $root 'modules\KGreen.Workstation.psd1'
if (-not $Version) {
    $Version = [string](Import-PowerShellDataFile $psd1).ModuleVersion
}
$tag = "v$Version"
if (-not $OutputDir) { $OutputDir = Join-Path $root 'dist' }

$zipName = "devready-$tag.zip"
$zipPath = Join-Path $OutputDir $zipName
$shaPath = Join-Path $OutputDir "devready-$tag.sha256.txt"

$excludeDirs = @(
    '.git', 'dist', '.cursor', 'internal-docs', 'node_modules', '__pycache__'
)
$excludeFiles = @('*.log', '*.tmp', '.tmp-*.json', 'validation-*.json', 'platform-hardening-*.json')

if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null
}
if (Test-Path $zipPath) { Remove-Item $zipPath -Force }

$staging = Join-Path ([System.IO.Path]::GetTempPath()) "devready-build-$([guid]::NewGuid().ToString('N').Substring(0, 8))"
New-Item -ItemType Directory -Force -Path $staging | Out-Null

try {
    Get-ChildItem -Path $root -Force | ForEach-Object {
        if ($_.PSIsContainer) {
            if ($excludeDirs -contains $_.Name) { return }
            Copy-Item -Path $_.FullName -Destination (Join-Path $staging $_.Name) -Recurse -Force
        } else {
            $skip = $false
            foreach ($pat in $excludeFiles) {
                if ($_.Name -like $pat) { $skip = $true; break }
            }
            if (-not $skip) {
                Copy-Item -Path $_.FullName -Destination (Join-Path $staging $_.Name) -Force
            }
        }
    }

    Compress-Archive -Path (Join-Path $staging '*') -DestinationPath $zipPath -CompressionLevel Optimal -Force
    $hash = (Get-FileHash -Path $zipPath -Algorithm SHA256).Hash.ToLower()
    Set-Content -Path $shaPath -Value $hash -Encoding ASCII -NoNewline

    Write-Host "Built: $zipPath ($((Get-Item $zipPath).Length) bytes)" -ForegroundColor Green
    Write-Host "SHA256: $hash" -ForegroundColor Green
    Write-Host "Wrote: $shaPath" -ForegroundColor Green

    if ($UpdateManifests) {
        $scoopPath = Join-Path $root 'packaging\scoop\devready.json'
        $wingetPath = Join-Path $root 'packaging\winget\XKush.DevReady.yaml'
        if (Test-Path $scoopPath) {
            $scoop = Get-Content $scoopPath -Raw | ConvertFrom-Json
            $scoop.version = $Version
            $scoop.url = "https://github.com/XKush/homebase-devshell/releases/download/$tag/devready-$tag.zip"
            $scoop.hash = "sha256:$hash"
            $scoop | ConvertTo-Json -Depth 6 | Set-Content $scoopPath -Encoding UTF8
            Write-Host "Updated: $scoopPath" -ForegroundColor DarkGray
        }
        if (Test-Path $wingetPath) {
            $winget = Get-Content $wingetPath -Raw
            $winget = $winget -replace '(?m)^PackageVersion:.*', "PackageVersion: $Version"
            $winget = $winget -replace '(?m)^InstallerSha256:.*', "InstallerSha256: $hash"
            $winget = $winget -replace 'releases/download/v[\d.]+/', "releases/download/$tag/"
            Set-Content $wingetPath $winget -Encoding UTF8 -NoNewline
            Write-Host "Updated: $wingetPath" -ForegroundColor DarkGray
        }
    }
}
finally {
    if (Test-Path $staging) { Remove-Item $staging -Recurse -Force }
}
