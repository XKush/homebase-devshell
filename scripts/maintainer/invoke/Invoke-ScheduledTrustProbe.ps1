#Requires -Version 7.0

. (Join-Path $PSScriptRoot '..\_Resolve-RepoRoot.ps1')
$repoRoot = Resolve-WorkstationRepoRoot -Start $PSScriptRoot
# Daily trust + command health (for scheduled task / CI)

$ErrorActionPreference = 'Continue'
. (Join-Path $repoRoot 'lib\HomeBasePaths.ps1')
$logDir = Get-HomeBasePath -Name Logs
if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Force -Path $logDir | Out-Null }

$modulePath = Join-Path $repoRoot 'modules\KGreen.Workstation.psm1'
Import-Module $modulePath -DisableNameChecking -Force

$trust = Get-SystemTrustReport -Live -Save
& (Join-Path $repoRoot 'scripts\maintainer\test\Test-WorkstationCommands.ps1') -Quick | Out-Null

@{
    Timestamp = (Get-Date).ToString('o')
    TrustLevel = $trust.Level
    TrustScore = $trust.Score
    CanTrust = $trust.CanTrustDashboard
    SelfChecks = "$($trust.SelfChecksPassed)/$($trust.SelfChecksTotal)"
} | ConvertTo-Json | Set-Content (Join-Path $logDir 'scheduled-trust-last.json') -Encoding UTF8

if (-not $trust.CanTrustDashboard) { exit 1 }
exit 0
