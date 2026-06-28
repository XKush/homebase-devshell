# HOME BASE Genesis — Operator DNA, Trust Chain, unique machine seal
# Уникально для KGreen: криптографический отпечаток + append-only chain + certificate

$script:GenesisStatePath = 'C:\Logs\Workstation\genesis-state.json'
$script:TrustChainPath   = 'C:\Logs\Workstation\trust-chain.jsonl'
$script:GenesisCertPath  = 'C:\Security\exports\genesis-certificate.txt'

function Get-FileSha256 {
    param([string]$Path)
    if (-not (Test-Path $Path)) { return $null }
    return (Get-FileHash $Path -Algorithm SHA256).Hash.ToLower()
}

function Get-MachineGuid {
    try {
        return (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Cryptography' -Name MachineGuid -ErrorAction Stop).MachineGuid
    } catch { return 'unknown-guid' }
}

function Get-OperatorGitHead {
    $root = if ($script:WSRoot) { $script:WSRoot } else { 'C:\Scripts\Workstation' }
    if (-not (Test-Path (Join-Path $root '.git'))) { return 'no-git' }
    try {
        Push-Location $root
        $h = (git rev-parse HEAD 2>$null).Trim()
        Pop-Location
        if ($h) { return $h }
        return 'no-head'
    } catch { Pop-Location -EA SilentlyContinue; return 'no-head' }
}

function Get-OperatorDnaInputs {
    $profile = Join-Path $HOME 'Documents\PowerShell\Microsoft.PowerShell_profile.ps1'
    $module  = Join-Path ($script:WSRoot ?? 'C:\Scripts\Workstation') 'modules\KGreen.Workstation.psm1'
    $trust   = $script:TrustReportPath ?? 'C:\Logs\Workstation\trust-report.json'

    $trustSnap = 'none'
    if (Test-Path $trust) {
        try {
            $t = Get-Content $trust -Raw | ConvertFrom-Json
            $trustSnap = "{0}:{1}:{2}" -f $t.Score, $t.Level, $t.SelfChecksPassed
        } catch { }
    }

    $userSid = $env:USERNAME
    try { $userSid = [System.Security.Principal.WindowsIdentity]::GetCurrent().User.Value } catch { }

    return [ordered]@{
        MachineGuid  = Get-MachineGuid
        UserSid      = $userSid
        Host         = $env:COMPUTERNAME
        User         = $env:USERNAME
        ProfileHash  = Get-FileSha256 $profile
        ModuleHash   = Get-FileSha256 $module
        GitHead      = Get-OperatorGitHead
        TrustSnap    = $trustSnap
        Workstation  = 'KGreen.HOME.BASE.v1'
    }
}

function Get-OperatorDna {
    param([switch]$Refresh)

    if (-not $Refresh -and (Test-Path $script:GenesisStatePath)) {
        try {
            $saved = Get-Content $script:GenesisStatePath -Raw | ConvertFrom-Json
            if ($saved.Dna -and $saved.Callsign) {
                return [PSCustomObject]$saved
            }
        } catch { }
    }

    $inputs = Get-OperatorDnaInputs
    $canonical = ($inputs.GetEnumerator() | Sort-Object Name | ForEach-Object { "{0}={1}" -f $_.Key, $_.Value }) -join '|'
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($canonical)
    $sha = [System.Security.Cryptography.SHA256]::Create()
    $hash = ($sha.ComputeHash($bytes) | ForEach-Object { $_.ToString('x2') }) -join ''
    $sha.Dispose()

    $callsign = ('{0}-{1}' -f ($env:USERNAME.Substring(0, [math]::Min(3, $env:USERNAME.Length)).ToUpper()), $hash.Substring(0, 6).ToUpper())
    $planetId = $hash.Substring(0, 32).ToUpper()

    $state = [ordered]@{
        Dna           = $hash
        Callsign      = $callsign
        PlanetId      = $planetId
        Created       = (Get-Date).ToString('o')
        Inputs        = $inputs
        SchemaVersion = 1
    }

    $dir = Split-Path $script:GenesisStatePath -Parent
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
    $state | ConvertTo-Json -Depth 6 | Set-Content $script:GenesisStatePath -Encoding UTF8

    return [PSCustomObject]$state
}

function Get-TrustChainLastHash {
    if (-not (Test-Path $script:TrustChainPath)) { return 'GENESIS' }
    $last = Get-Content $script:TrustChainPath -Tail 1 -ErrorAction SilentlyContinue
    if (-not $last) { return 'GENESIS' }
    try { return ([PSCustomObject]($last | ConvertFrom-Json)).BlockHash } catch { return 'GENESIS' }
}

function Add-TrustChainBlock {
    param(
        $TrustReport,
        [string]$Event = 'probe',
        [string]$Note = ''
    )

    $dna = Get-OperatorDna
    $prev = Get-TrustChainLastHash
    $payload = [ordered]@{
        Event       = $Event
        TrustScore  = $TrustReport.Score
        TrustLevel  = $TrustReport.Level
        CanTrust    = $TrustReport.CanTrustDashboard
        DnaShort    = $dna.Dna.Substring(0, 16)
        Callsign    = $dna.Callsign
        Note        = $Note
        Timestamp   = (Get-Date).ToString('o')
    }
    $canonical = "$prev|$(($payload | ConvertTo-Json -Compress))"
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($canonical)
    $sha = [System.Security.Cryptography.SHA256]::Create()
    $blockHash = ($sha.ComputeHash($bytes) | ForEach-Object { $_.ToString('x2') }) -join ''
    $sha.Dispose()

    $index = 0
    if (Test-Path $script:TrustChainPath) {
        $index = @(Get-Content $script:TrustChainPath -ErrorAction SilentlyContinue).Count
    }

    $block = [ordered]@{
        Index     = $index
        PrevHash  = $prev
        BlockHash = $blockHash
        Payload   = $payload
    }

    $dir = Split-Path $script:TrustChainPath -Parent
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
    ($block | ConvertTo-Json -Compress) | Add-Content $script:TrustChainPath -Encoding UTF8

    return [PSCustomObject]$block
}

function Test-TrustChainIntegrity {
    if (-not (Test-Path $script:TrustChainPath)) {
        return [PSCustomObject]@{ Valid = $true; Length = 0; Detail = 'empty chain' }
    }

    $lines = @(Get-Content $script:TrustChainPath -ErrorAction SilentlyContinue)
    $prev = 'GENESIS'
    $i = 0
    foreach ($line in $lines) {
        try {
            $b = $line | ConvertFrom-Json
            if ($b.PrevHash -ne $prev) {
                return [PSCustomObject]@{ Valid = $false; Length = $lines.Count; Detail = "break at index $i prev mismatch" }
            }
            $canonical = "$prev|$($b.Payload | ConvertTo-Json -Compress)"
            $bytes = [System.Text.Encoding]::UTF8.GetBytes($canonical)
            $sha = [System.Security.Cryptography.SHA256]::Create()
            $expected = ($sha.ComputeHash($bytes) | ForEach-Object { $_.ToString('x2') }) -join ''
            $sha.Dispose()
            if ($expected -ne $b.BlockHash) {
                return [PSCustomObject]@{ Valid = $false; Length = $lines.Count; Detail = "hash mismatch at index $i" }
            }
            $prev = $b.BlockHash
            $i++
        } catch {
            return [PSCustomObject]@{ Valid = $false; Length = $lines.Count; Detail = "parse error at index $i" }
        }
    }
    return [PSCustomObject]@{ Valid = $true; Length = $lines.Count; Detail = 'chain intact' }
}

function Get-DnaHelixArt {
    param([string]$Dna, [int]$Rows = 6)
    $chars = @('░', '▒', '▓', '█', '▄', '▀')
    $lines = [System.Collections.Generic.List[string]]::new()
    for ($r = 0; $r -lt $Rows; $r++) {
        $left = $chars[[int][char]$Dna[$r * 2] % $chars.Count]
        $right = $chars[[int][char]$Dna[$r * 2 + 1] % $chars.Count]
        $lines.Add("  $left───DNA───$right")
    }
    return @($lines)
}

function Export-GenesisCertificate {
    param($DnaState, $TrustReport, $ChainStatus, [int]$SingularityScore)

    $exportDir = Split-Path $script:GenesisCertPath -Parent
    if (-not (Test-Path $exportDir)) { New-Item -ItemType Directory -Force -Path $exportDir | Out-Null }

    $helix = Get-DnaHelixArt -Dna $DnaState.Dna
    $cert = @(
        '╔══════════════════════════════════════════════════════════════════╗'
        '║          HOME BASE GENESIS CERTIFICATE — UNIQUE SEAL             ║'
        '║          KGreen Workstation · Planet ID · Trust Chain            ║'
        '╠══════════════════════════════════════════════════════════════════╣'
        "║  OPERATOR   : $($DnaState.Callsign.PadRight(52)) ║"
        "║  PLANET ID  : $($DnaState.PlanetId.PadRight(52)) ║"
        "║  DNA        : $($DnaState.Dna.Substring(0, [math]::Min(52, $DnaState.Dna.Length)).PadRight(52)) ║"
        "║  HOST       : $($env:COMPUTERNAME)@$($env:USERNAME)".PadRight(67) + '║'
        "║  TRUST      : $($TrustReport.Score)/100 $($TrustReport.Level)".PadRight(67) + '║'
        "║  CHAIN      : $($ChainStatus.Length) blocks · $($ChainStatus.Detail)".PadRight(67) + '║'
        "║  SINGULARITY: $SingularityScore/100".PadRight(67) + '║'
        "║  ISSUED     : $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')".PadRight(67) + '║'
        '╠══════════════════════════════════════════════════════════════════╣'
    )
    foreach ($h in $helix) { $cert += "║$($h.PadRight(66))║" }
    $cert += @(
        '╠══════════════════════════════════════════════════════════════════╣'
        '║  This certificate is cryptographically tied to THIS machine.     ║'
        '║  DNA changes if profile, module, git, or trust anchor changes.   ║'
        '╚══════════════════════════════════════════════════════════════════╝'
    )

    $cert -join "`n" | Set-Content $script:GenesisCertPath -Encoding UTF8
    return $script:GenesisCertPath
}

function Get-SingularityScore {
    param($TrustReport, $WindowsReport, $ChainStatus)

    $score = 0
    if ($TrustReport.CanTrustDashboard -and $TrustReport.Score -ge 100) { $score += 40 }
    elseif ($TrustReport.CanTrustDashboard) { $score += [math]::Round($TrustReport.Score * 0.35) }
    if ($WindowsReport.Score -ge 100) { $score += 30 }
    elseif ($WindowsReport.Score -ge 90) { $score += 20 }
    if ($ChainStatus.Valid) { $score += 15 }
    if ($ChainStatus.Length -ge 1) { $score += 5 }
    if ($TrustReport.SelfChecksPassed -eq $TrustReport.SelfChecksTotal) { $score += 10 }
    return [math]::Min(100, $score)
}

function Show-GenesisCertificate {
    param([switch]$Quiet)
    $path = $script:GenesisCertPath
    if (-not (Test-Path $path)) { Write-HackerLine 'genesis certificate not found — run genesis or singularity' -Color Yellow; return }
    if ($Quiet) { return Get-Content $path -Raw }
    if (Get-Command bat -ErrorAction SilentlyContinue) { bat $path } else { Get-Content $path }
}

function Show-TrustChain {
    param([int]$Last = 5)
    $check = Test-TrustChainIntegrity
    Write-HackerSection -Tag 'CHAIN' -Title "TRUST CHAIN — $($check.Length) blocks · $($check.Detail)" -Color $(if ($check.Valid) { 'Green' } else { 'Red' })
    if (-not (Test-Path $script:TrustChainPath)) {
        Write-HackerLine 'empty — singularity or trustcheck creates first block' -Color DarkGray
        Write-Host ''
        return
    }
    Get-Content $script:TrustChainPath -Tail $Last | ForEach-Object {
        $b = $_ | ConvertFrom-Json
        Write-HackerLine ("#{0:D4} {1} T:{2} {3} · {4}" -f $b.Index, $b.Payload.Callsign, $b.Payload.TrustScore, $b.Payload.TrustLevel, $b.BlockHash.Substring(0, 12)) -Color DarkGreen
    }
    Write-Host ''
}

function dna {
    param([switch]$Help, [switch]$Refresh)
    if (Test-ShowCommandHelp -Name 'dna' -Help:$Help) { return }
    Invoke-WorkstationCmd 'dna' {
        $d = Get-OperatorDna -Refresh:$Refresh
        Write-HackerSection -Tag 'DNA' -Title 'OPERATOR DNA — уникальный отпечаток' -Color Cyan
        Write-HackerStat 'CALLSIGN' $d.Callsign -Color Green
        Write-HackerStat 'PLANET ID' $d.PlanetId -Color Cyan
        Write-HackerStat 'DNA FULL' $d.Dna -Color DarkGray
        Write-HackerStat 'GIT HEAD' $d.Inputs.GitHead.Substring(0, [math]::Min(12, $d.Inputs.GitHead.Length)) -Color DarkGray
        Get-DnaHelixArt -Dna $d.Dna | ForEach-Object { Write-HackerLine $_ -Color DarkGreen }
        Write-HackerLine '>> только эта машина · singularity · genesis' -Color DarkGray
        Write-Host ''
    }
}

function genesis {
    param([switch]$Help, [switch]$Force)
    if (Test-ShowCommandHelp -Name 'genesis' -Help:$Help) { return }
    Invoke-WorkstationCmd 'genesis' {
        $trust = Get-SystemTrustReport -Live -Save
        $win = Get-WindowsStatusReport
        $dna = Get-OperatorDna -Refresh
        Add-TrustChainBlock -TrustReport $trust -Event 'genesis' -Note 'seal refresh' | Out-Null
        $chain = Test-TrustChainIntegrity
        $sing = Get-SingularityScore -TrustReport $trust -WindowsReport $win -ChainStatus $chain
        $cert = Export-GenesisCertificate -DnaState $dna -TrustReport $trust -ChainStatus $chain -SingularityScore $sing
        Write-HackerSection -Tag 'SEAL' -Title 'GENESIS CERTIFICATE — создан' -Color Green
        Write-HackerStat 'CALLSIGN' $dna.Callsign -Color Green
        Write-HackerStat 'CERT' $cert -Color DarkGray
        Write-HackerStat 'SINGULARITY' "$sing/100" -Color $(if ($sing -ge 100) { 'Green' } else { 'Yellow' })
        Write-Host ''
    }
}

function trustchain {
    param([switch]$Help, [int]$Last = 8)
    if (Test-ShowCommandHelp -Name 'trustchain' -Help:$Help) { return }
    Invoke-WorkstationCmd 'trustchain' { Show-TrustChain -Last $Last }
}
