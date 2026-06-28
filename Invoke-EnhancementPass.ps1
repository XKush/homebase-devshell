#Requires -Version 7.0
<#
.SYNOPSIS
    Master enhancement pass — organization, networking, integration, validation.
#>
param(
    [switch]$SkipInstall,
    [switch]$SkipOrganize,
    [switch]$WhatIf
)

$ErrorActionPreference = 'Continue'
. "$PSScriptRoot\lib\WorkstationCommon.ps1"

$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
Write-WorkstationStep 'KGREEN WORKSTATION ENHANCEMENT PASS'

# Phase 1 — Audit
Write-WorkstationStep 'Phase 1 — Organization audit'
& "$PSScriptRoot\Invoke-OrganizationAudit.ps1"

# Phase 2 — Organize
if (-not $SkipOrganize) {
    Write-WorkstationStep 'Phase 2 — Workstation organization'
    & "$PSScriptRoot\Invoke-WorkstationOrganization.ps1" -WhatIf:$WhatIf
}

# Phase 3 — Network toolkit
if (-not $SkipInstall) {
    Write-WorkstationStep 'Phase 3 — Network toolkit install/validate'
    & "$PSScriptRoot\Install-NetworkToolkit.ps1" -SkipOptional:$false
}

# Phase 4 — Deploy profile (loads toolkit commands)
Write-WorkstationStep 'Phase 4 — Terminal integration'
& "$PSScriptRoot\Install-ShellProfile.ps1" -Force

# Phase 5 — Housekeeping
Write-WorkstationStep 'Phase 5 — Housekeeping'
& "$PSScriptRoot\Invoke-Housekeeping.ps1" -IncludeTemp

# Phase 6 — Beautification (fonts + path + env)
Write-WorkstationStep 'Phase 6 — Polish'
& "$PSScriptRoot\Repair-WorkstationFonts.ps1" -Force
& "$PSScriptRoot\Fix-WorkstationPath.ps1"

# Phase 7 — Final validation
Write-WorkstationStep 'Phase 7 — Final validation'
& "$PSScriptRoot\Validate-Workstation.ps1" -StartupBudgetMs 300
$valOk = ($LASTEXITCODE -eq 0)

# Generate final reports
$reports = [ordered]@{
    Timestamp = (Get-Date).ToString('o')
    Cleanup = Get-ChildItem 'C:\Logs\Workstation' -Filter 'housekeeping-*.json' | Sort-Object Name -Descending | Select-Object -First 1 -ExpandProperty FullName
    Organization = Get-ChildItem 'C:\Logs\Workstation' -Filter 'organization-audit-*.json' | Sort-Object Name -Descending | Select-Object -First 1 -ExpandProperty FullName
    Tools = Get-ChildItem 'C:\Logs\Workstation' -Filter 'tools-inventory-*.json' | Sort-Object Name -Descending | Select-Object -First 1 -ExpandProperty FullName
    Maintenance = 'C:\Logs\Workstation\maintenance-last.json'
    ValidationPassed = $valOk
}

$finalPath = "C:\Logs\Workstation\enhancement-final-$stamp.json"
$reports | ConvertTo-Json -Depth 3 | Set-Content $finalPath -Encoding UTF8

Write-Host ""
Write-Host '════════════════ ENHANCEMENT COMPLETE ════════════════' -ForegroundColor Cyan
Write-Host "  Validation: $(if($valOk){'PASS'}else{'FAIL'})" -ForegroundColor $(if($valOk){'Green'}else{'Yellow'})
Write-Host "  Reports:    $finalPath" -ForegroundColor DarkGray
Write-Host "  Commands:   nettools | toolbox | toolcheck | sysaudit" -ForegroundColor DarkGray
Write-Host '══════════════════════════════════════════════════════' -ForegroundColor Cyan

exit $(if ($valOk) { 0 } else { 1 })
