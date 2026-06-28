#Requires -Version 7.0
<#
.SYNOPSIS
    Mandatory Phase 2 commit gate pipeline (run before every Step 2 commit).
#>
$ErrorActionPreference = 'Stop'
$wsRoot = $PSScriptRoot
. (Join-Path $wsRoot 'lib\HomeBasePaths.ps1')

function Invoke-Gate {
    param([string]$Name, [scriptblock]$Action)
    Write-Host "=== $Name ===" -ForegroundColor Cyan
    & $Action
    if ($LASTEXITCODE -and $LASTEXITCODE -ne 0) {
        throw "Gate failed: $Name (exit $LASTEXITCODE)"
    }
}

Import-Module (Join-Path $wsRoot 'modules\KGreen.Workstation.psm1') -DisableNameChecking -Scope Global -Force

Invoke-Gate 'backupconfig' { backupconfig }
Invoke-Gate 'Test-HomeBasePaths' { & (Join-Path $wsRoot 'Test-HomeBasePaths.ps1') }
Invoke-Gate 'Test-LegacyEquivalence' { & (Join-Path $wsRoot 'Test-LegacyEquivalence.ps1') }
Invoke-Gate 'doctor' { doctor | Out-Null }
Invoke-Gate 'Test-WorkstationCommands -Quick' { & (Join-Path $wsRoot 'Test-WorkstationCommands.ps1') -Quick | Out-Null }
Invoke-Gate 'trustcheck' {
    Get-SystemTrustReport -Live -Save | Out-Null
    trustcheck | Out-Null
    $t = Get-Content (Join-Path (Get-HomeBasePath -Name Logs) 'trust-report.json') -Raw | ConvertFrom-Json
    if ($t.Level -ne 'VERIFIED' -or $t.Score -ne 100) {
        throw "Trust not VERIFIED 100: $($t.Level) $($t.Score)"
    }
}
Invoke-Gate 'Test-ReleaseVersion' { & (Join-Path $wsRoot 'Test-ReleaseVersion.ps1') }

Write-Host ''
Write-Host 'Phase 2 commit gate: ALL PASS — safe to commit' -ForegroundColor Green
exit 0
