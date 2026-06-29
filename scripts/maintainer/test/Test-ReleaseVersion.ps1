#Requires -Version 7.0
<#
.SYNOPSIS
    Verify release version consistency across psd1, install pin, CHANGELOG, and Git tag.
.DESCRIPTION
    Release gate helper. Does not modify runtime state.
    Checks:
      - modules/KGreen.Workstation.psd1 ModuleVersion
      - install.ps1 pinned release URL (homebase-devshell/vX.Y.Z)
      - CHANGELOG.md (root) section [X.Y.Z] or [Unreleased]
      - Git annotated tag v{version} exists
#>
[CmdletBinding()]
param(
    [string]$Version,
    [switch]$RequireTagAtHead,
    [switch]$SkipGit,
    [string]$Root
)

$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot '..\_Resolve-RepoRoot.ps1')
if (-not $Root) { $Root = Resolve-WorkstationRepoRoot -Start $PSScriptRoot }

$psd1Path = Join-Path $Root 'modules\KGreen.Workstation.psd1'
$installPath = Join-Path $Root 'install.ps1'
$changelogPath = Join-Path $Root 'CHANGELOG.md'

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

$allOk = $true

$checks = @()
$checks += (Write-ReleaseCheck -Name 'psd1 ModuleVersion present' -Ok ([bool]$psd1Version) -Detail $psd1Version)
if (-not $psd1Version) { $allOk = $false }

$semverOk = $psd1Version -match '^\d+\.\d+\.\d+$'
$checks += (Write-ReleaseCheck -Name 'psd1 semver format' -Ok $semverOk -Detail $psd1Version)
if (-not $semverOk) { $allOk = $false }

$paramOk = ($Version -eq $psd1Version)
$checks += (Write-ReleaseCheck -Name 'Expected version matches psd1' -Ok $paramOk -Detail "expected=$Version psd1=$psd1Version")
if (-not $paramOk) { $allOk = $false }

$installOk = $false
$installDetail = 'install.ps1 not found'
if (Test-Path $installPath) {
    $install = Get-Content -Path $installPath -Raw
    $pin = "homebase-devshell/v$Version"
    $installOk = $install -match [regex]::Escape($pin)
    $installDetail = if ($installOk) { "pinned URL contains $pin" } else { "missing install pin $pin" }
}
$checks += (Write-ReleaseCheck -Name 'install.ps1 release pin' -Ok $installOk -Detail $installDetail)
if (-not $installOk) { $allOk = $false }

$changelogOk = $false
$changelogDetail = 'CHANGELOG.md not found'
if (Test-Path $changelogPath) {
    $changelog = Get-Content -Path $changelogPath -Raw
    $releasedPattern = "\[${Version}\]"
    $unreleasedOk = $changelog -match '(?m)^## \[Unreleased\]'
    $sectionOk = ($changelog -match [regex]::Escape($releasedPattern))
    $changelogOk = $sectionOk -or $unreleasedOk
    if ($sectionOk) { $changelogDetail = "section [$Version] found" }
    elseif ($unreleasedOk) { $changelogDetail = '[Unreleased] present (pre-tag OK)' }
    else { $changelogDetail = "missing [$Version] and [Unreleased]" }
}
$checks += (Write-ReleaseCheck -Name 'CHANGELOG entry (root)' -Ok $changelogOk -Detail $changelogDetail)
if (-not $changelogOk) { $allOk = $false }

if (-not $SkipGit) {
    if (-not (Test-Path (Join-Path $Root '.git'))) {
        $checks += (Write-ReleaseCheck -Name 'Git repository' -Ok $false -Detail '.git not found')
        $allOk = $false
    }
    else {
        $tagName = "v$Version"
        $tagList = git -C $Root tag -l $tagName 2>$null
        $tagExists = ($tagList -eq $tagName)
        $checks += (Write-ReleaseCheck -Name 'Git tag exists' -Ok $tagExists -Detail $tagName)
        if (-not $tagExists) { $allOk = $false }

        if ($RequireTagAtHead) {
            $headTag = git -C $Root describe --tags --exact-match HEAD 2>$null
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
Write-Host 'Fix psd1, install.ps1 pin, CHANGELOG.md, or Git tag before release.' -ForegroundColor Yellow
exit 1
