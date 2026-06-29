#Requires -Version 7.0
<#
.SYNOPSIS
    Phase 3 — Install and validate professional networking toolkit.
.NOTES
    Skips already-installed tools. Upgrades when -Upgrade. Never touches Defender.
#>
param(
    [switch]$Force,
    [switch]$Upgrade,
    [switch]$SkipOptional
)
. (Join-Path $PSScriptRoot '..\_Resolve-RepoRoot.ps1')
$repoRoot = Resolve-WorkstationRepoRoot -Start $PSScriptRoot
$script:WSRoot = $repoRoot

$ErrorActionPreference = 'Continue'
. (Join-Path $repoRoot 'lib\WorkstationCommon.ps1')
Assert-DefenderUntouched

Write-WorkstationStep 'Network toolkit — inventory before install'

$required = @(
    @{ Id = 'WiresharkFoundation.Wireshark'; Name = 'Wireshark';    Cmd = 'wireshark'; AltCmd = 'tshark' }
    @{ Id = 'Insecure.Nmap';                 Name = 'Nmap';         Cmd = 'nmap' }
    @{ Id = 'Microsoft.SysinternalsSuite'; Name = 'Sysinternals'; Cmd = 'procexp64'; Optional = $true }
    @{ Id = 'voidtools.Everything';          Name = 'Everything';   Cmd = 'everything' }
    @{ Id = 'Git.Git';                       Name = 'Git';           Cmd = 'git' }
    @{ Id = 'GitHub.cli';                    Name = 'GitHub CLI';   Cmd = 'gh' }
    @{ Id = 'PuTTY.PuTTY';                   Name = 'PuTTY';         Cmd = 'putty' }
    @{ Id = 'ShiningLight.OpenSSL.Light';    Name = 'OpenSSL';      Cmd = 'openssl' }
    @{ Id = 'Microsoft.WindowsTerminal';     Name = 'Windows Terminal'; Cmd = 'wt'; Optional = $true }
)

$optional = @(
    @{ Id = 'BurntSushi.ripgrep.MSVC'; Name = 'ripgrep';  Cmd = 'rg' }
    @{ Id = 'sharkdp.fd';               Name = 'fd';       Cmd = 'fd' }
    @{ Id = 'jqlang.jq';                Name = 'jq';        Cmd = 'jq' }
    @{ Id = 'mikefarah.yq';             Name = 'yq';        Cmd = 'yq' }
    @{ Id = 'jesseduffield.lazygit';     Name = 'lazygit';  Cmd = 'lazygit' }
)

$psModules = @(
    @{ Name = 'PSWriteHTML'; Note = 'HTML reports (optional)' }
    @{ Name = 'Pester';      Note = 'testing (optional)' }
)

function Test-ToolPresent([hashtable]$Tool) {
    if (Get-Command $Tool.Cmd -ErrorAction SilentlyContinue) { return $true }
    if ($Tool.AltCmd -and (Get-Command $Tool.AltCmd -ErrorAction SilentlyContinue)) { return $true }
    return $false
}

function Install-WingetPackage([string]$Id, [string]$Label) {
    $args = @('install', '-e', '--id', $Id, '--accept-package-agreements', '--accept-source-agreements', '--disable-interactivity')
    if ($Upgrade) { $args += '--upgrade' }
    if ($Force)   { $args += '--force' }
    Write-Host "  -> $Label ($Id)" -ForegroundColor Gray
    $proc = Start-Process -FilePath winget -ArgumentList $args -Wait -PassThru -NoNewWindow
    if ($proc.ExitCode -notin 0, -1978335189) {
        Write-WorkstationLog "winget exit $($proc.ExitCode) for $Id" 'WARN'
        return $false
    }
    Write-WorkstationLog "Verified/installed $Id" 'OK'
    return $true
}

# OpenSSH Client (Windows feature)
Write-WorkstationStep 'OpenSSH Client'
if (Get-Command ssh -ErrorAction SilentlyContinue) {
    Write-WorkstationLog 'OpenSSH Client present' 'OK'
} else {
    Write-WorkstationLog 'OpenSSH Client missing — enable via Settings > Optional Features' 'WARN'
}

# WinDbg (optional — large)
Write-WorkstationStep 'WinDbg'
$windbgPaths = @(
    'C:\Program Files (x86)\Windows Kits\10\Debuggers\x64\windbg.exe',
    'C:\Program Files\Windows Kits\10\Debuggers\x64\windbg.exe'
)
$windbgFound = $windbgPaths | Where-Object { Test-Path $_ } | Select-Object -First 1
if ($windbgFound) {
    Write-WorkstationLog "WinDbg found: $windbgFound" 'OK'
} elseif (-not $SkipOptional) {
    Install-WingetPackage 'Microsoft.WinDbg' 'WinDbg Preview' | Out-Null
}

# Required + optional winget packages
Write-WorkstationStep 'Installing network tools via winget'
foreach ($tool in $required) {
    if (Test-ToolPresent $tool) {
        Write-WorkstationLog "$($tool.Name) already available ($($tool.Cmd))" 'OK'
        if (-not $Upgrade) { continue }
    }
    Install-WingetPackage $tool.Id $tool.Name | Out-Null
}

if (-not $SkipOptional) {
    foreach ($tool in $optional) {
        if (Test-ToolPresent $tool) {
            Write-WorkstationLog "$($tool.Name) present" 'OK'
            if (-not $Upgrade) { continue }
        }
        Install-WingetPackage $tool.Id $tool.Name | Out-Null
    }
}

# Sysinternals PATH helper
Write-WorkstationStep 'Sysinternals suite paths'
function Install-SysinternalsSuite {
    $target = 'C:\Tools\Sysinternals'
    if (Test-Path (Join-Path $target 'procexp64.exe')) { return $target }
    New-Item -ItemType Directory -Force -Path $target | Out-Null
    $zip = Join-Path $env:TEMP 'SysinternalsSuite.zip'
    Write-WorkstationLog 'Downloading Sysinternals Suite...'
    try {
        Invoke-WebRequest -Uri 'https://download.sysinternals.com/files/SysinternalsSuite.zip' -OutFile $zip -UseBasicParsing
        Expand-Archive -Path $zip -DestinationPath $target -Force
        Remove-Item $zip -Force -EA SilentlyContinue
        Write-WorkstationLog "Sysinternals extracted to $target" 'OK'
    } catch {
        Write-WorkstationLog "Sysinternals download failed: $($_.Exception.Message)" 'WARN'
    }
    return $target
}

$sysPaths = @(
    'C:\Tools\Sysinternals',
    'C:\Program Files\Sysinternals',
    (Join-Path $env:USERPROFILE 'Downloads\SysinternalsSuite')
)
$sysDir = $sysPaths | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $sysDir) {
    $sysDir = Install-SysinternalsSuite
}
if ($sysDir) {
    $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
    if ($userPath -notlike "*$sysDir*") {
        [Environment]::SetEnvironmentVariable('Path', "$userPath;$sysDir", 'User')
        Write-WorkstationLog "Added Sysinternals to PATH: $sysDir" 'OK'
    }
    foreach ($exe in @('procexp64','procmon64','tcpview64')) {
        $full = Join-Path $sysDir "$exe.exe"
        if (Test-Path $full) { Write-WorkstationLog "Sysinternals: $exe OK" 'OK' }
        else { Write-WorkstationLog "Sysinternals: $exe not found in $sysDir" 'WARN' }
    }
} else {
    Write-WorkstationLog 'Sysinternals directory not found — re-run after winget install' 'WARN'
}

# PowerShell networking modules
Write-WorkstationStep 'PowerShell networking modules'
$coreModules = @('PSReadLine', 'posh-git', 'Terminal-Icons')
foreach ($mod in $coreModules) {
    if (-not (Get-Module -ListAvailable $mod)) {
        Install-Module $mod -Scope CurrentUser -Force -AllowClobber -Repository PSGallery -EA SilentlyContinue
    }
}
foreach ($mod in $psModules) {
    if (-not (Get-Module -ListAvailable $mod.Name)) {
        try {
            Install-Module $mod.Name -Scope CurrentUser -Force -AllowClobber -Repository PSGallery -EA Stop
            Write-WorkstationLog "Module installed: $($mod.Name)" 'OK'
        } catch {
            Write-WorkstationLog "Optional module $($mod.Name) skipped: $($_.Exception.Message)" 'WARN'
        }
    }
}

# OpenSSL PATH (winget installs but often omits bin from user PATH)
Write-WorkstationStep 'OpenSSL PATH'
$opensslBins = @(
    'C:\Program Files\OpenSSL-Win64\bin'
    'C:\Program Files\OpenSSL\bin'
)
$opensslDir = $opensslBins | Where-Object { Test-Path (Join-Path $_ 'openssl.exe') } | Select-Object -First 1
if ($opensslDir) {
    $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
    if ($userPath -notlike "*$opensslDir*") {
        [Environment]::SetEnvironmentVariable('Path', "$userPath;$opensslDir", 'User')
        $env:Path = "$env:Path;$opensslDir"
        Write-WorkstationLog "Added OpenSSL to PATH: $opensslDir" 'OK'
    } else {
        Write-WorkstationLog 'OpenSSL already on PATH' 'OK'
    }
} else {
    Write-WorkstationLog 'OpenSSL bin not found — re-run after winget install' 'WARN'
}

# Validate all tools
Write-WorkstationStep 'Validating network toolkit'
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$inventory = [System.Collections.Generic.List[object]]::new()

$checkTools = @(
    @{ Name = 'Wireshark';  Cmd = 'wireshark' }
    @{ Name = 'TShark';     Cmd = 'tshark' }
    @{ Name = 'Nmap';       Cmd = 'nmap' }
    @{ Name = 'OpenSSH';    Cmd = 'ssh' }
    @{ Name = 'OpenSSL';    Cmd = 'openssl' }
    @{ Name = 'PuTTY';      Cmd = 'putty' }
    @{ Name = 'Everything'; Cmd = 'everything' }
    @{ Name = 'GitHub CLI'; Cmd = 'gh' }
    @{ Name = 'Git';        Cmd = 'git' }
    @{ Name = 'ripgrep';    Cmd = 'rg'; Optional = $true }
    @{ Name = 'fd';         Cmd = 'fd'; Optional = $true }
    @{ Name = 'jq';         Cmd = 'jq'; Optional = $true }
    @{ Name = 'yq';         Cmd = 'yq'; Optional = $true }
    @{ Name = 'lazygit';    Cmd = 'lazygit'; Optional = $true }
)

foreach ($t in $checkTools) {
    $cmd = Get-Command $t.Cmd -ErrorAction SilentlyContinue
    $status = if ($cmd) { 'OK' } elseif ($t.Optional) { 'OPTIONAL' } else { 'MISSING' }
    $ver = '-'
    if ($cmd) {
        try {
            $verOut = & $t.Cmd --version 2>&1 | Select-Object -First 1
            $ver = "$verOut".Trim()
        } catch { $ver = $cmd.Source }
    }
    $inventory.Add([ordered]@{
        Tool   = $t.Name
        Command = $t.Cmd
        Status = $status
        Version = $ver
        Path   = if ($cmd) { $cmd.Source } else { $null }
    })
    $color = switch ($status) { 'OK' { 'OK' } 'OPTIONAL' { 'WARN' } default { 'ERROR' } }
    Write-WorkstationLog "$($t.Name): $status" $color
}

# Sysinternals (not always on PATH as commands)
foreach ($s in @(
    @{ Name = 'Process Explorer'; File = 'procexp64.exe' }
    @{ Name = 'Process Monitor';  File = 'procmon64.exe' }
    @{ Name = 'TCPView';          File = 'tcpview64.exe' }
)) {
    $found = $null
    if ($sysDir) {
        $p = Join-Path $sysDir $s.File
        if (Test-Path $p) { $found = $p }
    }
    if (-not $found) {
        $found = (Get-Command $s.File -ErrorAction SilentlyContinue).Source
    }
    $inventory.Add([ordered]@{
        Tool = $s.Name; Command = $s.File
        Status = if ($found) { 'OK' } else { 'MISSING' }
        Path = $found
    })
}

$reportPath = "C:\Logs\Workstation\tools-inventory-$stamp.json"
@{
    Timestamp = (Get-Date).ToString('o')
    Tools = @($inventory)
} | ConvertTo-Json -Depth 4 | Set-Content $reportPath -Encoding UTF8

Write-WorkstationStep 'Network toolkit complete'
Write-Host "  Inventory: $reportPath" -ForegroundColor DarkGray

$missing = @($inventory | Where-Object { $_.Status -eq 'MISSING' })
exit $(if ($missing.Count -eq 0) { 0 } else { 1 })
