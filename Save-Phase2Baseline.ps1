#Requires -Version 7.0
<#
.SYNOPSIS
    Capture Phase 2 baseline snapshot from runtime reports (non-destructive).
#>
[CmdletBinding()]
param(
    [string]$OutputPath
)

$ErrorActionPreference = 'Stop'
$wsRoot = 'C:\Scripts\Workstation'
$logDir = 'C:\Logs\Workstation'

if (-not $OutputPath) {
    if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Force -Path $logDir | Out-Null }
    $OutputPath = Join-Path $logDir ("phase2-baseline-{0}.json" -f (Get-Date -Format 'yyyyMMdd-HHmmss'))
}

$folders = [ordered]@{
    Logs = 'C:\Logs\Workstation'; Backups = 'C:\Backups\Workstation'
}
$foldersLib = Join-Path $wsRoot 'lib\WorkstationFolders.ps1'
if (Test-Path $foldersLib) {
    . $foldersLib
    if (Get-Command Get-WorkstationStandardFolders -ErrorAction SilentlyContinue) {
        $folders = Get-WorkstationStandardFolders
    }
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
if ($validation) {
    $v = Get-Content $validation.FullName -Raw | ConvertFrom-Json
    $valSummary = [ordered]@{
        File     = $validation.Name
        Passed   = $v.Passed
        Failed   = $v.Failed
        Warnings = $v.Warnings
    }
}

$baseline = [ordered]@{
    Timestamp      = (Get-Date).ToString('o')
    Phase          = '2-pre'
    ProductTag     = 'v2.0.0'
    PowerShell     = $PSVersionTable.PSVersion.ToString()
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
            Total           = $health.Total
            Broken          = $health.Broken
            ExecuteFailures = $health.ExecuteFailures
        }
    } else { $null }
    Validation     = $valSummary
    Paths          = $folders
    BackupLatest   = (Get-ChildItem 'C:\Backups\Workstation' -Directory -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -notmatch '^_' } |
        Sort-Object LastWriteTime -Descending | Select-Object -First 1 -ExpandProperty Name)
    QualityGates   = [ordered]@{
        DoctorPass       = ($valSummary -and $valSummary.Failed -eq 0 -and $valSummary.Passed -ge 75)
        TrustVerified    = ($trust -and $trust.Level -eq 'VERIFIED' -and $trust.Score -eq 100)
        CommandsHealthy  = ($health -and $health.Broken -eq 0 -and $health.ExecuteFailures -eq 0)
    }
}

$baseline | ConvertTo-Json -Depth 6 | Set-Content -Path $OutputPath -Encoding UTF8
Write-Host "Phase 2 baseline saved: $OutputPath" -ForegroundColor Green
if (-not $baseline.QualityGates.TrustVerified) {
    Write-Warning 'Trust not VERIFIED — run Test-WorkstationCommands -Quick then Get-SystemTrustReport -Live -Save'
    exit 1
}
exit 0
