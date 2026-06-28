# SINGULARITY — ultimate HOME BASE cockpit (unique operator experience)

function Show-SingularityCockpit {
    $GT = Get-GenesisTexts
    $P  = Get-HackerPalette
    $sw = [Diagnostics.Stopwatch]::StartNew()

    if ([Environment]::UserInteractive -and -not $env:CI) {
        try { Clear-Host } catch { }
    }
    Write-Host ''
    Write-Host '  ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓' -ForegroundColor DarkGreen
    Write-Host '  ▓' -NoNewline -ForegroundColor DarkGreen
    Write-Host '  S I N G U L A R I T Y   M O D E  //  HOME BASE UNIQUE SEAL  ' -NoNewline -ForegroundColor Green
    Write-Host '▓' -ForegroundColor DarkGreen
    Write-Host '  ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓' -ForegroundColor DarkGreen
    Write-Host ''

    Write-HackerLine $GT.SingularityTitle -Color $P.Cyan
    Write-HackerLine $GT.DnaExplain -Color $P.Muted
    Write-Host ''

    Write-HackerSection -Tag 'PHASE' -Title 'PHASE 1 — live trust probe' -Color $P.Cyan
    $trust = Get-SystemTrustReport -Live -Save
    Write-HackerStat 'TRUST' (Format-HackerBar -Percent $trust.Score -Label $trust.Level) -Color $(if ($trust.CanTrustDashboard) { $P.TrustOk } else { $P.Alert })
    Write-HackerStat 'SELFCHK' "$($trust.SelfChecksPassed)/$($trust.SelfChecksTotal)" -Color $P.Muted

    Write-HackerSection -Tag 'PHASE' -Title 'PHASE 2 — Windows + command matrix' -Color $P.Cyan
    $win = Get-WindowsStatusReport
    Write-HackerStat 'WINDOWS' (Format-HackerBar -Percent $win.Score) -Color $P.Muted
    $health = Get-WorkstationCommandHealth -ErrorAction SilentlyContinue
    if (-not $health) {
        & (Join-Path ($script:WSRoot ?? 'C:\Scripts\Workstation') 'Test-WorkstationCommands.ps1') -Quick | Out-Null
    }

    Write-HackerSection -Tag 'PHASE' -Title 'PHASE 3 — Operator DNA synthesis' -Color $P.Neon
    $dna = Get-OperatorDna -Refresh
    Write-HackerStat 'CALLSIGN' $dna.Callsign -Color $P.TrustOk
    Write-HackerStat 'PLANET' $dna.PlanetId -Color $P.Cyan
    Get-DnaHelixArt -Dna $dna.Dna -Rows 4 | ForEach-Object { Write-HackerLine $_ -Color $P.Matrix }

    Write-HackerSection -Tag 'PHASE' -Title 'PHASE 4 — Trust Chain append' -Color $P.Accent
    $block = Add-TrustChainBlock -TrustReport $trust -Event 'singularity' -Note 'full probe'
    $chain = Test-TrustChainIntegrity
    Write-HackerStat 'BLOCK' ("#{0} {1}" -f $block.Index, $block.BlockHash.Substring(0, 20)) -Color DarkGreen
    Write-HackerStat 'CHAIN' ("{0} blocks · {1}" -f $chain.Length, $chain.Detail) -Color $(if ($chain.Valid) { $P.TrustOk } else { $P.Alert })

    $singScore = Get-SingularityScore -TrustReport $trust -WindowsReport $win -ChainStatus $chain
    $cert = Export-GenesisCertificate -DnaState $dna -TrustReport $trust -ChainStatus $chain -SingularityScore $singScore

    $sw.Stop()
    Write-Host ''
    Write-HackerSection -Tag 'SING' -Title 'SINGULARITY RESULT' -Color $(if ($singScore -ge 100) { $P.TrustOk } else { $P.Warn })

    if ($singScore -ge 100 -and $trust.CanTrustDashboard -and $chain.Valid) {
        Write-Host ''
        Write-Host '  ╔════════════════════════════════════════════════════════════╗' -ForegroundColor Green
        Write-Host '  ║' -NoNewline -ForegroundColor Green
        Write-Host '   ★ SINGULARITY ACHIEVED — UNIQUE OPERATOR SEAL ACTIVE ★   ' -NoNewline -ForegroundColor White
        Write-Host '║' -ForegroundColor Green
        Write-Host '  ╚════════════════════════════════════════════════════════════╝' -ForegroundColor Green
        Write-Host ''
        Write-HackerLine $GT.Achieved -Color $P.Neon
    } else {
        Write-HackerLine $GT.NotYet -Color $P.Warn
    }

    Write-HackerStat 'SCORE' (Format-HackerBar -Percent $singScore -Width 32 -Label 'SINGULARITY') -Color $P.Data
    Write-HackerStat 'TIME' ("{0} ms" -f $sw.ElapsedMilliseconds) -Color $P.Muted
    Write-HackerStat 'CERT' $cert -Color $P.Muted
    Write-HackerStat 'CHAIN' $GT.ChainPath -Color $P.Muted

    Write-Host ''
    Show-HackerCommandMatrix
    Write-HackerLine ">> callsign: $($dna.Callsign) · dna · trustchain · genesis" -Color $P.Matrix
    Write-Host ''

    if (-not $trust.CanTrustDashboard) { $global:LASTEXITCODE = 1 }
}

function singularity {
    param([switch]$Help)
    if (Test-ShowCommandHelp -Name 'singularity' -Help:$Help) { return }
    Invoke-WorkstationCmd 'singularity' { Show-SingularityCockpit }
}
