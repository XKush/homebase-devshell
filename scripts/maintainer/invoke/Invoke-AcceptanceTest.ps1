#Requires -Version 7.0
<#
.SYNOPSIS
    Phase 10 — Final acceptance test (all health checks + commands).
#>
param([int]$StartupBudgetMs = 750)

$ErrorActionPreference = 'Continue'
. "$repoRoot\lib\WorkstationCommon.ps1"

$fail = 0
Write-WorkstationStep 'ACCEPTANCE TEST — KGreen Workstation'

# 1. Core validation
& "$repoRoot\scripts\maintainer\install\Validate-Workstation.ps1" -StartupBudgetMs $StartupBudgetMs
if ($LASTEXITCODE -ne 0) { $fail++ }

# 2. Command center commands
Write-WorkstationStep 'Command center self-test'
$live = Join-Path $HOME 'Documents\PowerShell\Microsoft.PowerShell_profile.ps1'
$cmdTest = pwsh -NoProfile -Command @"
`$env:WORKSTATION_DASHBOARD='0'; `$env:WORKSTATION_DASHBOARD_SHOWN='1'; `$env:WORKSTATION_WELCOMED='1'; `$env:CI='1'
. '$live'
. 'C:\Scripts\Workstation\lib\WorkstationCommandCenter.ps1'
`$required = @(
  'doctor','repairterminal','updateall','backupconfig','restoreconfig','cleanup',
  'healthcheck','workstationstatus','securitycheck','devstart','workspace',
  'cheatsheet','helpme','fixprofile','reloadprofile','sysreport','logs','networkstatus','learn',
  'nettools','toolbox','toolcheck','sysaudit',
  'jarvis','dashboard','home'
)

. (Join-Path $PSScriptRoot '..\_Resolve-RepoRoot.ps1')
$repoRoot = Resolve-WorkstationRepoRoot -Start $PSScriptRoot
`$missing = `$required | Where-Object { -not (Get-Command `$_ -EA SilentlyContinue) }
if (`$missing) { `$missing -join ','; exit 1 } else { exit 0 }
"@
if ($LASTEXITCODE -ne 0) {
    Write-WorkstationLog "Missing commands: $cmdTest" 'ERROR'
    $fail++
} else {
    Write-WorkstationLog 'All command center commands registered' 'OK'
}

# 3. Dashboard render test
Write-WorkstationStep 'Jarvis render test'
$dashOk = pwsh -NoProfile -Command @"
. 'C:\Scripts\Workstation\lib\WorkstationOperationsCenter.ps1'
Show-Woc -Mode minimal -Force -NoHeal | Out-Null
exit 0
"@
if ($LASTEXITCODE -ne 0) { $fail++; Write-WorkstationLog 'Dashboard render failed' 'ERROR' }
else { Write-WorkstationLog 'Dashboard renders' 'OK' }

# 4. Profile startup budget (parse only — Jarvis/OMP deferred to first prompt)
Write-WorkstationStep 'Startup budget (profile parse)'
$sw = [Diagnostics.Stopwatch]::StartNew()
pwsh -NoProfile -Command @"
`$env:CI='1'; `$env:WORKSTATION_JARVIS='0'; `$env:WORKSTATION_WELCOMED='1'
. '$live'
"@ 2>$null | Out-Null
$sw.Stop()
Write-WorkstationLog "Profile parse: $($sw.ElapsedMilliseconds)ms"
if ($sw.ElapsedMilliseconds -gt $StartupBudgetMs) {
    Write-WorkstationLog "Profile parse over budget ($StartupBudgetMs ms)" 'WARN'
    $fail++
} else {
    Write-WorkstationLog 'Profile parse within budget' 'OK'
}

Write-WorkstationStep 'ACCEPTANCE RESULT'
if ($fail -eq 0) {
    Write-Host 'PRODUCTION READY — all acceptance tests passed.' -ForegroundColor Green
    exit 0
} else {
    Write-Host "FAILED — $fail acceptance groups failed." -ForegroundColor Red
    exit 1
}
