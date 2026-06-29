#Requires -Version 7.0
<#
.SYNOPSIS
    Resilience checks for health baseline/history (corrupt JSON, missing files).
#>
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '..\_Resolve-RepoRoot.ps1')
$Root = Resolve-WorkstationRepoRoot -Start $PSScriptRoot
. (Join-Path $Root 'lib\WorkstationCommon.ps1')
. (Join-Path $Root 'lib\DevShellHealth.ps1')

Write-Host 'Health resilience smoke' -ForegroundColor Cyan

$product = '3.0.0'
$psd1 = Join-Path $Root 'modules\KGreen.Workstation.psd1'
if (Test-Path $psd1) { $product = [string](Import-PowerShellDataFile $psd1).ModuleVersion }

$report = [PSCustomObject]@{
    timestamp       = (Get-Date).ToString('o')
    sections        = [ordered]@{ developer = @{ label = 'Developer'; status = 'PASS' } }
    privacyReport   = @{ checks = @(@{ id = 'doh'; status = 'Pass' }) }
}

$tempBase = Join-Path $env:TEMP "devshell-baseline-test-$([guid]::NewGuid().ToString('N').Substring(0,8)).json"
try {
    Set-Content -Path $tempBase -Value '{ not valid json' -Encoding UTF8
    $bad = Compare-DevShellHealthBaseline -Current $report -BaselinePath $tempBase
    if (-not $bad.baselineInvalid) { throw 'corrupt baseline should set baselineInvalid' }
    Write-Host '  [PASS] corrupt baseline handled' -ForegroundColor Green

    $badJson = $bad | ConvertTo-Json -Depth 3
    if ($badJson -notmatch 'baselineInvalid') { throw 'baselineInvalid should serialize' }

    $missing = Join-Path $env:TEMP "devshell-missing-baseline-$([guid]::NewGuid().ToString('N')).json"
    $none = Compare-DevShellHealthBaseline -Current $report -BaselinePath $missing
    if (-not $none.noBaseline) { throw 'missing baseline should set noBaseline' }
    Write-Host '  [PASS] missing baseline handled' -ForegroundColor Green
}
finally {
    if (Test-Path $tempBase) { Remove-Item $tempBase -Force -ErrorAction SilentlyContinue }
}

$tempHist = Join-Path $env:TEMP "devshell-history-test-$([guid]::NewGuid().ToString('N').Substring(0,8)).jsonl"
try {
    @(
        '{"timestamp":"2026-01-01T00:00:00","privacy":80,"developer":"PASS","ready":true}'
        'not-json'
        '{"timestamp":"2026-01-02T00:00:00","privacy":90,"developer":"PASS","ready":true}'
    ) | Set-Content $tempHist -Encoding UTF8
    $out = pwsh -NoProfile -Command @"
. '$Root\lib\DevShellHealth.ps1'
Show-DevShellHealthHistory -HistoryPath '$tempHist' -Last 5
"@ 2>&1 | Out-String
    if ($out -notmatch 'Privacy') { throw 'history should show valid rows despite corrupt line' }
    Write-Host '  [PASS] corrupt history line skipped' -ForegroundColor Green
}
finally {
    if (Test-Path $tempHist) { Remove-Item $tempHist -Force -ErrorAction SilentlyContinue }
}

Write-Host ''
Write-Host 'Health resilience smoke — ALL PASS' -ForegroundColor Green
exit 0
