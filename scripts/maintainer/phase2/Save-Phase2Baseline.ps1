#Requires -Version 7.0
<#
.SYNOPSIS
    Capture Phase 2 baseline snapshot from runtime reports (non-destructive).
.PARAMETER StableLabel
    When set (e.g. Phase2-Step1-Stable), writes canonical baseline to Logs + docs/baselines/.
#>
[CmdletBinding()]
param(
    [string]$OutputPath,
    [string]$StableLabel,
    [string]$Phase = '2-step1',
    [string]$ProductTag = '2.0.0'
)

. (Join-Path $PSScriptRoot '..\_Resolve-RepoRoot.ps1')
$repoRoot = Resolve-WorkstationRepoRoot -Start $PSScriptRoot

$ErrorActionPreference = 'Stop'
$wsRoot = 'C:\Scripts\Workstation'
$logDir = 'C:\Logs\Workstation'

if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Force -Path $logDir | Out-Null }

if ($StableLabel) {
    $slug = ($StableLabel -replace '\s+', '-').ToLowerInvariant()
    $OutputPath = Join-Path $logDir "$slug.json"
    $Phase = $StableLabel
}

if (-not $OutputPath) {
    $OutputPath = Join-Path $logDir ("phase2-baseline-{0}.json" -f (Get-Date -Format 'yyyyMMdd-HHmmss'))
}

. (Join-Path $wsRoot 'lib\HomeBasePaths.ps1')
$foldersLib = Join-Path $wsRoot 'lib\WorkstationFolders.ps1'
if (Test-Path $foldersLib) { . $foldersLib }

$folders = Get-WorkstationStandardFolders
$configPath = Get-HomeBaseConfigPath
$config = Get-HomeBaseConfig

$gitHead = $null
if (Test-Path (Join-Path $wsRoot '.git')) {
    $gitHead = (git -C $wsRoot rev-parse --short HEAD 2>$null)
}

$trust = $null
$trustPath = Join-Path $logDir 'trust-report.json'
if (Test-Path $trustPath) {
    $trust = Get-Content $trustPath -Raw | ConvertFrom-Json
}

$health = $null
$healthPath = Join-Path $logDir 'command-health.json'
if (Test-Path $healthPath) {
    $health = Get-Content $healthPath -Raw | ConvertFrom-Json
}

$validation = Get-ChildItem $logDir -Filter 'validation-*.json' -ErrorAction SilentlyContinue |
    Sort-Object LastWriteTime -Descending | Select-Object -First 1

$valSummary = $null
$passCount = 0
$failCount = 0
$warnCount = 0
if ($validation) {
    $v = Get-Content $validation.FullName -Raw | ConvertFrom-Json
    if ($v.Metrics) {
        $passCount = [int]$v.Metrics.PassCount
        $failCount = [int]$v.Metrics.FailCount
        $warnCount = [int]$v.Metrics.WarnCount
    } else {
        $passCount = if ($v.Passed -is [array]) { $v.Passed.Count } else { [int]$v.Passed }
        $failCount = if ($v.Failed -is [array]) { $v.Failed.Count } else { [int]$v.Failed }
        $warnCount = if ($v.Warnings -is [array]) { $v.Warnings.Count } else { [int]$v.Warnings }
    }
    $valSummary = [ordered]@{
        File     = $validation.Name
        Passed   = $passCount
        Failed   = $failCount
        Warnings = $warnCount
    }
}

$pathSsot = [ordered]@{
    ConfigFile    = $configPath
    SchemaVersion = $config.SchemaVersion
    RuntimeRoot   = Get-HomeBasePath -Name RuntimeRoot
    Logs          = Get-HomeBasePath -Name Logs
    Backups       = Get-HomeBasePath -Name Backups
    Configs       = Get-HomeBasePath -Name Configs
    LegacyJunctions = @($config.LegacyJunctions).Count
}

$baseline = [ordered]@{
    Label          = if ($StableLabel) { $StableLabel } else { $null }
    Timestamp      = (Get-Date).ToString('o')
    Phase          = $Phase
    ProductTag     = "v$ProductTag"
    GitCommit      = $gitHead
    PowerShell     = $PSVersionTable.PSVersion.ToString()
    PathSsot       = $pathSsot
    Trust          = if ($trust) {
        [ordered]@{
            Level             = $trust.Level
            Score             = $trust.Score
            CanTrustDashboard = $trust.CanTrustDashboard
            SelfChecksPassed  = $trust.SelfChecksPassed
            SelfChecksTotal   = $trust.SelfChecksTotal
        }
    } else { $null }
    CommandHealth  = if ($health) {
        [ordered]@{
            Total           = $health.TotalCommands
            Broken          = $health.Broken
            ExecuteFailures = $health.ExecuteFailures
        }
    } else { $null }
    Validation     = $valSummary
    Paths          = $folders
    BackupLatest   = (Get-ChildItem (Get-HomeBasePath -Name Backups) -Directory -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -notmatch '^_' } |
        Sort-Object LastWriteTime -Descending | Select-Object -First 1 -ExpandProperty Name)
    QualityGates   = [ordered]@{
        DoctorPass      = ($valSummary -and $valSummary.Failed -eq 0 -and $valSummary.Passed -ge 75)
        TrustVerified   = ($trust -and $trust.Level -eq 'VERIFIED' -and $trust.Score -eq 100)
        CommandsHealthy = ($health -and $health.Broken -eq 0 -and $health.ExecuteFailures -eq 0)
    }
}

$baseline | ConvertTo-Json -Depth 8 | Set-Content -Path $OutputPath -Encoding UTF8
Write-Host "Phase 2 baseline saved: $OutputPath" -ForegroundColor Green

if ($StableLabel) {
    $repoBaselineDir = Join-Path $wsRoot 'docs\baselines'
    if (-not (Test-Path $repoBaselineDir)) {
        New-Item -ItemType Directory -Force -Path $repoBaselineDir | Out-Null
    }
    $repoCopy = Join-Path $repoBaselineDir "$slug.json"
    Copy-Item -Path $OutputPath -Destination $repoCopy -Force
    Write-Host "Stable baseline copy: $repoCopy" -ForegroundColor Green
}

if (-not $baseline.QualityGates.TrustVerified) {
    Write-Warning 'Trust not VERIFIED — run doctor, Test-WorkstationCommands -Quick, Get-SystemTrustReport -Live -Save'
    exit 1
}
if (-not $baseline.QualityGates.DoctorPass) {
    Write-Warning 'Doctor baseline not PASS — run doctor first'
    exit 1
}
exit 0
