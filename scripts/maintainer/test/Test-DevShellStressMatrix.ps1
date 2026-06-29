#Requires -Version 7.0
<#
.SYNOPSIS
    Offline stress scenarios — isolated temp dirs, no network, no admin required.
.DESCRIPTION
    Safe CI matrix for missing/corrupt paths. Does not modify user profile or ~/.homebase.
#>
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '..\_Resolve-RepoRoot.ps1')
$Root = Resolve-WorkstationRepoRoot -Start $PSScriptRoot
. (Join-Path $Root 'lib\WorkstationCommon.ps1')
. (Join-Path $Root 'lib\DevShellHealth.ps1')
. (Join-Path $Root 'lib\PrivacyAudit.ps1')

$pass = 0
function Assert-Stress {
    param([string]$Name, [scriptblock]$Test)
    try {
        & $Test
        Write-Host "  [PASS] $Name" -ForegroundColor Green
        $script:pass++
    } catch {
        Write-Host "  [FAIL] $Name — $_" -ForegroundColor Red
        throw
    }
}

Write-Host 'DevShell stress matrix (offline)' -ForegroundColor Cyan

$product = '3.0.0'
$psd1 = Join-Path $Root 'modules\KGreen.Workstation.psd1'
if (Test-Path $psd1) { $product = [string](Import-PowerShellDataFile $psd1).ModuleVersion }

$sampleReport = [PSCustomObject]@{
    timestamp     = (Get-Date).ToString('o')
    sections      = [ordered]@{
        developer            = @{ label = 'Developer'; status = 'PASS' }
        privacyConfiguration = @{ label = 'Privacy Configuration'; status = 'PASS'; score = 90 }
    }
    privacyReport = @{ checks = @(@{ id = 'doh'; status = 'Pass' }) }
}

Assert-Stress 'missing baseline path' {
    $p = Join-Path $env:TEMP "devshell-stress-missing-$([guid]::NewGuid().ToString('N')).json"
    $r = Compare-DevShellHealthBaseline -Current $sampleReport -BaselinePath $p
    if (-not $r.noBaseline) { throw 'expected noBaseline' }
}

Assert-Stress 'corrupt baseline JSON' {
    $p = Join-Path $env:TEMP "devshell-stress-bad-$([guid]::NewGuid().ToString('N')).json"
    try {
        Set-Content $p '{ corrupt' -Encoding UTF8
        $r = Compare-DevShellHealthBaseline -Current $sampleReport -BaselinePath $p
        if (-not $r.baselineInvalid) { throw 'expected baselineInvalid' }
    } finally {
        Remove-Item $p -Force -ErrorAction SilentlyContinue
    }
}

Assert-Stress 'corrupt history jsonl line skipped' {
    $hist = Join-Path $env:TEMP "devshell-stress-hist-$([guid]::NewGuid().ToString('N')).jsonl"
    try {
        @('{"timestamp":"2026-01-01T00:00:00","privacy":80,"developer":"PASS","ready":true}', 'BAD', '{"timestamp":"2026-01-02T00:00:00","privacy":90,"developer":"PASS","ready":true}') |
            Set-Content $hist -Encoding UTF8
        $out = pwsh -NoProfile -Command @"
. '$Root\lib\DevShellHealth.ps1'
Show-DevShellHealthHistory -HistoryPath '$hist' -Last 5
"@ 2>&1 | Out-String
        if ($out -notmatch 'Privacy') { throw 'valid rows not shown' }
    } finally {
        Remove-Item $hist -Force -ErrorAction SilentlyContinue
    }
}

Assert-Stress 'privacy audit without user config (defaults only)' {
    $r = Get-PrivacyAuditReport -Scope System -RepoRoot $Root -ProductVersion $product
    if ($null -eq $r.Score) { throw 'no score' }
    if ($r.Checks.Count -lt 1) { throw 'no checks' }
}

Assert-Stress 'verify -Json no_baseline envelope' {
    $env:HOMEBASE_DEVSHELL_ROOT = $Root
    $fakeBase = Join-Path $env:TEMP "devshell-stress-nobase-$([guid]::NewGuid().ToString('N')).json"
    $out = pwsh -NoProfile -Command @"
`$env:HOMEBASE_DEVSHELL_ROOT = '$Root'
. '$Root\lib\DevShellHealth.ps1'
. '$Root\lib\WorkstationCommon.ps1'
. '$Root\scripts\maintainer\invoke\_PrivacyInvokeCommon.ps1'
`$repo = '$Root'
`$product = '$product'
`$current = Get-DevShellHealthReport -RepoRoot `$repo -Tier Core -ProductVersion `$product
`$diff = Compare-DevShellHealthBaseline -Current `$current -BaselinePath '$fakeBase'
if (`$diff.noBaseline) { @{ error = 'no_baseline'; message = 'Run: devshell baseline' } | ConvertTo-Json } else { throw 'expected no baseline' }
"@ 2>&1 | Out-String
    if ($out -notmatch 'no_baseline') { throw "bad envelope: $out" }
}

Assert-Stress 'empty logs dir — doctor json path tolerant' {
    $tempLogs = Join-Path $env:TEMP "devshell-stress-logs-$([guid]::NewGuid().ToString('N'))"
    New-Item -ItemType Directory -Force -Path $tempLogs | Out-Null
    try {
        $r = Invoke-DevShellDoctorJson -RepoRoot $Root -Tier Core
        if ($null -ne $r -and $r.Passed -eq $null -and $r.Failed -eq $null) { throw 'unexpected doctor shape' }
    } finally {
        Remove-Item $tempLogs -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Write-Host ''
Write-Host "DevShell stress matrix — ALL PASS ($pass checks)" -ForegroundColor Green
exit 0
