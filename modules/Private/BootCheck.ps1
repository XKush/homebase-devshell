# Post-reboot + profile drift guards

$script:BootMarkerPath = 'C:\Logs\Workstation\last-boot-marker.txt'

function Test-PostRebootSession {
    try {
        $os = Get-CimInstance Win32_OperatingSystem -OperationTimeoutSec 2
        $bootId = $os.LastBootUpTime.ToString('o')
        if (-not (Test-Path $script:BootMarkerPath)) {
            Set-Content $script:BootMarkerPath $bootId -Encoding UTF8
            return $true
        }
        $saved = Get-Content $script:BootMarkerPath -Raw
        if ($saved.Trim() -ne $bootId) {
            Set-Content $script:BootMarkerPath $bootId -Encoding UTF8
            return $true
        }
    } catch { }
    return $false
}

function Invoke-ProfileDriftGuard {
    $canon = Join-Path $script:WSRoot 'profile\Microsoft.PowerShell_profile.ps1'
    $live = Join-Path $env:USERPROFILE 'Documents\PowerShell\Microsoft.PowerShell_profile.ps1'
    if (-not ((Test-Path $canon) -and (Test-Path $live))) { return $false }
    if ((Get-FileHash $canon).Hash -eq (Get-FileHash $live).Hash) { return $false }

    Write-HackerLine '[DRIFT] profile out of sync — auto fixprofile' -Color Yellow
    $ip = Join-Path $script:WSRoot 'Install-ShellProfile.ps1'
    if (Test-Path $ip) { & $ip -Force -ErrorAction SilentlyContinue | Out-Null; return $true }
    return $false
}

function Show-PostRebootChecklist {
    Write-HackerSection -Tag 'BOOT' -Title 'POST-REBOOT CHECKLIST' -Color Yellow
    $checks = @(
        @{ N = 'Nerd Font'; T = { Test-Path (Join-Path 'C:\Logs\Workstation' 'font-status.json') } }
        @{ N = 'OMP theme'; T = { Test-Path 'C:\Scripts\Workstation\terminal\active-theme.omp.json' } }
        @{ N = 'Module';    T = { [bool](Get-Module KGreen.Workstation) } }
        @{ N = 'Trust';     T = { (Get-SystemTrustReport -Live).CanTrustDashboard } }
    )
    foreach ($c in $checks) {
        $ok = try { & $c.T } catch { $false }
        Write-HackerStatusRow -Icon $(if ($ok) { '++' } else { '!!' }) -Name $c.N -Status $(if ($ok) { 'OK' } else { 'WARNING' })
    }
    Write-HackerLine '>> repairterminal · scan · trustcheck' -Color DarkGreen
    Write-Host ''
}
