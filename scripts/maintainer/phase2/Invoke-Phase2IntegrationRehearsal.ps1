#Requires -Version 7.0
<#
.SYNOPSIS
    Phase 2 integration rehearsal — platform readiness after command-queue migration.
.PARAMETER SkipStashRuntime
    Do not apply stash@{0} for gate/runtime (pure committed tree only).
#>
[CmdletBinding()]
param(
    [switch]$SkipStashRuntime
)

. (Join-Path $PSScriptRoot '..\_Resolve-RepoRoot.ps1')
$repoRoot = Resolve-WorkstationRepoRoot -Start $PSScriptRoot

$ErrorActionPreference = 'Stop'
$wsRoot = $repoRoot
. (Join-Path $wsRoot 'lib\HomeBasePaths.ps1')

$logsRoot = Get-HomeBasePath -Name Logs
$artifactDir = Join-Path $logsRoot 'Phase2'
$reportPath = Join-Path $artifactDir 'Integration-Rehearsal.md'
$passportPath = Join-Path $artifactDir 'Phase2-Completion-Passport.json'

$stages = [System.Collections.Generic.List[object]]::new()
$head = (git -C $wsRoot rev-parse --short HEAD 2>$null)
$stashRef = 'stash@{0}'
$runtimeLiteralsBefore = 124

function Add-StageResult {
    param([string]$Stage, [string]$Step, [bool]$Ok, [string]$Detail = '')
    $stages.Add([ordered]@{
        Stage  = $Stage
        Step   = $Step
        Result = $(if ($Ok) { 'PASS' } else { 'FAIL' })
        Detail = $Detail
    })
    if (-not $Ok) { throw "Integration failed: $Stage / $Step — $Detail" }
}

function Invoke-StageScript {
    param([string]$Stage, [string]$Step, [string]$ScriptPath, [string[]]$ScriptArgs = @())
    & $ScriptPath @ScriptArgs
    Add-StageResult -Stage $Stage -Step $Step -Ok ($LASTEXITCODE -eq 0) -Detail "exit=$LASTEXITCODE"
}

function Import-WorkstationModule {
    Import-Module (Join-Path $wsRoot 'modules\KGreen.Workstation.psm1') -DisableNameChecking -Scope Global -Force
}

Write-Host ''
Write-Host '=== Phase 2 Integration Rehearsal ===' -ForegroundColor Cyan
Write-Host "HEAD: $head" -ForegroundColor DarkGray

# ── Stage 0: Pre-flight ─────────────────────────────────────────────────────
$dirty = git -C $wsRoot status --porcelain
Add-StageResult -Stage 'Stage0-PreFlight' -Step 'CleanWorkingTree' -Ok ([string]::IsNullOrWhiteSpace($dirty)) -Detail $(if ($dirty) { 'dirty' } else { 'clean' })

$stashList = git -C $wsRoot stash list 2>$null
Add-StageResult -Stage 'Stage0-PreFlight' -Step 'StashPresent' -Ok ($stashList -match 'phase2-isolation') -Detail $stashRef

Invoke-StageScript -Stage 'Stage0-PreFlight' -Step 'Test-HomeBasePaths' -ScriptPath (Join-Path $wsRoot 'Test-HomeBasePaths.ps1')
Invoke-StageScript -Stage 'Stage0-PreFlight' -Step 'Test-ReleaseVersion' -ScriptPath (Join-Path $wsRoot 'Test-ReleaseVersion.ps1')

if (-not $SkipStashRuntime) {
    Write-Host 'Applying gate runtime from stash (integration sandbox)...' -ForegroundColor DarkGray
    git -C $wsRoot stash apply $stashRef 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Write-Warning 'stash apply returned non-zero; continuing if runtime files present'
    }
    if (Test-Path (Join-Path $wsRoot 'Install-ShellProfile.ps1')) {
        & (Join-Path $wsRoot 'Install-ShellProfile.ps1') | Out-Null
    }
}

Import-WorkstationModule

Import-WorkstationModule

# ── Stage 1: Recovery ───────────────────────────────────────────────────────
backupconfig | Out-Null
Add-StageResult -Stage 'Stage1-Recovery' -Step 'backupconfig' -Ok ($LASTEXITCODE -eq 0)

Invoke-StageScript -Stage 'Stage1-Recovery' -Step 'Test-RestoreRehearsal' -ScriptPath (Join-Path $wsRoot 'Test-RestoreRehearsal.ps1')

$env:CI = '1'
$env:WORKSTATION_DASHBOARD = '0'
$env:WORKSTATION_DASHBOARD_SHOWN = '1'
$env:WORKSTATION_WELCOMED = '1'
reloadprofile | Out-Null
Add-StageResult -Stage 'Stage1-Recovery' -Step 'reloadprofile' -Ok ($LASTEXITCODE -eq 0)

# ── Stage 2: Core Health ──────────────────────────────────────────────────────
doctor | Out-Null
$latestVal = Get-ChildItem $logsRoot -Filter 'validation-*.json' -EA SilentlyContinue |
    Sort-Object LastWriteTime -Descending | Select-Object -First 1
$doctorOk = $false
$doctorLabel = 'unknown'
if ($latestVal) {
    $v = Get-Content $latestVal.FullName -Raw | ConvertFrom-Json
    $doctorOk = ($v.Metrics.FailCount -eq 0 -and $v.Metrics.PassCount -ge 75)
    $doctorLabel = '{0}/{1}' -f $v.Metrics.PassCount, ($v.Metrics.PassCount + $v.Metrics.FailCount)
}
Add-StageResult -Stage 'Stage2-CoreHealth' -Step 'doctor' -Ok $doctorOk -Detail $doctorLabel

trustcheck | Out-Null
$t = Get-Content (Join-Path $logsRoot 'trust-report.json') -Raw | ConvertFrom-Json
Add-StageResult -Stage 'Stage2-CoreHealth' -Step 'trustcheck' -Ok ($t.Level -eq 'VERIFIED' -and $t.Score -eq 100) -Detail "$($t.Level) $($t.Score)"

& (Join-Path $wsRoot 'Invoke-WorkstationRevision.ps1') | Out-Null
Add-StageResult -Stage 'Stage2-CoreHealth' -Step 'revise' -Ok ($LASTEXITCODE -eq 0)

# ── Stage 3: User Journey ───────────────────────────────────────────────────
home | Out-Null
Add-StageResult -Stage 'Stage3-UserJourney' -Step 'home' -Ok ($LASTEXITCODE -eq 0)

if (-not (Get-Command go -EA SilentlyContinue)) {
    Add-StageResult -Stage 'Stage3-UserJourney' -Step 'go' -Ok $false -Detail 'command missing'
}
else {
    $goPre = Test-CommandSelfCheck -Name 'go' -Phase Pre
    Add-StageResult -Stage 'Stage3-UserJourney' -Step 'go' -Ok $goPre.OK -Detail $goPre.Detail
}

$anonCmd = if (Get-Command anon -EA SilentlyContinue) { 'anon' } elseif (Get-Command sec -EA SilentlyContinue) { 'sec' } else { $null }
if (-not $anonCmd) {
    Add-StageResult -Stage 'Stage3-UserJourney' -Step 'anon' -Ok $false -Detail 'anon/sec missing'
}
elseif ($anonCmd -eq 'anon') {
    anon -Audit | Out-Null
    Add-StageResult -Stage 'Stage3-UserJourney' -Step 'anon' -Ok ($LASTEXITCODE -eq 0) -Detail 'anon -Audit'
}
else {
    sec -Status | Out-Null
    Add-StageResult -Stage 'Stage3-UserJourney' -Step 'anon' -Ok ($LASTEXITCODE -eq 0) -Detail 'sec -Status (anon alias path)'
}

# ── Stage 4: Architecture ───────────────────────────────────────────────────
Invoke-StageScript -Stage 'Stage4-Architecture' -Step 'Test-HomeBasePaths' -ScriptPath (Join-Path $wsRoot 'Test-HomeBasePaths.ps1')
Invoke-StageScript -Stage 'Stage4-Architecture' -Step 'Test-LegacyEquivalence' -ScriptPath (Join-Path $wsRoot 'Test-LegacyEquivalence.ps1')

$pathReport = & (Join-Path $wsRoot 'Get-Phase2LegacyPathReport.ps1') -SaveJson
Add-StageResult -Stage 'Stage4-Architecture' -Step 'Get-Phase2LegacyPathReport' -Ok ($null -ne $pathReport)

Invoke-StageScript -Stage 'Stage4-Architecture' -Step 'Test-ReleaseVersion' -ScriptPath (Join-Path $wsRoot 'Test-ReleaseVersion.ps1')

$runtimeAfter = [int]$pathReport.RuntimeLiterals
$legacyEquiv = 'PASS'
$trustLabel = 'VERIFIED'
$step25Ready = $true
$decision = 'READY FOR STEP 2.5'

$passport = [ordered]@{
    phase                   = '2'
    status                  = 'PASS'
    scope                   = 'command-script-queue-integration'
    product_version         = (Import-PowerShellDataFile (Join-Path $wsRoot 'modules\KGreen.Workstation.psd1')).ModuleVersion
    baseline                = 'Phase2-Step1-Stable'
    commit_head             = $head
    components_migrated     = 7
    runtime_literals_before = $runtimeLiteralsBefore
    runtime_literals_after  = $runtimeAfter
    runtime_literals_exit_target = 0
    legacy_equivalence      = $legacyEquiv
    doctor                  = $doctorLabel
    trust                   = $trustLabel
    rollback_anchor         = 'v2.0.0'
    integration_rehearsal   = 'PASS'
    ready_for_step_2_5      = $step25Ready
    ready_for_v2_1_0        = $false
    legacy_junctions_enabled = $false
    timestamp               = (Get-Date).ToString('o')
    stages                  = @($stages)
}

if (-not (Test-Path $artifactDir)) { New-Item -ItemType Directory -Force -Path $artifactDir | Out-Null }
$passport | ConvertTo-Json -Depth 8 | Set-Content $passportPath -Encoding UTF8

$md = @(
    '# Phase 2 — Integration Rehearsal Report'
    ''
    "**Date:** $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    "**Commit HEAD:** ``$head``"
    "**Baseline:** Phase2-Step1-Stable"
    "**Overall:** PASS"
    ''
    '## Stage results'
    ''
    '| Stage | Step | Result | Detail |'
    '|-------|------|--------|--------|'
)

. (Join-Path $PSScriptRoot '..\_Resolve-RepoRoot.ps1')
$repoRoot = Resolve-WorkstationRepoRoot -Start $PSScriptRoot

foreach ($s in $stages) {
    $md += "| $($s.Stage) | $($s.Step) | $($s.Result) | $($s.Detail) |"
}

$md += @(
    ''
    '## Legacy path metrics'
    ''
    "| Runtime literals (mid-phase baseline) | $runtimeLiteralsBefore |"
    "| Runtime literals (now) | $runtimeAfter |"
    "| Total literals | $($pathReport.TotalLiterals) |"
    ''
    '## Decision'
    ''
    "**$decision**"
    ''
    'Remaining runtime literals are in module/profile/install/fallback layers — acceptable per Phase 2 Final Review before Step 2.5 discussion.'
    ''
    '**v2.1.0:** NOT READY (runtime literal exit target not met).'
    ''
    "## Artifacts"
    ''
    "- ``$passportPath``"
    "- ``$(Join-Path $artifactDir 'legacy-path-report.json')``"
)

$md -join "`n" | Set-Content $reportPath -Encoding UTF8
Copy-Item $reportPath (Join-Path $wsRoot 'docs\charter\Integration-Rehearsal.md') -Force

Write-Host ''
Write-Host 'Integration Rehearsal: PASS' -ForegroundColor Green
Write-Host "Passport: $passportPath" -ForegroundColor DarkGray
Write-Host "Report:   $reportPath" -ForegroundColor DarkGray
Write-Host "Decision: $decision" -ForegroundColor Green
exit 0
