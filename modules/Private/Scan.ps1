# Быстрый mini-probe — trust + ключевые команды (<150ms target)

function Invoke-QuickScan {
    $sw = [Diagnostics.Stopwatch]::StartNew()
    $checks = [System.Collections.Generic.List[string]]::new()

    $trust = Get-SystemTrustReport -Live -Save
    $checks.Add("TRUST $($trust.Score)/100 $($trust.Level)")

    foreach ($cmd in @('doctor', 'nettools', 'toolcheck', 'hack', 'home')) {
        $pre = Test-CommandSelfCheck -Name $cmd -Phase Pre
        $checks.Add($(if ($pre.OK) { "[OK] $cmd" } else { "[!!] $cmd — $($pre.Detail)" }))
    }

    $mod = Get-Module KGreen.Workstation
    $checks.Add($(if ($mod) { '[OK] module loaded' } else { '[!!] module missing' }))

    $sw.Stop()
    return [PSCustomObject]@{
        DurationMs = $sw.ElapsedMilliseconds
        Trust        = $trust
        Lines        = @($checks)
    }
}

function scan {
    param([switch]$Help, [switch]$Quiet)
    if (Test-ShowCommandHelp -Name 'scan' -Help:$Help) { return }

    Invoke-WorkstationCmd 'scan' {
        $r = Invoke-QuickScan
        if (-not $Quiet) {
            Write-Host ''
            Write-HackerSection -Tag 'SCAN' -Title "QUICK SCAN — $($r.DurationMs) ms" -Color Cyan
            $r.Lines | ForEach-Object { Write-HackerLine $_ -Color $(if ($_ -match '\[OK\]|TRUST.*VERIFIED') { 'Green' } elseif ($_ -match '\[!!\]|UNTRUSTED') { 'Red' } else { 'Yellow' }) }
            Write-HackerLine "integrity: $(if ($r.Trust.CanTrustDashboard) { 'CONFIRMED' } else { 'COMPROMISED' })" -Color $(if ($r.Trust.CanTrustDashboard) { 'Green' } else { 'Red' })
            Write-Host ''
        }
        if (-not $r.Trust.CanTrustDashboard) { $global:LASTEXITCODE = 1 }
    }
}
