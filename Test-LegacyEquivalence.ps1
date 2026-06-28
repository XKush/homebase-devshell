#Requires -Version 7.0
<#
.SYNOPSIS
    Confirm Path Abstraction changed internals only — user-visible behavior unchanged.
.DESCRIPTION
    Compares SSOT paths to legacy layout, verifies runtime file locations,
    and optionally compares trust/doctor metrics to a stable baseline JSON.
.PARAMETER BaselinePath
    Default: docs/baselines/phase2-step1-stable.json or Logs copy.
.EXAMPLE
    pwsh -File Test-LegacyEquivalence.ps1
.EXAMPLE
    pwsh -File Test-LegacyEquivalence.ps1 -BaselinePath C:\Logs\Workstation\phase2-step1-stable.json
#>
[CmdletBinding()]
param(
    [string]$BaselinePath,
    [switch]$SkipBaselineCompare
)

$ErrorActionPreference = 'Stop'
$wsRoot = $PSScriptRoot
$fail = 0

function Write-EquivCheck {
    param([string]$Name, [bool]$Ok, [string]$Detail = '')
    if (-not $Ok) { $script:fail++ }
    $icon = if ($Ok) { 'PASS' } else { 'FAIL' }
    $color = if ($Ok) { 'Green' } else { 'Red' }
    Write-Host ("[{0}] {1}" -f $icon, $Name) -ForegroundColor $color
    if ($Detail) { Write-Host "      $Detail" -ForegroundColor DarkGray }
}

. (Join-Path $wsRoot 'lib\HomeBasePaths.ps1')
$foldersLib = Join-Path $wsRoot 'lib\WorkstationFolders.ps1'
if (Test-Path $foldersLib) { . $foldersLib }

# ── 1. Legacy path equivalence (SSOT = current layout) ─────────────────────
$legacyExpected = [ordered]@{
    Logs     = 'C:\Logs\Workstation'
    Backups  = 'C:\Backups\Workstation'
    Configs  = 'C:\Configs\Workstation'
    Projects = 'C:\Projects'
    Tools    = 'C:\Tools'
    Scripts  = 'C:\Scripts'
}

foreach ($key in $legacyExpected.Keys) {
    $got = Get-HomeBasePath -Name $key
    $ok = ($got -eq $legacyExpected[$key])
    Write-EquivCheck -Name "Get-HomeBasePath.$key" -Ok $ok -Detail "$got"
}

$std = Get-WorkstationStandardFolders
foreach ($key in @('Logs', 'Backups', 'Configs')) {
    $ok = ($std[$key] -eq $legacyExpected[$key])
    Write-EquivCheck -Name "StandardFolders.$key" -Ok $ok -Detail $std[$key]
}

# ── 2. Junctions remain disabled until explicit migration ────────────────────
$cfg = Get-HomeBaseConfig
$junctionCount = @($cfg.LegacyJunctions).Count
Write-EquivCheck -Name 'LegacyJunctions empty (safe default)' -Ok ($junctionCount -eq 0) -Detail "count=$junctionCount"

# ── 3. Runtime files at expected locations ───────────────────────────────────
$runtimeChecks = @(
    @{ Name = 'trust-report.json'; Path = Join-Path (Get-HomeBasePath -Name Logs) 'trust-report.json' }
    @{ Name = 'command-health.json'; Path = Join-Path (Get-HomeBasePath -Name Logs) 'command-health.json' }
    @{ Name = 'commands.log'; Path = Join-Path (Get-HomeBasePath -Name Logs) 'commands.log' }
    @{ Name = 'homebase.defaults.json'; Path = (Get-HomeBaseConfigPath) }
)

foreach ($rc in $runtimeChecks) {
    $exists = Test-Path $rc.Path
    Write-EquivCheck -Name "Runtime file: $($rc.Name)" -Ok $exists -Detail $rc.Path
}

$latestVal = Get-ChildItem (Get-HomeBasePath -Name Logs) -Filter 'validation-*.json' -ErrorAction SilentlyContinue |
    Sort-Object LastWriteTime -Descending | Select-Object -First 1
Write-EquivCheck -Name 'Latest validation report exists' -Ok ([bool]$latestVal) -Detail $(if ($latestVal) { $latestVal.Name } else { 'none' })

# ── 4. Key status metrics (from reports, non-destructive) ─────────────────────
$trustPath = Join-Path (Get-HomeBasePath -Name Logs) 'trust-report.json'
$trust = if (Test-Path $trustPath) { Get-Content $trustPath -Raw | ConvertFrom-Json } else { $null }

Write-EquivCheck -Name 'Trust Level VERIFIED' -Ok ($trust -and $trust.Level -eq 'VERIFIED') -Detail $(if ($trust) { $trust.Level } else { 'missing' })
Write-EquivCheck -Name 'Trust Score 100' -Ok ($trust -and $trust.Score -eq 100) -Detail $(if ($trust) { [string]$trust.Score } else { 'missing' })
Write-EquivCheck -Name 'SelfCheck 72/72' -Ok ($trust -and $trust.SelfChecksPassed -eq 72 -and $trust.SelfChecksTotal -eq 72) `
    -Detail $(if ($trust) { "$($trust.SelfChecksPassed)/$($trust.SelfChecksTotal)" } else { 'missing' })

if ($latestVal) {
    $v = Get-Content $latestVal.FullName -Raw | ConvertFrom-Json
    if ($v.Metrics) {
        $pCount = [int]$v.Metrics.PassCount
        $fCount = [int]$v.Metrics.FailCount
    } else {
        $pCount = if ($v.Passed -is [array]) { $v.Passed.Count } else { [int]$v.Passed }
        $fCount = if ($v.Failed -is [array]) { $v.Failed.Count } else { [int]$v.Failed }
    }
    Write-EquivCheck -Name 'Doctor 75/75' -Ok ($fCount -eq 0 -and $pCount -ge 75) -Detail "Passed=$pCount Failed=$fCount"
}

# ── 5. Compare to stable baseline (optional) ────────────────────────────────
if (-not $SkipBaselineCompare) {
    if (-not $BaselinePath) {
        $candidates = @(
            (Join-Path $wsRoot 'docs\baselines\phase2-step1-stable.json')
            (Join-Path (Get-HomeBasePath -Name Logs) 'phase2-step1-stable.json')
        )
        $BaselinePath = $candidates | Where-Object { Test-Path $_ } | Select-Object -First 1
    }

    if ($BaselinePath -and (Test-Path $BaselinePath)) {
        $base = Get-Content $BaselinePath -Raw | ConvertFrom-Json
        Write-Host ''
        Write-Host "[BASELINE] $BaselinePath" -ForegroundColor Cyan

        if ($base.Trust -and $trust) {
            Write-EquivCheck -Name 'Baseline trust Level unchanged' -Ok ($trust.Level -eq $base.Trust.Level) `
                -Detail "now=$($trust.Level) base=$($base.Trust.Level)"
            Write-EquivCheck -Name 'Baseline trust Score unchanged' -Ok ($trust.Score -eq $base.Trust.Score) `
                -Detail "now=$($trust.Score) base=$($base.Trust.Score)"
        }

        foreach ($key in @('Logs', 'Backups', 'Configs')) {
            $nowPath = Get-HomeBasePath -Name $key
            $basePath = $base.PathSsot.$key
            if (-not $basePath) { $basePath = $base.Paths.$key }
            Write-EquivCheck -Name "Baseline path $key unchanged" -Ok ($nowPath -eq $basePath) `
                -Detail "now=$nowPath base=$basePath"
        }
    } else {
        Write-Host '[SKIP] No stable baseline file for compare — run Save-Phase2Baseline -StableLabel Phase2-Step1-Stable' -ForegroundColor Yellow
    }
}

Write-Host ''
if ($fail -gt 0) {
    Write-Host "Test-LegacyEquivalence: FAIL ($fail checks)" -ForegroundColor Red
    exit 1
}
Write-Host 'Test-LegacyEquivalence: PASS — external behavior equivalent to legacy layout' -ForegroundColor Green
exit 0
