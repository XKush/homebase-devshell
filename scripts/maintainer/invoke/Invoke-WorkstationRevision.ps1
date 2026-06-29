#Requires -Version 7.0
<#
.SYNOPSIS
    Full HOME BASE revision pass — sync, validate, trust, security readiness.
.PARAMETER Quick
    Skip doctor (Validate-Workstation) — faster.
.PARAMETER Backup
    Run backupconfig if last backup > 7 days.
#>
param(
    [switch]$Quick,
    [switch]$Backup
)

. (Join-Path $PSScriptRoot '..\_Resolve-RepoRoot.ps1')
$repoRoot = Resolve-WorkstationRepoRoot -Start $PSScriptRoot

$ErrorActionPreference = 'Continue'
. "$repoRoot\lib\WorkstationCommon.ps1"

$logsRoot = Get-WorkstationLogsRoot
$backupsRoot = Get-WorkstationBackupsRoot

Write-WorkstationStep 'HOME BASE revision pass'

# 1. PATH + docs sync
& (Join-Path $repoRoot 'scripts\maintainer\configure\Fix-WorkstationPath.ps1') | Out-Null
& (Join-Path $repoRoot 'scripts\maintainer\invoke\Sync-WorkstationDocs.ps1') -CheckOnly
if ($LASTEXITCODE -ne 0) {
    & (Join-Path $repoRoot 'scripts\maintainer\invoke\Sync-WorkstationDocs.ps1') | Out-Null
}

# 2. Tor profile cleanup (wrong Profile Groups user.js)
$wrongJs = Join-Path $env:USERPROFILE 'Desktop\Tor Browser\Browser\TorBrowser\Data\Browser\Profile Groups\user.js'
$rightJs = Join-Path $env:USERPROFILE 'Desktop\Tor Browser\Browser\TorBrowser\Data\Browser\profile.default\user.js'
if ((Test-Path $wrongJs) -and (Test-Path $rightJs)) {
    Remove-Item $wrongJs -Force -ErrorAction SilentlyContinue
    Write-WorkstationLog 'Removed stray user.js from Profile Groups' 'OK'
}

# 3. Doctor
$doctorOk = $true
if (-not $Quick) {
    Write-WorkstationStep 'Doctor (Validate-Workstation)'
    & (Join-Path $repoRoot 'scripts\maintainer\install\Validate-Workstation.ps1')
    $latest = Get-ChildItem $logsRoot -Filter 'validation-*.json' -ErrorAction SilentlyContinue |
        Sort-Object Name -Descending | Select-Object -First 1
    if ($latest) {
        try {
            $rep = Get-Content $latest.FullName -Raw | ConvertFrom-Json
            $doctorOk = ($rep.Failed -eq 0)
            Write-WorkstationLog "Doctor: $($rep.Passed) pass / $($rep.Failed) fail" $(if ($doctorOk) { 'OK' } else { 'WARN' })
        } catch { }
    }
}

# 4. Module trust + security
Import-Module (Join-Path $PSScriptRoot 'modules\KGreen.Workstation.psm1') -Force

Write-WorkstationStep 'Trust probe'
$trust = Get-SystemTrustReport -Live -Save
Write-WorkstationLog "Trust: $($trust.Level) $($trust.Score)/100 · selfcheck $($trust.SelfChecksPassed)/$($trust.SelfChecksTotal)" 'OK'

Write-WorkstationStep 'SHADOW OPS readiness'
if (Get-Command Show-SecurityStatusPanel -ErrorAction SilentlyContinue) {
    Show-SecurityStatusPanel
    $sec = Get-SecurityReadinessReport
} else {
    $secJson = pwsh -NoProfile -Command @"
Import-Module '$(Join-Path $PSScriptRoot 'modules\KGreen.Workstation.psm1')' -Force
Get-SecurityReadinessReport | ConvertTo-Json -Compress
"@
    try { $sec = $secJson | ConvertFrom-Json } catch { $sec = $null }
    if (Get-Command sec -ErrorAction SilentlyContinue) { sec -Status | Out-Null }
}

# 5. Optional backup
if ($Backup) {
    $bakRoot = $backupsRoot
    $days = 999
    if (Test-Path $bakRoot) {
        $latestBak = Get-ChildItem $bakRoot -Directory -ErrorAction SilentlyContinue | Sort-Object Name -Descending | Select-Object -First 1
        if ($latestBak) { $days = ((Get-Date) - $latestBak.LastWriteTime).Days }
    }
    if ($days -gt 7) {
        Write-WorkstationStep 'Backup (stale > 7d)'
        & (Join-Path $repoRoot 'scripts\maintainer\invoke\Backup-Configuration.ps1') -Force
    } else {
        Write-WorkstationLog "Backup fresh ($days d) — skipped" 'OK'
    }
}

# 6. Mission queue
Write-WorkstationStep 'Next actions'
$next = [System.Collections.Generic.List[string]]::new()
if (-not $doctorOk) { $next.Add('doctor — fix validation failures') }
if ($trust.Score -lt 100) { $next.Add('trustcheck — resolve trust issues') }
if ($sec) {
    if (-not $sec.PgpReady) { $next.Add('pgp-repair') }
    if (-not $sec.TorReady) { $next.Add('tor-setup') }
    elseif (-not $sec.Hardened) { $next.Add('tor-harden') }
    if ($sec.Level -eq 'READY' -and -not $sec.KillSwitch) {
        $next.Add('tor-lock — admin перед Tor-сессией (опционально 100%)')
    }
    if ($sec.Level -ne 'READY') { $next.Add('sec — меню безопасности') }
}
if (-not $next.Count) {
    $next.Add('deploy: devstart · projects')
    $next.Add('session: sec → tor-check → Tor Browser')
    $next.Add('maintenance: revise -Backup раз в неделю')
}

$i = 1
foreach ($item in $next) {
    Write-Host ("  {0:D2} >> {1}" -f $i, $item) -ForegroundColor $(if ($i -eq 1 -and $item -notmatch 'deploy') { 'Yellow' } else { 'Green' })
    $i++
}

Write-Host ''
Write-WorkstationLog 'Revision complete — reloadprofile if module changed' 'OK'
