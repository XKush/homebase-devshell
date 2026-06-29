#Requires -Version 7.0
<#
.SYNOPSIS
    Scan repository for legacy HOME BASE path literals and classify by layer/category.
.PARAMETER SaveJson
    Write report JSON under Logs/Phase2/legacy-path-report.json
#>
[CmdletBinding()]
param(
    [switch]$SaveJson
)

. (Join-Path $PSScriptRoot '..\_Resolve-RepoRoot.ps1')
$repoRoot = Resolve-WorkstationRepoRoot -Start $PSScriptRoot

$ErrorActionPreference = 'Stop'
$wsRoot = $repoRoot
$pathsLib = Join-Path $wsRoot 'lib\HomeBasePaths.ps1'
if (Test-Path $pathsLib) { . $pathsLib }

$patterns = [ordered]@{
    ScriptsWorkstation = 'C:\\Scripts\\Workstation'
    LogsWorkstation    = 'C:\\Logs\\Workstation'
    BackupsWorkstation = 'C:\\Backups\\Workstation'
    ConfigsWorkstation = 'C:\\Configs\\Workstation'
}

$fallbackRelPaths = @(
    'lib\WorkstationCommon.ps1'
    'lib\WorkstationFolders.ps1'
    'lib\WorkstationOperationsCenter.ps1'
    'lib\WorkstationDashboard.ps1'
    'lib\WorkstationToolkit.ps1'
    'modules\Private\Common.ps1'
)

$gateTestRelPaths = @(
    'Test-HomeBasePaths.ps1'
    'Test-LegacyEquivalence.ps1'
    'Test-RestoreRehearsal.ps1'
    'Save-Phase2Baseline.ps1'
    'Invoke-Phase2CommitGate.ps1'
    'Invoke-Phase2Step1Baseline.ps1'
    'Test-WorkstationCommands.ps1'
    'Invoke-AcceptanceTest.ps1'
)

function Get-RelativeRepoPath {
    param([string]$FullPath)
    return [System.IO.Path]::GetRelativePath($wsRoot, $FullPath) -replace '\\', '/'
}

function Get-Phase2FileLayer {
    param([string]$RelPath)

    if ($RelPath -match '^docs/') { return 'Documentation' }
    if ($RelPath -match '\.md$') { return 'Documentation' }
    if ($RelPath -match '^Config/homebase\.defaults\.json$') { return 'SSOT-Definition' }
    if ($RelPath -match '^lib/HomeBasePaths\.ps1$') { return 'SSOT-Definition' }

    $winRel = $RelPath -replace '/', '\'
    if ($gateTestRelPaths -contains $winRel) { return 'Tests-Gates' }
    if ($RelPath -match '^Test-' -or $RelPath -match '/Test-') { return 'Tests-Gates' }

    if ($fallbackRelPaths -contains $winRel) { return 'Legacy-Fallback' }

    return 'Runtime-Code'
}

function Get-Phase2FileCategory {
    param(
        [string]$RelPath,
        [string]$Layer
    )

    switch ($Layer) {
        'Documentation' { return 'Documentation' }
        'SSOT-Definition' { return 'SSOT definition' }
        'Tests-Gates' { return 'Tests' }
        'Legacy-Fallback' { return 'Legacy fallback' }
    }

    if ($RelPath -match 'Audit|Validate-Workstation|LegacyEquivalence|Trust|trust|TerminalAudit|PostProduction|CommandCenterCI|AcceptanceTest|ScheduledTrust|EnhancementReports|FinalAudit|OrganizationAudit') {
        return 'Diagnostics'
    }
    if ($RelPath -match 'Maintenance|Housekeeping|Backup-Configuration|cleanup|cleanlogs|Repair-|Install-|Register-.*Task|Rollback|EnhancementPass|Fix-WorkstationPath') {
        return 'Maintenance'
    }

    return 'Runtime'
}

$scanGlobs = @('*.ps1', 'docs/**/*.md', 'Config/*.json', 'README.md')
$files = [System.Collections.Generic.List[string]]::new()
foreach ($g in $scanGlobs) {
    Get-ChildItem -Path (Join-Path $wsRoot $g) -File -Recurse -ErrorAction SilentlyContinue |
        Where-Object { $_.FullName -notmatch '\\\.git\\' } |
        ForEach-Object { $files.Add($_.FullName) }
}
$files = @($files | Sort-Object -Unique)

$byPattern = @{}
$byLayer = @{}
$byCategory = @{}
$fileHits = [System.Collections.Generic.List[object]]::new()
$totalLiterals = 0

foreach ($key in $patterns.Keys) {
    $byPattern[$key] = 0
}
foreach ($layer in @('Runtime-Code', 'Tests-Gates', 'Documentation', 'Legacy-Fallback', 'SSOT-Definition')) {
    $byLayer[$layer] = 0
}
foreach ($cat in @('Runtime', 'Diagnostics', 'Maintenance', 'Tests', 'Documentation', 'Legacy fallback', 'SSOT definition')) {
    $byCategory[$cat] = 0
}

foreach ($full in $files) {
    $rel = Get-RelativeRepoPath $full
    if ($rel -eq 'Get-Phase2LegacyPathReport.ps1') { continue }
    $layer = Get-Phase2FileLayer $rel
    $category = Get-Phase2FileCategory $rel $layer
    $lines = Get-Content -LiteralPath $full -ErrorAction SilentlyContinue
    if (-not $lines) { continue }

    $filePatternHits = [ordered]@{}
    foreach ($key in $patterns.Keys) { $filePatternHits[$key] = 0 }

    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]
        foreach ($key in $patterns.Keys) {
            $literal = switch ($key) {
                'ScriptsWorkstation' { 'C:\Scripts\Workstation' }
                'LogsWorkstation' { 'C:\Logs\Workstation' }
                'BackupsWorkstation' { 'C:\Backups\Workstation' }
                'ConfigsWorkstation' { 'C:\Configs\Workstation' }
            }
            $n = ([regex]::Matches($line, [regex]::Escape($literal))).Count
            if ($n -le 0) { continue }
            $byPattern[$key] += $n
            $filePatternHits[$key] += $n
            $byLayer[$layer] += $n
            $byCategory[$category] += $n
            $totalLiterals += $n
        }
    }

    $fileTotal = ($filePatternHits.Values | Measure-Object -Sum).Sum
    if ($fileTotal -gt 0) {
        $fileHits.Add([ordered]@{
            File     = $rel
            Layer    = $layer
            Category = $category
            Hits     = $filePatternHits
            Total    = $fileTotal
        })
    }
}

$runtimeLiterals = $byLayer['Runtime-Code']
$report = [ordered]@{
    Timestamp       = (Get-Date).ToString('o')
    RepositoryRoot  = $wsRoot
    ScannedFiles    = $files.Count
    TotalLiterals   = $totalLiterals
    ByPattern       = $byPattern
    ByLayer         = $byLayer
    ByCategory      = $byCategory
    RuntimeLiterals = $runtimeLiterals
    FilesWithHits   = $fileHits.Count
    TopFiles        = @($fileHits | Sort-Object { $_.Total } -Descending | Select-Object -First 15)
}

Write-Host ''
Write-Host '=== Phase 2 Legacy Path Report ===' -ForegroundColor Cyan
Write-Host "Scanned: $($files.Count) files | Total literals: $totalLiterals | Runtime-code literals: $runtimeLiterals"
Write-Host ''
Write-Host 'By path pattern:' -ForegroundColor Yellow
foreach ($key in $patterns.Keys) {
    Write-Host ('  {0,-22} {1,4}' -f $key, $byPattern[$key])
}
Write-Host ''
Write-Host 'By layer:' -ForegroundColor Yellow
foreach ($key in $byLayer.Keys) {
    Write-Host ('  {0,-22} {1,4}' -f $key, $byLayer[$key])
}
Write-Host ''
Write-Host 'By category:' -ForegroundColor Yellow
foreach ($key in $byCategory.Keys) {
    Write-Host ('  {0,-22} {1,4}' -f $key, $byCategory[$key])
}
Write-Host ''
Write-Host 'Top files (runtime-code only):' -ForegroundColor Yellow
$fileHits | Where-Object { $_.Layer -eq 'Runtime-Code' } | Sort-Object { $_.Total } -Descending | Select-Object -First 10 |
    ForEach-Object { Write-Host ('  {0,3}  {1}' -f $_.Total, $_.File) }

if ($SaveJson) {
    $outDir = if (Get-Command Get-HomeBasePath -ErrorAction SilentlyContinue) {
        Join-Path (Get-HomeBasePath -Name Logs) 'Phase2'
    } else {
        Join-Path $wsRoot 'docs\baselines'
    }
    if (-not (Test-Path $outDir)) { New-Item -ItemType Directory -Force -Path $outDir | Out-Null }
    $outPath = Join-Path $outDir 'legacy-path-report.json'
    $report | ConvertTo-Json -Depth 6 | Set-Content $outPath -Encoding UTF8
    Write-Host ''
    Write-Host "Report saved: $outPath" -ForegroundColor DarkGray
}

return $report
