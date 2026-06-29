#Requires -Version 7.0
<#
.SYNOPSIS
    Operational hardening runner for Wave A–D platform (scenarios, drift, load, contract).
.PARAMETER LoadIterations
    Repeated router dispatch count for execution-under-load check.
.PARAMETER SaveReport
    Write JSON report under Logs/Workstation.
#>
param(
    [int]$LoadIterations = 50,
    [switch]$SaveReport
)

$ErrorActionPreference = 'Stop'
$root = if ($env:WORKSTATION_ROOT) { $env:WORKSTATION_ROOT } else { 'C:\Scripts\Workstation' }

. (Join-Path $root 'lib\HomeBasePaths.ps1')

$report = [ordered]@{
    Timestamp = (Get-Date).ToString('o')
    Root      = $root
    Passed    = [System.Collections.Generic.List[string]]::new()
    Failed    = [System.Collections.Generic.List[string]]::new()
    Warnings  = [System.Collections.Generic.List[string]]::new()
    Metrics   = [ordered]@{}
}

function Add-Pass([string]$Name) { $report.Passed.Add($Name) | Out-Null }
function Add-Fail([string]$Name, [string]$Detail) { $report.Failed.Add("${Name}: $Detail") | Out-Null }
function Add-Warn([string]$Name, [string]$Detail) { $report.Warnings.Add("${Name}: $Detail") | Out-Null }

. (Join-Path $root 'lib\WorkstationCommon.ps1')
. (Join-Path $root 'lib\ProfileEnvironment.ps1')
. (Join-Path $root 'lib\WorkstationOrchestrator.ps1')
. (Join-Path $root 'lib\WorkstationCommandRegistry.ps1')
. (Join-Path $root 'lib\WorkstationCapabilityObservability.ps1')
. (Join-Path $root 'lib\WorkstationEventCore.ps1')
. (Join-Path $root 'lib\WorkstationPlatformContract.ps1')
. (Join-Path $root 'lib\WorkstationExecutionTrace.ps1')
. (Join-Path $root 'lib\WorkstationCommandRouter.ps1')
. (Join-Path $root 'lib\WorkstationCapabilityExtensions.ps1')
. (Join-Path $root 'lib\WorkstationExtensionEventBridge.ps1')
. (Join-Path $root 'lib\WorkstationExtensionRuntime.ps1')

function Get-EventSlice {
    param([int]$FromIndex, [string]$Layer = '')
    $slice = @($script:WorkstationEventBuffer | Select-Object -Skip $FromIndex)
    if ($Layer) { return @($slice | Where-Object { $_.Layer -eq $Layer }) }
    return $slice
}

# ── Scenario 1: Profile bootstrap + drift ─────────────────────────────────────
try {
    $canon = Join-Path $root 'profile\Microsoft.PowerShell_profile.ps1'
    $live  = Join-Path $env:USERPROFILE 'Documents\PowerShell\Microsoft.PowerShell_profile.ps1'
    if ((Test-Path $canon) -and (Test-Path $live)) {
        $canonHash = (Get-FileHash $canon).Hash
        $liveHash  = (Get-FileHash $live).Hash
        if ($canonHash -eq $liveHash) { Add-Pass 'profile.drift.canonical-live-match' }
        else { Add-Warn 'profile.drift.canonical-live-match' 'Run Install-ShellProfile.ps1 -Force' }
    } else {
        Add-Warn 'profile.drift.canonical-live-match' 'Canonical or live profile missing'
    }
} catch {
    Add-Fail 'profile.drift' $_.Exception.Message
}

$eventBase = $script:WorkstationEventBuffer.Count
Invoke-WorkstationProfile -RepositoryRoot $root -Force | Out-Null
$afterInit = $script:WorkstationEventBuffer.Count - $eventBase

try {
    if ($afterInit -ne 2) { throw "Expected 2 orchestrator events, got $afterInit" }
    Test-WorkstationEventBufferContract -FromIndex $eventBase | Out-Null
    Test-WorkstationEventLifecyclePairs -FromIndex $eventBase | Out-Null
    Add-Pass 'scenario.profile-init.lifecycle'
} catch {
    Add-Fail 'scenario.profile-init.lifecycle' $_.Exception.Message
}

# ── Scenario 2: Orchestrator idempotent (no duplicate events) ───────────────
$beforeCached = $script:WorkstationEventBuffer.Count
Invoke-WorkstationProfile -RepositoryRoot $root | Out-Null
$afterCached = $script:WorkstationEventBuffer.Count - $beforeCached
if ($afterCached -eq 0) { Add-Pass 'scenario.orchestrator.idempotent-no-events' }
else { Add-Fail 'scenario.orchestrator.idempotent-no-events' "Emitted $afterCached events on cached call" }

# ── Scenario 3: Core commands + module shadowing ────────────────────────────
Import-WorkstationProfileModule -Root $root | Out-Null
$coreKeys = @($script:WorkstationCommandRegistry.Keys | Sort-Object)
$expected = @('diag.boot', 'env.show', 'profile.reload')
if (($coreKeys -join ',') -ne ($expected -join ',')) {
    Add-Fail 'scenario.core-registry.keys' "Got: $($coreKeys -join ', ')"
} else {
    Add-Pass 'scenario.core-registry.keys'
}

$moduleCatalog = @(Get-WorkstationCommandRegistry)
if ($moduleCatalog.Count -eq $coreKeys.Count) {
    Add-Warn 'scenario.registry.shadowing' 'Module catalog same count as core — verify separation'
} else {
    Add-Pass 'scenario.registry.shadowing-separated'
}

$beforeRouter = $script:WorkstationEventBuffer.Count
foreach ($cmd in $expected) {
    $null = Invoke-WorkstationCommand -Name $cmd
}
$routerEvents = @(Get-EventSlice -FromIndex $beforeRouter -Layer 'Router').Count
try {
    if ($routerEvents -ne ($expected.Count * 2)) {
        throw "Expected $($expected.Count * 2) router lifecycle events, got $routerEvents"
    }
    Test-WorkstationEventBufferContract -FromIndex $beforeRouter | Out-Null
    Test-WorkstationEventLifecyclePairs -FromIndex $beforeRouter | Out-Null
    Add-Pass 'scenario.router.all-core-commands'
} catch {
    Add-Fail 'scenario.router.all-core-commands' $_.Exception.Message
}

# ── Scenario 4: Extension sandbox + ctx snapshot ────────────────────────────
$extName = 'hardening.probe'
if (-not (Get-WorkstationExtension -Name $extName)) {
    Register-WorkstationExtension -Name $extName -Version '1.0.0' -Capability 'system.tools.hardening' -EntryPoint {
        param($ctx)
        if ($ctx.Capabilities.Commands.Count -lt 3) { throw 'Core capabilities snapshot incomplete' }
        if (-not $ctx.Environment.Bootstrap) { throw 'Environment snapshot missing' }
        'probe-ok'
    } | Out-Null
}

$beforeExt = $script:WorkstationEventBuffer.Count
$result = Invoke-WorkstationExtension -Name $extName -Command 'probe' -Arguments @{ pass = 1 }
$extEvents = @(Get-EventSlice -FromIndex $beforeExt -Layer 'Handler').Count
try {
    if ($result -ne 'probe-ok') { throw 'Unexpected extension result' }
    if ($extEvents -ne 2) { throw "Expected 2 extension events, got $extEvents" }
    Test-WorkstationEventLifecyclePairs -FromIndex $beforeExt | Out-Null
    Add-Pass 'scenario.extension.sandbox'
} catch {
    Add-Fail 'scenario.extension.sandbox' $_.Exception.Message
}

$beforeNotFound = $script:WorkstationEventBuffer.Count
$nf = Invoke-WorkstationExtension -Name 'missing.extension'
$nfEvents = $script:WorkstationEventBuffer.Count - $beforeNotFound
if ($nf.Status -eq 'NotFound' -and $nfEvents -eq 0) { Add-Pass 'scenario.extension.notfound-no-events' }
else { Add-Fail 'scenario.extension.notfound-no-events' "Status=$($nf.Status) events=$nfEvents" }

# ── Scenario 5: Trace correlation ─────────────────────────────────────────────
try {
    $trace = Get-WorkstationExecutionTrace
    if ($trace.Count -ne $script:WorkstationEventBuffer.Count) {
        throw "Trace rows $($trace.Count) != events $($script:WorkstationEventBuffer.Count)"
    }
    $envTrace = @($trace | Where-Object { $_.Command -eq 'env.show' -and $_.Capability -eq 'system.inspect' })
    if ($envTrace.Count -lt 1) { throw 'Missing env.show trace join' }
    $extTrace = @($trace | Where-Object { $_.Command -eq $extName -and $_.Capability -eq 'system.tools.hardening' })
    if ($extTrace.Count -lt 1) { throw 'Missing extension trace join' }
    Add-Pass 'scenario.trace.correlation'
} catch {
    Add-Fail 'scenario.trace.correlation' $_.Exception.Message
}

# ── Scenario 6: Load — repeated dispatch ──────────────────────────────────────
$beforeLoad = $script:WorkstationEventBuffer.Count
$sw = [Diagnostics.Stopwatch]::StartNew()
for ($i = 0; $i -lt $LoadIterations; $i++) {
    Invoke-WorkstationCommand -Name 'env.show' | Out-Null
}
$sw.Stop()
$loadEvents = @(Get-EventSlice -FromIndex $beforeLoad -Layer 'Router').Count
$expectedLoadEvents = $LoadIterations * 2
try {
    if ($loadEvents -ne $expectedLoadEvents) {
        throw "Expected $expectedLoadEvents router events, got $loadEvents"
    }
    Test-WorkstationEventBufferContract -FromIndex $beforeLoad | Out-Null
    Test-WorkstationEventLifecyclePairs -FromIndex $beforeLoad | Out-Null
    Add-Pass 'scenario.load.router-repeat'
    $report.Metrics.LoadIterations = $LoadIterations
    $report.Metrics.LoadDurationMs = $sw.ElapsedMilliseconds
    $report.Metrics.LoadAvgMs = [math]::Round($sw.ElapsedMilliseconds / [double]$LoadIterations, 2)
} catch {
    Add-Fail 'scenario.load.router-repeat' $_.Exception.Message
}

# ── Scenario 7: profile.reload nested orchestrator (real cascade) ───────────
$beforeReload = $script:WorkstationEventBuffer.Count
Invoke-WorkstationCommand -Name 'profile.reload' | Out-Null
$reloadSlice = @(Get-EventSlice -FromIndex $beforeReload)
$reloadRouter = @($reloadSlice | Where-Object { $_.Layer -eq 'Router' }).Count
$reloadOrch = @($reloadSlice | Where-Object { $_.Layer -eq 'Orchestrator' }).Count
try {
    if ($reloadRouter -ne 2) { throw "Expected 2 router events, got $reloadRouter" }
    if ($reloadOrch -ne 2) { throw "Expected 2 orchestrator events, got $reloadOrch" }
    Test-WorkstationEventLifecyclePairs -FromIndex $beforeReload | Out-Null
    Add-Pass 'scenario.profile-reload.cascade'
} catch {
    Add-Fail 'scenario.profile-reload.cascade' $_.Exception.Message
}

# ── Summary ───────────────────────────────────────────────────────────────────
$report.Metrics.TotalEvents = $script:WorkstationEventBuffer.Count
$report.Metrics.Passed = $report.Passed.Count
$report.Metrics.Failed = $report.Failed.Count
$report.Metrics.Warnings = $report.Warnings.Count

Write-Host ''
Write-Host '=== Workstation Platform Hardening ===' -ForegroundColor Cyan
Write-Host "Passed:  $($report.Metrics.Passed)" -ForegroundColor Green
Write-Host "Failed:  $($report.Metrics.Failed)" -ForegroundColor $(if ($report.Metrics.Failed -gt 0) { 'Red' } else { 'Green' })
Write-Host "Warnings: $($report.Metrics.Warnings)" -ForegroundColor Yellow
if ($report.Metrics.LoadAvgMs) {
    Write-Host "Load: $($report.Metrics.LoadIterations)x env.show avg $($report.Metrics.LoadAvgMs)ms" -ForegroundColor DarkGray
}

foreach ($f in $report.Failed) { Write-Host "  FAIL: $f" -ForegroundColor Red }
foreach ($w in $report.Warnings) { Write-Host "  WARN: $w" -ForegroundColor Yellow }

if ($SaveReport) {
    $outDir = Get-HomeBasePath -Name Logs
    $outFile = Join-Path $outDir "platform-hardening-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
    $report | ConvertTo-Json -Depth 6 | Set-Content -Path $outFile -Encoding UTF8
    Write-Host "Report: $outFile" -ForegroundColor DarkGray
}

if ($report.Failed.Count -gt 0) { exit 1 }
exit 0
