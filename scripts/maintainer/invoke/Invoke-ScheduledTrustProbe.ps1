#Requires -Version 7.0

. (Join-Path $PSScriptRoot '..\_Resolve-RepoRoot.ps1')
$repoRoot = Resolve-WorkstationRepoRoot -Start $PSScriptRoot
# Daily trust + command health (for scheduled task / CI)

$ErrorActionPreference = 'Continue'
$logDir = 'C:\Logs\Workstation'
if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Force -Path $logDir | Out-Null }

Import-Module 'C:\Scripts\Workstation\modules\KGreen.Workstation.psm1' -DisableNameChecking -Force

$trust = Get-SystemTrustReport -Live -Save
& 'C:\Scripts\Workstation\Test-WorkstationCommands.ps1' -Quick | Out-Null

@{
    Timestamp = (Get-Date).ToString('o')
    TrustLevel = $trust.Level
    TrustScore = $trust.Score
    CanTrust = $trust.CanTrustDashboard
    SelfChecks = "$($trust.SelfChecksPassed)/$($trust.SelfChecksTotal)"
} | ConvertTo-Json | Set-Content (Join-Path $logDir 'scheduled-trust-last.json') -Encoding UTF8

if (-not $trust.CanTrustDashboard) { exit 1 }
exit 0
