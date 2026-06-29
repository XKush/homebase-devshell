# Profile boot diagnostics — read-only validation (Wave A Commit 5)

function Get-BootCheckLogsRoot {
    if (Get-Command Get-HomeBasePath -ErrorAction SilentlyContinue) {
        return Get-HomeBasePath -Name Logs
    }
    if ($env:WORKSTATION_LOGS) { return $env:WORKSTATION_LOGS }
    return 'C:\Logs\Workstation'
}

function Get-BootCheckRepositoryRoot {
    if ($script:WSRoot) { return $script:WSRoot }
    if ($env:WORKSTATION_ROOT) { return $env:WORKSTATION_ROOT }
    if (Get-Command Get-HomeBasePath -ErrorAction SilentlyContinue) {
        return Get-HomeBasePath -Name RepositoryRoot
    }
    return 'C:\Scripts\Workstation'
}

function Get-BootMarkerPath {
    Join-Path (Get-BootCheckLogsRoot) 'last-boot-marker.txt'
}

function Test-PostRebootSession {
    try {
        $os = Get-CimInstance Win32_OperatingSystem -OperationTimeoutSec 2
        $bootId = $os.LastBootUpTime.ToString('o')
        $marker = Get-BootMarkerPath
        if (-not (Test-Path $marker)) { return $false }
        $saved = (Get-Content $marker -Raw).Trim()
        return ($saved -ne $bootId)
    } catch { }
    return $false
}

function Test-ProfileDrift {
    $root = Get-BootCheckRepositoryRoot
    $canon = Join-Path $root 'profile\Microsoft.PowerShell_profile.ps1'
    $live  = Join-Path $env:USERPROFILE 'Documents\PowerShell\Microsoft.PowerShell_profile.ps1'
    if (-not ((Test-Path $canon) -and (Test-Path $live))) {
        return [PSCustomObject]@{ Ok = $false; Drift = $false; Reason = 'missing profile file' }
    }
    $match = (Get-FileHash $canon).Hash -eq (Get-FileHash $live).Hash
    [PSCustomObject]@{
        Ok    = $match
        Drift = -not $match
        Reason = if ($match) { 'synced' } else { 'canonical != live' }
    }
}

function Invoke-ProfileDriftGuard {
    $result = Test-ProfileDrift
    if ($result.Drift) {
        Write-HackerLine '[DRIFT] profile out of sync — run fixprofile' -Color Yellow
    }
    return $result.Drift
}

function Test-WorkstationBootEnvironment {
    $checks = [System.Collections.Generic.List[object]]::new()

    $ssotOk = $false
    $ssotDetail = 'Get-HomeBasePath unavailable'
    try {
        if (Get-Command Get-HomeBasePath -ErrorAction SilentlyContinue) {
            $null = Get-HomeBasePath -Name RepositoryRoot
            $ssotOk = $true
            $ssotDetail = 'RepositoryRoot resolved'
        }
    } catch {
        $ssotDetail = $_.Exception.Message
    }
    $checks.Add([PSCustomObject]@{
        Name = 'SSOT'; Status = $(if ($ssotOk) { 'OK' } else { 'ERROR' }); Detail = $ssotDetail
    })

    $roots = $script:WorkstationRoots
    if (-not $roots -and $global:WorkstationRoots) { $roots = $global:WorkstationRoots }
    $envOk = [bool]$env:WORKSTATION_ROOT -and [bool]$roots
    $checks.Add([PSCustomObject]@{
        Name = 'Environment'
        Status = $(if ($envOk) { 'OK' } else { 'ERROR' })
        Detail = $(if ($envOk) { 'WORKSTATION_ROOT + WorkstationRoots' } else { 'environment not initialized' })
    })

    $modReady = [bool](Get-Module KGreen.Workstation) -or ($script:WorkstationModuleLoaded -eq $true)
    $checks.Add([PSCustomObject]@{
        Name = 'Module bootstrap'
        Status = $(if ($modReady) { 'OK' } else { 'WARNING' })
        Detail = $(if ($modReady) { 'module load state consistent' } else { 'KGreen.Workstation not loaded yet' })
    })

    return @($checks)
}

function Show-PostRebootChecklist {
    Write-HackerSection -Tag 'BOOT' -Title 'После перезагрузки' -Color Yellow

    foreach ($c in (Test-WorkstationBootEnvironment)) {
        $ok = $c.Status -eq 'OK'
        Write-HackerStatusRow -Icon $(if ($ok) { '++' } else { '!!' }) -Name $c.Name -Status $(if ($ok) { 'OK' } else { $c.Status })
    }

    $logsRoot = Get-BootCheckLogsRoot
    $repoRoot = Get-BootCheckRepositoryRoot
    $ompPath  = if ($script:ProfileOmpTheme) { $script:ProfileOmpTheme } else { Join-Path $repoRoot 'terminal\active-theme.omp.json' }
    $extra = @(
        @{ N = 'Nerd Font'; T = { Test-Path (Join-Path $logsRoot 'font-status.json') } }
        @{ N = 'OMP theme'; T = { Test-Path $ompPath } }
        @{ N = 'Module';    T = { [bool](Get-Module KGreen.Workstation) } }
        @{ N = 'Trust';     T = { (Get-SystemTrustReport -Live).CanTrustDashboard } }
    )
    foreach ($c in $extra) {
        $ok = try { & $c.T } catch { $false }
        Write-HackerStatusRow -Icon $(if ($ok) { '++' } else { '!!' }) -Name $c.N -Status $(if ($ok) { 'OK' } else { 'WARNING' })
    }
    Write-HackerLine '>> repairterminal · scan · trustcheck' -Color DarkGreen
    Write-Host ''
}
