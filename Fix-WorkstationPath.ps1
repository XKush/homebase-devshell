#Requires -Version 7.0
<#
.SYNOPSIS
    Deduplicate user PATH, repair split "Program Files" segments, ensure workstation dirs.
#>
$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\lib\WorkstationCommon.ps1"

$pathsToEnsure = @(
    'C:\Program Files\7-Zip'
    'C:\Program Files\Wireshark'
    'C:\Program Files\Everything'
    'C:\Program Files\Git\cmd'
    'C:\Program Files\OpenSSL-Win64\bin'
    'C:\Program Files (x86)\GnuPG\bin'
    'C:\Program Files\GnuPG\bin'
    'C:\Tools'
    'C:\Tools\Sysinternals'
    'C:\Scripts'
)

function Repair-PathSegments {
    param([string[]]$Raw)
    $fixed = [System.Collections.Generic.List[string]]::new()
    $i = 0
    while ($i -lt $Raw.Count) {
        $p = $Raw[$i].Trim()
        if (-not $p) { $i++; continue }

        if ($p -eq 'C:\Program' -and ($i + 1) -lt $Raw.Count -and $Raw[$i + 1] -match '^Files\\') {
            $merged = "C:\Program $($Raw[$i + 1].Trim())"
            if (-not $fixed.Contains($merged)) { [void]$fixed.Add($merged) }
            $i += 2
            continue
        }
        if ($p -eq 'C:\Program Files (x86)' -and ($i + 1) -lt $Raw.Count -and $Raw[$i + 1] -match '^[^\\]') {
            $merged = "$p\$($Raw[$i + 1].Trim())"
            if (-not $fixed.Contains($merged)) { [void]$fixed.Add($merged) }
            $i += 2
            continue
        }
        if ($p -eq 'C:\Program' -or $p -match '^Files\\') { $i++; continue }

        if (-not $fixed.Contains($p)) { [void]$fixed.Add($p) }
        $i++
    }
    return @($fixed)
}

$userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
$raw = @($userPath -split ';' | Where-Object { $_ })
$segments = [System.Collections.Generic.List[string]]::new()
foreach ($p in (Repair-PathSegments -Raw $raw)) { [void]$segments.Add($p) }

foreach ($p in $pathsToEnsure) {
    if ((Test-Path $p) -and -not $segments.Contains($p)) { [void]$segments.Add($p) }
}

$newPath = $segments -join ';'
[Environment]::SetEnvironmentVariable('Path', $newPath, 'User')
$env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' + $newPath
Write-WorkstationLog "PATH repaired ($($segments.Count) entries)" 'OK'

# Verify OpenSSL resolves after repair
if (Get-Command openssl -ErrorAction SilentlyContinue) {
    Write-WorkstationLog 'OpenSSL on PATH' 'OK'
} elseif (Test-Path 'C:\Program Files\OpenSSL-Win64\bin\openssl.exe') {
    Write-WorkstationLog 'OpenSSL installed but not on PATH — re-open terminal' 'WARN'
}
