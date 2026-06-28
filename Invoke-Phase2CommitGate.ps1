#Requires -Version 7.0
<#
.SYNOPSIS
    Mandatory Phase 2 commit gate pipeline (run before every Step 2 commit).
.DESCRIPTION
    Commit is forbidden if this script returns non-zero.
    With -SaveArtifacts, writes quality passport under Logs/Phase2/Commit/.
.PARAMETER SaveArtifacts
    Save doctor/trust/paths/equivalence JSON under Logs/Phase2/Commit/{folder}/.
.PARAMETER FinalizePendingArtifacts
    After git commit, rename latest *-pending artifact folder to current HEAD short hash.
#>
[CmdletBinding()]
param(
    [switch]$SaveArtifacts,
    [switch]$FinalizePendingArtifacts
)

$ErrorActionPreference = 'Stop'
$wsRoot = $PSScriptRoot
. (Join-Path $wsRoot 'lib\HomeBasePaths.ps1')

$logsRoot = Get-HomeBasePath -Name Logs
$artifactRoot = Join-Path $logsRoot 'Phase2\Commit'

function Get-GitShortHead {
    if (-not (Test-Path (Join-Path $wsRoot '.git'))) { return 'nogit' }
    return (git -C $wsRoot rev-parse --short HEAD 2>$null)
}

function Save-Phase2GateArtifacts {
    param([string]$FolderName)

    $dir = Join-Path $artifactRoot $FolderName
    New-Item -ItemType Directory -Force -Path $dir | Out-Null

    $latestVal = Get-ChildItem $logsRoot -Filter 'validation-*.json' -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if ($latestVal) {
        Copy-Item $latestVal.FullName (Join-Path $dir 'doctor.json') -Force
    }

    $trustPath = Join-Path $logsRoot 'trust-report.json'
    if (Test-Path $trustPath) {
        Copy-Item $trustPath (Join-Path $dir 'trust.json') -Force
    }

    $pathNames = @('Logs', 'Backups', 'Configs', 'Projects', 'Tools', 'Scripts', 'RepositoryRoot', 'RuntimeRoot')
    $pathsObj = [ordered]@{}
    foreach ($n in $pathNames) {
        $pathsObj[$n] = Get-HomeBasePath -Name $n
    }
    $pathsObj | ConvertTo-Json -Depth 4 | Set-Content (Join-Path $dir 'paths.json') -Encoding UTF8

    $equiv = [ordered]@{
        Timestamp   = (Get-Date).ToString('o')
        ParentHead  = Get-GitShortHead
        Folder      = $FolderName
        LegacyJunctions = @((Get-HomeBaseConfig).LegacyJunctions).Count
        Baseline    = 'docs/baselines/phase2-step1-stable.json'
        GateScript  = 'Test-LegacyEquivalence.ps1'
        Result      = 'PASS'
    }
    $equiv | ConvertTo-Json -Depth 4 | Set-Content (Join-Path $dir 'equivalence.json') -Encoding UTF8

    [ordered]@{
        Timestamp  = (Get-Date).ToString('o')
        ParentHead = Get-GitShortHead
        Folder     = $FolderName
        Files      = @('doctor.json', 'trust.json', 'paths.json', 'equivalence.json')
    } | ConvertTo-Json | Set-Content (Join-Path $dir 'manifest.json') -Encoding UTF8

    Write-Host "Artifacts saved: $dir" -ForegroundColor DarkGray
    return $dir
}

if ($FinalizePendingArtifacts) {
    $pending = Get-ChildItem $artifactRoot -Directory -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -like '*-pending' } |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1
    if (-not $pending) {
        Write-Warning 'No pending artifact folder to finalize'
        exit 0
    }
    $newHash = Get-GitShortHead
    $dest = Join-Path $artifactRoot $newHash
    if (Test-Path $dest) {
        Write-Warning "Artifact folder already exists: $dest"
        exit 1
    }
    Move-Item $pending.FullName $dest
    $manifestPath = Join-Path $dest 'manifest.json'
    if (Test-Path $manifestPath) {
        $m = Get-Content $manifestPath -Raw | ConvertFrom-Json
        $m | Add-Member -NotePropertyName CommitHash -NotePropertyValue $newHash -Force
        $m | Add-Member -NotePropertyName Finalized -NotePropertyValue ((Get-Date).ToString('o')) -Force
        $m | ConvertTo-Json | Set-Content $manifestPath -Encoding UTF8
    }
    Write-Host "Artifacts finalized: $dest" -ForegroundColor Green
    exit 0
}

function Invoke-Gate {
    param([string]$Name, [scriptblock]$Action)
    Write-Host "=== $Name ===" -ForegroundColor Cyan
    & $Action
    if ($LASTEXITCODE -and $LASTEXITCODE -ne 0) {
        throw "Gate failed: $Name (exit $LASTEXITCODE)"
    }
}

Import-Module (Join-Path $wsRoot 'modules\KGreen.Workstation.psm1') -DisableNameChecking -Scope Global -Force

Invoke-Gate 'backupconfig' { backupconfig }
Invoke-Gate 'Test-HomeBasePaths' { & (Join-Path $wsRoot 'Test-HomeBasePaths.ps1') }
Invoke-Gate 'Test-LegacyEquivalence' { & (Join-Path $wsRoot 'Test-LegacyEquivalence.ps1') }
Invoke-Gate 'doctor' { doctor | Out-Null }
Invoke-Gate 'Test-WorkstationCommands -Quick' { & (Join-Path $wsRoot 'Test-WorkstationCommands.ps1') -Quick | Out-Null }
Invoke-Gate 'trustcheck' {
    Get-SystemTrustReport -Live -Save | Out-Null
    trustcheck | Out-Null
    $t = Get-Content (Join-Path $logsRoot 'trust-report.json') -Raw | ConvertFrom-Json
    if ($t.Level -ne 'VERIFIED' -or $t.Score -ne 100) {
        throw "Trust not VERIFIED 100: $($t.Level) $($t.Score)"
    }
}
Invoke-Gate 'Test-ReleaseVersion' { & (Join-Path $wsRoot 'Test-ReleaseVersion.ps1') }

if ($SaveArtifacts) {
    if (-not (Test-Path $artifactRoot)) {
        New-Item -ItemType Directory -Force -Path $artifactRoot | Out-Null
    }
    $folder = "$(Get-GitShortHead)-pending"
    Save-Phase2GateArtifacts -FolderName $folder | Out-Null
}

Write-Host ''
Write-Host 'Phase 2 commit gate: ALL PASS — safe to commit' -ForegroundColor Green
exit 0
