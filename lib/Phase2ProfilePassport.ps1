# Phase 2 Wave A — Profile layer passport helpers

function Get-Phase2ProfilePassport {
    param(
        [string]$WsRoot = (Split-Path $PSScriptRoot -Parent)
    )

    if (-not (Get-Command Get-HomeBasePath -ErrorAction SilentlyContinue)) {
        $pathsLib = Join-Path $WsRoot 'lib\HomeBasePaths.ps1'
        if (Test-Path $pathsLib) { . $pathsLib }
    }

    $repoRoot = if (Get-Command Get-HomeBasePath -ErrorAction SilentlyContinue) {
        Get-HomeBasePath -Name RepositoryRoot
    } else {
        $WsRoot
    }

    $logsRoot = if (Get-Command Get-HomeBasePath -ErrorAction SilentlyContinue) {
        Get-HomeBasePath -Name Logs
    } else { 'C:\Logs\Workstation' }

    $canonicalProfile = Join-Path $repoRoot 'profile\Microsoft.PowerShell_profile.ps1'
    $ompTheme = Join-Path $repoRoot 'terminal\active-theme.omp.json'

    $doctorLabel = 'unknown'
    $latestVal = Get-ChildItem $logsRoot -Filter 'validation-*.json' -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if ($latestVal) {
        try {
            $v = Get-Content $latestVal.FullName -Raw | ConvertFrom-Json
            if ($v.Metrics) {
                $doctorLabel = '{0}/{1}' -f $v.Metrics.PassCount, ($v.Metrics.PassCount + $v.Metrics.FailCount)
            }
        } catch { }
    }

    $trustLabel = 'unknown'
    $trustPath = Join-Path $logsRoot 'trust-report.json'
    if (Test-Path $trustPath) {
        try {
            $t = Get-Content $trustPath -Raw | ConvertFrom-Json
            $trustLabel = if ($t.Score -eq 100) { $t.Level } else { "$($t.Level) $($t.Score)" }
        } catch { }
    }

    $moduleLoaded = [bool](Get-Module 'KGreen.Workstation' -ErrorAction SilentlyContinue)
    $ompLoaded = [bool](Get-Command oh-my-posh -ErrorAction SilentlyContinue) -and (Test-Path $ompTheme)
    $profileLoaded = ($env:PROFILE_LOADED -eq '1') -or (Test-Path variable:global:PROFILE_LOADED)
    if (-not $profileLoaded) { $profileLoaded = Test-Path $PROFILE }

    $projectsRoot = if (Get-Command Get-HomeBasePath -ErrorAction SilentlyContinue) {
        Get-HomeBasePath -Name Projects
    } else { 'C:\Projects' }

    $cwdRestored = $false
    try {
        $cwdRestored = (Resolve-Path (Get-Location).Path).Path -eq (Resolve-Path $projectsRoot).Path
    } catch {
        $cwdRestored = $false
    }

    $pass = ($doctorLabel -match '75/75') -and ($trustLabel -eq 'VERIFIED') -and $profileLoaded -and $moduleLoaded

    return [ordered]@{
        wave            = 'Profile'
        profile_loaded  = $profileLoaded
        module_loaded   = $moduleLoaded
        omp_loaded      = $ompLoaded
        cwd_restored    = $cwdRestored
        doctor          = $doctorLabel
        trust           = $trustLabel
        profile_passport = if ($pass) { 'PASS' } else { 'FAIL' }
        profile_canonical = $canonicalProfile
        profile_deployed  = $PROFILE
    }
}
