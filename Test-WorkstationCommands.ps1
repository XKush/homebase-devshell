#Requires -Version 7.0
<#
.SYNOPSIS
    Test framework for all workstation command center commands.
.DESCRIPTION
    Enumerates registered commands, validates existence, safe-executes each,
    verifies logging, and writes command-health.json for WOC integration.
#>
param(
    [switch]$Quick,
    [switch]$ReportOnly,
    [string]$OutputPath
)

$ErrorActionPreference = 'Continue'
$wsRoot = 'C:\Scripts\Workstation'
. (Join-Path $wsRoot 'lib\HomeBasePaths.ps1')
if (-not $OutputPath) { $OutputPath = Join-Path (Get-HomeBasePath -Name Logs) 'command-health.json' }
$modulePath = Join-Path $wsRoot 'modules\KGreen.Workstation.psm1'
$logPath = Join-Path (Get-HomeBasePath -Name Logs) 'commands.log'
$reportDir = Get-HomeBasePath -Name Logs

if (-not (Test-Path $reportDir)) { New-Item -ItemType Directory -Force -Path $reportDir | Out-Null }

function Test-CommandSafeInvoke {
    param(
        [string]$Name,
        [string]$SafeExpr,
        [hashtable]$EnvOverrides = @{}
    )
    $sw = [Diagnostics.Stopwatch]::StartNew()
    $result = [ordered]@{
        Command    = $Name
        Executed   = $false
        ExitCode   = 0
        DurationMs = 0
        Error      = $null
        OutputLines = 0
    }

    if (-not $SafeExpr) {
        $result.Skipped = $true
        $result.Reason = 'no safe mode (interactive/admin only)'
        $sw.Stop()
        $result.DurationMs = $sw.ElapsedMilliseconds
        return [PSCustomObject]$result
    }

    $envBlock = ($EnvOverrides.GetEnumerator() | ForEach-Object { "`$env:$($_.Key)='$($_.Value)'" }) -join '; '
    $script = @"
`$ErrorActionPreference = 'Continue'
$envBlock
Import-Module '$modulePath' -DisableNameChecking -Force
try {
    `$out = Invoke-Expression '$SafeExpr' 2>&1
    `$lines = @(`$out)
    Write-Output ('__LINES__:' + `$lines.Count)
    if (`$LASTEXITCODE) { exit `$LASTEXITCODE }
    exit 0
} catch {
    Write-Output ('__ERROR__:' + `$_.Exception.Message)
    exit 1
}
"@

    try {
        $raw = pwsh -NoProfile -Command $script 2>&1
        $text = ($raw | Out-String).Trim()
        if ($text -match '__ERROR__:(.+)') { $result.Error = $Matches[1].Trim(); $result.ExitCode = 1 }
        elseif ($text -match '__LINES__:\d+') { $result.Executed = $true; $result.ExitCode = 0 }
        elseif ($LASTEXITCODE -and $LASTEXITCODE -ne 0) { $result.ExitCode = $LASTEXITCODE; $result.Error = $text }
        else { $result.Executed = $true; $result.OutputLines = if ($text -match '__LINES__:(\d+)') { [int]$Matches[1] } else { 0 } }
    } catch {
        $result.Error = $_.Exception.Message
        $result.ExitCode = 1
    }

    $sw.Stop()
    $result.DurationMs = $sw.ElapsedMilliseconds
    return [PSCustomObject]$result
}

# Load registry in current session for inventory
Import-Module $modulePath -DisableNameChecking -Force
$registry = Get-WorkstationCommandRegistry
$logBefore = if (Test-Path $logPath) { (Get-Item $logPath).Length } else { 0 }

$matrix = [System.Collections.Generic.List[object]]::new()
$failures = [System.Collections.Generic.List[object]]::new()

foreach ($entry in $registry) {
    $name = $entry.Name
    $backend = $entry.Backend
    $cmdExists = [bool](Get-Command $name -ErrorAction SilentlyContinue)
    $backendExists = if ($backend -eq $name) { $cmdExists } else { [bool](Get-Command $backend -ErrorAction SilentlyContinue) }
    $helpOk = $false
    if ($cmdExists) {
        try {
            $cmdObj = Get-Command $name -ErrorAction SilentlyContinue
            if ($cmdObj -and $cmdObj.Parameters -and $cmdObj.Parameters.ContainsKey('Help')) { $helpOk = $true }
        } catch { }
    }

    $execResult = $null
    if (-not $ReportOnly -and $cmdExists -and $backendExists -and -not $Quick) {
        $envOverrides = @{ CI = '1'; WORKSTATION_JARVIS = '0'; WORKSTATION_JARVIS_SHOWN = '1' }
        $execResult = Test-CommandSafeInvoke -Name $name -SafeExpr $entry.Safe -EnvOverrides $envOverrides
        if ($execResult.Error -or ($execResult.ExitCode -ne 0 -and -not $execResult.Skipped)) {
            $failures.Add([PSCustomObject]@{
                Command = $name; Error = $execResult.Error; ExitCode = $execResult.ExitCode
            })
        }
    }

    $logsOk = $false
    if (-not $ReportOnly -and $cmdExists -and $backendExists -and -not $Quick -and $execResult -and ($execResult.Executed -or $execResult.Skipped)) {
        if (Test-Path $logPath) {
            $tail = Get-Content $logPath -Tail 5 -ErrorAction SilentlyContinue
            $logsOk = @($tail | Where-Object { $_ -match "\] $name -> OK" }).Count -gt 0
        }
    } elseif ($ReportOnly) {
        $logsOk = Test-Path $logPath
    }

    $executes = if ($execResult) {
        if ($execResult.Skipped) { 'SKIP' } elseif ($execResult.Executed -and -not $execResult.Error) { 'YES' } else { 'NO' }
    } else { if ($Quick) { '—' } else { '—' } }

    $matrix.Add([PSCustomObject]@{
        Command    = $name
        Backend    = $backend
        Module     = $entry.Module
        Exists     = if ($cmdExists) { 'YES' } else { 'NO' }
        Loads      = if ($cmdExists -and $backendExists) { 'YES' } else { 'NO' }
        Executes   = $executes
        Help       = if ($helpOk) { 'YES' } else { 'NO' }
        Logs       = if ($logsOk) { 'YES' } elseif ($Quick -or $ReportOnly) { '—' } else { 'NO' }
        DurationMs = if ($execResult) { $execResult.DurationMs } else { 0 }
        Error      = if ($execResult) { $execResult.Error } else { $null }
    })
}

$broken = @($matrix | Where-Object { $_.Exists -eq 'NO' -or $_.Loads -eq 'NO' })
$execFail = @($matrix | Where-Object { $_.Executes -eq 'NO' })
$passCount = @($matrix | Where-Object { $_.Exists -eq 'YES' -and $_.Loads -eq 'YES' -and $_.Executes -in @('YES','SKIP','—') }).Count

$health = [ordered]@{
    Timestamp       = (Get-Date).ToString('o')
    TotalCommands   = $matrix.Count
    Passed          = $passCount
    Broken          = $broken.Count
    ExecuteFailures = $execFail.Count
    BrokenCommands  = @($broken | ForEach-Object { $_.Command })
    FailedExecution = @($execFail | ForEach-Object { $_.Command })
    Matrix          = @($matrix)
    Failures        = @($failures)
}

$health | ConvertTo-Json -Depth 6 | Set-Content $OutputPath -Encoding UTF8

Write-Host "`n  Test-WorkstationCommands — KGreen" -ForegroundColor Cyan
Write-Host ("  {0}/{1} commands healthy | {2} broken | {3} exec failures" -f $passCount, $matrix.Count, $broken.Count, $execFail.Count) -ForegroundColor $(if ($broken.Count -eq 0 -and $execFail.Count -eq 0) { 'Green' } else { 'Yellow' })
Write-Host "  Report: $OutputPath`n" -ForegroundColor DarkGray

$matrix | Format-Table Command, Exists, Loads, Executes, Help, Logs, DurationMs -AutoSize

if ($broken.Count -or $execFail.Count) { exit 1 }
exit 0
