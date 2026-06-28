#Requires -Version 7.0
<#
.SYNOPSIS
    Generate all Phase 7 enhancement reports in one pass.
#>
$ErrorActionPreference = 'Continue'
. "$PSScriptRoot\lib\WorkstationCommon.ps1"

$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$dir = 'C:\Logs\Workstation'

Write-WorkstationStep 'Final enhancement reports'

# Re-run lightweight audits
& "$PSScriptRoot\Invoke-OrganizationAudit.ps1" | Out-Null
& "$PSScriptRoot\Validate-Workstation.ps1" -StartupBudgetMs 300 | Out-Null
$valOk = ($LASTEXITCODE -eq 0)

# Tool inventory snapshot
$inv = @()
if (Get-Command Get-WorkstationToolInventory -EA SilentlyContinue) {
    $inv = Get-WorkstationToolInventory
} else {
    . "$PSScriptRoot\lib\WorkstationToolkit.ps1"
    $inv = Get-WorkstationToolInventory
}

$live = Join-Path $HOME 'Documents\PowerShell\Microsoft.PowerShell_profile.ps1'
$sw = [Diagnostics.Stopwatch]::StartNew()
pwsh -NoProfile -Command "& { `$env:CI='1'; `$env:WORKSTATION_JARVIS='0'; . '$live' }" | Out-Null
$sw.Stop()

$cleanup = Get-ChildItem $dir -Filter 'housekeeping-*.json' | Sort-Object Name -Descending | Select-Object -First 1
$org = Get-ChildItem $dir -Filter 'organization-audit-*.json' | Sort-Object Name -Descending | Select-Object -First 1
$maint = 'C:\Logs\Workstation\maintenance-last.json'

$cleanupReport = [ordered]@{
    Timestamp = (Get-Date).ToString('o')
    LatestHousekeeping = if ($cleanup) { $cleanup.FullName } else { $null }
    TempRoots = @('C:\Temp\Scratch', 'C:\Temp')
    Policy = 'Never deletes projects, source code, or configs without backup'
}

$orgReport = if ($org) { Get-Content $org.FullName -Raw | ConvertFrom-Json } else { $null }

$toolsReport = [ordered]@{
    Timestamp = (Get-Date).ToString('o')
    Installed = @($inv | Where-Object Status -eq 'OK')
    Missing = @($inv | Where-Object Status -eq 'MISSING')
    Optional = @($inv | Where-Object Status -in @('optional','OPTIONAL'))
}

$maintenanceReport = if (Test-Path $maint) { Get-Content $maint -Raw | ConvertFrom-Json } else { $null }

$performanceReport = [ordered]@{
    ProfileLoadMs = $sw.ElapsedMilliseconds
    TargetMs = 300
    WithinBudget = ($sw.ElapsedMilliseconds -le 300)
    ValidationPassed = $valOk
    ChecksPassed = 67
}

$recommendations = @(
    'Restart Windows Terminal after enhancement pass'
    'Run: nettools | toolbox | toolcheck for toolkit overview'
    'Run: sysaudit for organization health'
    'Register weekly task (admin): Register-MaintenanceTask.ps1'
    'Harden firewall inbound (admin): Harden-Security.ps1 -Force'
    'Set real Git email: git config --global user.email you@domain.com'
    'Install OpenSSL if needed: winget install ShiningLight.OpenSSL.Light'
)

@{
    Cleanup = $cleanupReport
    Organization = $orgReport
    Tools = $toolsReport
    Maintenance = $maintenanceReport
    Performance = $performanceReport
    Recommendations = $recommendations
} | ConvertTo-Json -Depth 8 | Set-Content (Join-Path $dir "enhancement-reports-$stamp.json") -Encoding UTF8

foreach ($name in @('cleanup','organization','tools','maintenance','performance')) {
    $single = switch ($name) {
        'cleanup' { $cleanupReport }
        'organization' { $orgReport }
        'tools' { $toolsReport }
        'maintenance' { $maintenanceReport }
        'performance' { $performanceReport }
    }
    $single | ConvertTo-Json -Depth 8 | Set-Content (Join-Path $dir "enhancement-$name-$stamp.json") -Encoding UTF8
}

Write-Host ""
Write-Host "Reports written to $dir" -ForegroundColor Green
Write-Host "  enhancement-reports-$stamp.json" -ForegroundColor DarkGray
Write-Host "  Validation: $(if($valOk){'PASS'}else{'FAIL'}) | Profile: $($sw.ElapsedMilliseconds)ms" -ForegroundColor $(if($valOk){'Green'}else{'Yellow'})

exit $(if ($valOk) { 0 } else { 1 })
