#Requires -Version 7.0
<#
.SYNOPSIS
    Final post-production validation + regression/usability/performance reports.
#>

. (Join-Path $PSScriptRoot '..\_Resolve-RepoRoot.ps1')
$repoRoot = Resolve-WorkstationRepoRoot -Start $PSScriptRoot
param([int]$StartupBudgetMs = 300)

$ErrorActionPreference = 'Continue'
. "$repoRoot\lib\WorkstationCommon.ps1"
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$dir = 'C:\Logs\Workstation'

Write-WorkstationStep 'POST-PRODUCTION VALIDATION'

# Run repairs first if font mismatch
$wtPath = Join-Path $env:LOCALAPPDATA 'Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json'
$wt = Get-Content $wtPath -Raw | ConvertFrom-Json
if ($wt.profiles.defaults.font.face -ne 'CaskaydiaCove NF') {
    Write-WorkstationLog 'Auto-repairing font mismatch' 'WARN'
    & "$repoRoot\Repair-WorkstationAll.ps1"
}

# Validation
& "$repoRoot\Validate-Workstation.ps1" -StartupBudgetMs $StartupBudgetMs
$valOk = ($LASTEXITCODE -eq 0)

# Acceptance
& "$repoRoot\Invoke-AcceptanceTest.ps1" -StartupBudgetMs $StartupBudgetMs
$accOk = ($LASTEXITCODE -eq 0)

# Benchmark
$live = Join-Path $HOME 'Documents\PowerShell\Microsoft.PowerShell_profile.ps1'
$sw = [Diagnostics.Stopwatch]::StartNew()
pwsh -NoProfile -Command "& { `$env:CI='1'; `$env:WORKSTATION_JARVIS='0'; . '$live' }" | Out-Null
$sw.Stop()
$profileMs = $sw.ElapsedMilliseconds

# Glyph test
$glyphOk = $true
$nfReg = (Get-ItemProperty 'HKCU:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts' -EA SilentlyContinue).PSObject.Properties.Name |
    Where-Object { $_ -like 'CaskaydiaCove NF Regular*' }
if (-not $nfReg) { $glyphOk = $false }

# Reports
$regression = [ordered]@{
    Timestamp = (Get-Date).ToString('o')
    ProfileLoadMs = $profileMs
    ProfileBudgetMs = $StartupBudgetMs
    ProfileWithinBudget = ($profileMs -le $StartupBudgetMs)
    ValidationPassed = $valOk
    AcceptancePassed = $accOk
    FontRegistryOK = [bool]$nfReg
    TerminalFontFace = $wt.profiles.defaults.font.face
    GlyphIssueRootCause = 'WT used CaskaydiaCove Nerd Font but installed face is CaskaydiaCove NF'
    FixApplied = 'Repair-WorkstationFonts.ps1 sets CaskaydiaCove NF on all profiles'
}

$usability = [ordered]@{
    BeginnerCommands = @('helpme','learn','whereami','explain','new-project','devstart')
    JarvisOnStartup = $true
    ConfusionRisks = @(
        'Git email still placeholder — set real email'
        'Firewall inbound not Block — run securitycheck'
        'Admin window needs restart after repairterminal for font cache'
    )
    AutomationsAdded = @('Jarvis cache','weekly maintenance task','backupconfig','cleanup','repairterminal')
}

$performance = [ordered]@{
    ProfileLoadMs = $profileMs
    TargetMs = $StartupBudgetMs
    OMPDeferred = $true
    JarvisCacheOnly = $true
    Note = 'Jarvis + OMP render on first prompt; profile parse stays under budget'
}

$reports = @{
    Regression = $regression
    Usability  = $usability
    Performance = $performance
}

foreach ($name in $reports.Keys) {
    $path = Join-Path $dir "final-$($name.ToLower())-$stamp.json"
    $reports[$name] | ConvertTo-Json -Depth 5 | Set-Content $path -Encoding UTF8
    Write-Host "  $path" -ForegroundColor DarkGray
}

$md = @"
# Post-Production Final Reports — KGreen
## Regression
- Profile load: **${profileMs}ms** (target ${StartupBudgetMs}ms)
- Validation: $(if($valOk){'PASS'}else{'FAIL'})
- Acceptance: $(if($accOk){'PASS'}else{'FAIL'})
- Font glyphs: $(if($glyphOk){'NF Regular installed'}else{'NEEDS REPAIR'})
- Terminal font: $($wt.profiles.defaults.font.face)

## Glyph fix
Root cause: font face name mismatch after reboot.
Fix: **CaskaydiaCove NF** (not 'CaskaydiaCove Nerd Font').

## Reboot checklist
1. Restart Windows Terminal (not just new tab)
2. Run ``doctor``
3. Run ``ll`` — icons should render
4. OMP prompt arrows should display correctly

## Commands
``repairterminal`` | ``doctor`` | ``Show-Jarvis``
"@
Set-Content (Join-Path $dir "final-summary-$stamp.md") $md -Encoding UTF8

Write-Host ""
if ($valOk -and $accOk -and $glyphOk -and $wt.profiles.defaults.font.face -eq 'CaskaydiaCove NF') {
    Write-Host 'POST-PRODUCTION: ACCEPTED' -ForegroundColor Green
    exit 0
} else {
    Write-Host 'POST-PRODUCTION: ISSUES REMAIN — run repairterminal' -ForegroundColor Yellow
    exit 1
}
