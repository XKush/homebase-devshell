#Requires -Version 7.0

param([switch]$Quick)

. (Join-Path $PSScriptRoot '..\_Resolve-RepoRoot.ps1')
$repoRoot = Resolve-WorkstationRepoRoot -Start $PSScriptRoot

$ErrorActionPreference = 'Continue'
$fail = 0

& (Join-Path $repoRoot 'scripts\maintainer\test\Test-WorkstationCommands.ps1') @($(if ($Quick) { '-Quick' }))
if ($LASTEXITCODE) { $fail++ }

$trustScript = Join-Path $repoRoot 'scripts\maintainer\invoke\Invoke-ScheduledTrustProbe.ps1'
if (Test-Path $trustScript) {
    & $trustScript
    if ($LASTEXITCODE) { $fail++ }
}

if ($fail) {
    Write-Host "CI FAIL: $fail check(s) failed" -ForegroundColor Red
    exit 1
}
Write-Host 'CI OK: commands + trust verified' -ForegroundColor Green
exit 0
