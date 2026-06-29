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
    'C:\Program Files\KeePassXC'
    'C:\Program Files\VeraCrypt'
    'C:\Program Files\nodejs'
    'C:\Tools'
    'C:\Tools\Sysinternals'
    'C:\Scripts'
)

function Normalize-PathSegment {
    param([string]$Path)
    if ([string]::IsNullOrWhiteSpace($Path)) { return $null }
    $p = $Path.Trim().TrimEnd('\')
    try { return [System.IO.Path]::GetFullPath($p) } catch { return $p.ToLowerInvariant() }
}

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
$machinePath = [Environment]::GetEnvironmentVariable('Path', 'Machine')
$machineSet = @{}
foreach ($p in ($machinePath -split ';' | Where-Object { $_ })) {
    $n = Normalize-PathSegment $p
    if ($n) { $machineSet[$n] = $true }
}

$raw = @($userPath -split ';' | Where-Object { $_ })
$segments = [System.Collections.Generic.List[string]]::new()
$removedFromUser = 0
foreach ($p in (Repair-PathSegments -Raw $raw)) {
    $n = Normalize-PathSegment $p
    if ($n -and $machineSet.ContainsKey($n)) {
        $removedFromUser++
        continue
    }
    if (-not $segments.Contains($p)) { [void]$segments.Add($p) }
}

foreach ($p in $pathsToEnsure) {
    if (-not (Test-Path $p)) { continue }
    $n = Normalize-PathSegment $p
    if ($n -and $machineSet.ContainsKey($n)) { continue }
    if (-not $segments.Contains($p)) { [void]$segments.Add($p) }
}

$newPath = $segments -join ';'
[Environment]::SetEnvironmentVariable('Path', $newPath, 'User')
$env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' + $newPath
Write-WorkstationLog "PATH repaired ($($segments.Count) user entries, $removedFromUser machine dupes removed)" 'OK'

# Verify OpenSSL resolves after repair
if (Get-Command openssl -ErrorAction SilentlyContinue) {
    Write-WorkstationLog 'OpenSSL on PATH' 'OK'
} elseif (Test-Path 'C:\Program Files\OpenSSL-Win64\bin\openssl.exe') {
    Write-WorkstationLog 'OpenSSL installed but not on PATH — re-open terminal' 'WARN'
}

foreach ($tool in @(
    @{ Name = 'keepassxc'; Path = 'C:\Program Files\KeePassXC\KeePassXC.exe' }
    @{ Name = 'veracrypt'; Path = 'C:\Program Files\VeraCrypt\VeraCrypt.exe' }
)) {
    if (Get-Command $tool.Name -ErrorAction SilentlyContinue) {
        Write-WorkstationLog "$($tool.Name) on PATH" 'OK'
    } elseif (Test-Path $tool.Path) {
        Write-WorkstationLog "$($tool.Name) installed (open new terminal for PATH)" 'OK'
    }
}

function Install-HomeBaseLegacyJunction {
    param(
        [Parameter(Mandatory)][string]$LegacyPath,
        [Parameter(Mandatory)][string]$TargetPath,
        [switch]$WhatIf
    )
    if (Test-Path $LegacyPath) {
        $item = Get-Item $LegacyPath -Force
        if ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) {
            Write-WorkstationLog "Junction exists: $LegacyPath" 'OK'
            return
        }
        if (-not $WhatIf) {
            throw "Legacy path exists and is not a junction: $LegacyPath"
        }
        Write-WorkstationLog "Would skip — path exists: $LegacyPath" 'WARN'
        return
    }
    if (-not (Test-Path $TargetPath)) {
        New-Item -ItemType Directory -Force -Path $TargetPath | Out-Null
    }
    if ($WhatIf) {
        Write-WorkstationLog "Would junction: $LegacyPath -> $TargetPath" 'INFO'
        return
    }
    cmd /c mklink /J "$LegacyPath" "$TargetPath" | Out-Null
    Write-WorkstationLog "Junction: $LegacyPath -> $TargetPath" 'OK'
}

function Install-HomeBaseLegacyJunctions {
    param([switch]$WhatIf)
    . "$PSScriptRoot\lib\HomeBasePaths.ps1"
    foreach ($j in Get-HomeBaseLegacyJunctions) {
        $target = Expand-HomeBasePathTemplate -Value $j.Target -Tokens @{
            RuntimeRoot = (Get-HomeBasePath -Name RuntimeRoot)
            RepositoryRoot = (Get-HomeBasePath -Name RepositoryRoot)
        }
        Install-HomeBaseLegacyJunction -LegacyPath $j.Legacy -TargetPath $target -WhatIf:$WhatIf
    }
}
