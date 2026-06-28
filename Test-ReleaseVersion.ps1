#Requires -Version 7.0
<#
.SYNOPSIS
    Verify release version consistency across psd1, README, CHANGELOG, and Git tag.
.DESCRIPTION
    Phase 1.5 release gate helper. Does not modify runtime state.
    Checks:
      - modules/KGreen.Workstation.psd1 ModuleVersion
      - README.md version table
      - docs/charter/CHANGELOG.md section header
      - Git annotated tag v{version} exists
.PARAMETER Version
    Expected semver. Default: ModuleVersion from psd1.
.PARAMETER RequireTagAtHead
    Fail if current HEAD is not exactly tagged v{version}.
.PARAMETER SkipGit
    Skip Git tag checks (useful outside a repo clone).
.EXAMPLE
    pwsh -File .\Test-ReleaseVersion.ps1
.EXAMPLE
    pwsh -File .\Test-ReleaseVersion.ps1 -Version 2.0.0 -RequireTagAtHead
#>
[CmdletBinding()]
param(
    [string]$Version,
    [switch]$RequireTagAtHead,
    [switch]$SkipGit,
    [string]$Root = $PSScriptRoot
)

$ErrorActionPreference = 'Stop'

$psd1Path = Join-Path $Root 'modules\KGreen.Workstation.psd1'
$readmePath = Join-Path $Root 'README.md'
$changelogPath = Join-Path $Root 'docs\charter\CHANGELOG.md'

function Write-ReleaseCheck {
    param(
        [string]$Name,
        [bool]$Ok,
        [string]$Detail
    )
    $icon = if ($Ok) { 'PASS' } else { 'FAIL' }
    $color = if ($Ok) { 'Green' } else { 'Red' }
    Write-Host ("[{0}] {1}" -f $icon, $Name) -ForegroundColor $color
    if ($Detail) { Write-Host "      $Detail" -ForegroundColor DarkGray }
    return $Ok
}

if (-not (Test-Path $psd1Path)) {
    Write-Error "Missing manifest: $psd1Path"
}

$manifest = Import-PowerShellDataFile -Path $psd1Path
$psd1Version = [string]$manifest.ModuleVersion

if (-not $Version) {
    $Version = $psd1Version
}

$checks = @()
$allOk = $true

# psd1 internal consistency
$checks += (Write-ReleaseCheck -Name 'psd1 ModuleVersion present' -Ok ([bool]$psd1Version) -Detail $psd1Version)
if (-not $psd1Version) { $allOk = $false }

$semverOk = $psd1Version -match '^\d+\.\d+\.\d+$'
$checks += (Write-ReleaseCheck -Name 'psd1 semver format' -Ok $semverOk -Detail $psd1Version)
if (-not $semverOk) { $allOk = $false }

# parameter vs psd1
$paramOk = ($Version -eq $psd1Version)
$checks += (Write-ReleaseCheck -Name 'Expected version matches psd1' -Ok $paramOk -Detail "expected=$Version psd1=$psd1Version")
if (-not $paramOk) { $allOk = $false }

# README
$readmeOk = $false
$readmeDetail = 'README.md not found'
if (Test-Path $readmePath) {
    $readme = Get-Content -Path $readmePath -Raw
    if ($readme -match '\|\s*\*\*Версия\*\*\s*\|\s*([0-9]+\.[0-9]+\.[0-9]+)\s*\|') {
        $readmeVersion = $Matches[1]
        $readmeOk = ($readmeVersion -eq $Version)
        $readmeDetail = "README=$readmeVersion expected=$Version"
    }
    elseif ($readme -match 'HOME BASE v([0-9]+\.[0-9]+\.[0-9]+)') {
        $readmeVersion = $Matches[1]
        $readmeOk = ($readmeVersion -eq $Version)
        $readmeDetail = "README footer=$readmeVersion expected=$Version"
    }
    else {
        $readmeDetail = 'Version pattern not found in README.md'
    }
}
$checks += (Write-ReleaseCheck -Name 'README version' -Ok $readmeOk -Detail $readmeDetail)
if (-not $readmeOk) { $allOk = $false }

# CHANGELOG
$changelogOk = $false
$changelogDetail = 'CHANGELOG not found'
if (Test-Path $changelogPath) {
    $changelog = Get-Content -Path $changelogPath -Raw
    $releasedPattern = "\[${Version}\]"
    $unreleasedOk = $false
    if ($changelog -match '(?m)^## \[Unreleased\]') {
        $unreleasedOk = $true
    }
    $sectionOk = ($changelog -match [regex]::Escape($releasedPattern))
    $changelogOk = $sectionOk -or $unreleasedOk
    if ($sectionOk) {
        $changelogDetail = "section [$Version] found"
    }
    elseif ($unreleasedOk) {
        $changelogDetail = '[Unreleased] present (pre-tag OK)'
    }
    else {
        $changelogDetail = "missing [$Version] and [Unreleased]"
    }
}
$checks += (Write-ReleaseCheck -Name 'CHANGELOG entry' -Ok $changelogOk -Detail $changelogDetail)
if (-not $changelogOk) { $allOk = $false }

# Git tag
if (-not $SkipGit) {
    $gitRoot = $Root
    if (-not (Test-Path (Join-Path $gitRoot '.git'))) {
        $checks += (Write-ReleaseCheck -Name 'Git repository' -Ok $false -Detail '.git not found')
        $allOk = $false
    }
    else {
        $tagName = "v$Version"
        $tagList = git -C $gitRoot tag -l $tagName 2>$null
        $tagExists = ($tagList -eq $tagName)
        $checks += (Write-ReleaseCheck -Name 'Git tag exists' -Ok $tagExists -Detail $tagName)
        if (-not $tagExists) { $allOk = $false }

        if ($RequireTagAtHead) {
            $headTag = git -C $gitRoot describe --tags --exact-match HEAD 2>$null
            $headOk = ($headTag -eq $tagName)
            $checks += (Write-ReleaseCheck -Name 'HEAD tagged exactly' -Ok $headOk -Detail "HEAD=$headTag expected=$tagName")
            if (-not $headOk) { $allOk = $false }
        }
    }
}

Write-Host ''
if ($allOk) {
    Write-Host "Release version $Version — CONSISTENT" -ForegroundColor Green
    exit 0
}

Write-Host "Release version $Version — INCONSISTENT" -ForegroundColor Red
Write-Host 'Fix psd1, README, CHANGELOG, or Git tag before release.' -ForegroundColor Yellow
exit 1
