#Requires -Version 7.0
<#
.SYNOPSIS
    Phase 1 — Full system discovery (read-only audit, no modifications).
#>

. (Join-Path $PSScriptRoot '..\_Resolve-RepoRoot.ps1')
$repoRoot = Resolve-WorkstationRepoRoot -Start $PSScriptRoot
param([string]$OutDir)

$ErrorActionPreference = 'Continue'
. "$repoRoot\lib\WorkstationCommon.ps1"

if (-not $OutDir) {
    $OutDir = Get-WorkstationLogsRoot
}

$repoRoot = if (Get-Command Get-HomeBasePath -ErrorAction SilentlyContinue) {
    Get-HomeBasePath -Name RepositoryRoot
} else {
    $PSScriptRoot
}
$backupsRoot = Get-WorkstationBackupsRoot

$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
if (-not (Test-Path $OutDir)) { New-Item -ItemType Directory -Force -Path $OutDir | Out-Null }

$discovery = [ordered]@{
    Timestamp = (Get-Date).ToString('o')
    Owner     = 'KGreen'
    Host      = $env:COMPUTERNAME
    OS        = [ordered]@{}
    Tools     = [ordered]@{}
    Terminal  = [ordered]@{}
    PathEnv   = [ordered]@{}
    Security  = [ordered]@{}
    Startup   = @()
    Services  = [ordered]@{}
    Backups   = [ordered]@{}
    Issues    = [System.Collections.Generic.List[string]]::new()
}

$env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' +
    [Environment]::GetEnvironmentVariable('Path', 'User')

$toolFallbacks = @{
    node = 'C:\Program Files\nodejs\node.exe'
    rg   = 'C:\Users\Admin\AppData\Local\Microsoft\WinGet\Links\rg.exe'
}

# OS
$os = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion'
$discovery.OS = [ordered]@{
    Version     = $os.DisplayVersion
    Build       = $os.CurrentBuild
    ProductName = $os.ProductName
    PowerShell  = (pwsh -NoProfile -Command '$PSVersionTable.PSVersion.ToString()')
}

# Tools
$toolList = @('pwsh','git','python','winget','code','oh-my-posh','fzf','bat','eza','zoxide','fastfetch','rg','nmap','7z','node','pipx')
foreach ($t in $toolList) {
    $c = Get-Command $t -ErrorAction SilentlyContinue
    if (-not $c -and $toolFallbacks.ContainsKey($t) -and (Test-Path $toolFallbacks[$t])) {
        $discovery.Tools[$t] = $toolFallbacks[$t]
        continue
    }
    $discovery.Tools[$t] = if ($c) { $c.Source } else { $null }
    if (-not $discovery.Tools[$t]) { $discovery.Issues.Add("Missing tool: $t") }
}

# Modules
$discovery.Modules = @{}
foreach ($m in @('PSReadLine','posh-git','Terminal-Icons')) {
    $mod = Get-Module -ListAvailable $m | Sort-Object Version -Descending | Select-Object -First 1
    $discovery.Modules[$m] = if ($mod) { "$($mod.Version)" } else { 'MISSING' }
    if (-not $mod) { $discovery.Issues.Add("Missing module: $m") }
}

# Fonts
$discovery.Fonts = @{}
$fontKeys = (Get-ItemProperty 'HKCU:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts' -EA SilentlyContinue).PSObject.Properties.Name |
    Where-Object { $_ -like '*Caskaydia*' -or $_ -like '*Nerd*' }
$discovery.Fonts.NerdFont = ($fontKeys | Select-Object -First 3) -join '; '
if (-not $fontKeys) { $discovery.Issues.Add('Nerd Font not in registry') }

# Terminal
$wt = Join-Path $env:LOCALAPPDATA 'Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json'
if (Test-Path $wt) {
    $w = Get-Content $wt -Raw | ConvertFrom-Json
    $discovery.Terminal = [ordered]@{
        DefaultProfile = $w.defaultProfile
        ColorScheme    = $w.profiles.defaults.colorScheme
        Font           = $w.profiles.defaults.font.face
        StartDir       = $w.profiles.defaults.startingDirectory
    }
} else { $discovery.Issues.Add('Windows Terminal settings missing') }

# PATH
$up = [Environment]::GetEnvironmentVariable('Path','User')
$mp = [Environment]::GetEnvironmentVariable('Path','Machine')
$all = ($up + ';' + $mp) -split ';' | Where-Object { $_ }
$dupes = $all | Group-Object | Where-Object Count -gt 1
$discovery.PathEnv = [ordered]@{
    UserSegments    = ($up -split ';' | Where-Object { $_ }).Count
    MachineSegments = ($mp -split ';' | Where-Object { $_ }).Count
    Duplicates      = @($dupes | ForEach-Object { $_.Name })
}
if ($dupes) { $discovery.Issues.Add("PATH duplicates: $($dupes.Count)") }

# Profile
$canon = Join-Path $repoRoot 'profile\Microsoft.PowerShell_profile.ps1'
$live  = Join-Path $HOME 'Documents\PowerShell\Microsoft.PowerShell_profile.ps1'
$discovery.Profile = [ordered]@{
    CanonicalExists = Test-Path $canon
    LiveExists      = Test-Path $live
    Match           = if ((Test-Path $canon) -and (Test-Path $live)) {
        (Get-FileHash $canon).Hash -eq (Get-FileHash $live).Hash
    } else { $false }
}
if (-not $discovery.Profile.Match) { $discovery.Issues.Add('Profile mismatch canonical vs live') }

# Security
try {
    $fw = Get-NetFirewallProfile -EA Stop
    foreach ($p in $fw) {
        $discovery.Security["Firewall_$($p.Name)"] = "$($p.Enabled)|inbound=$($p.DefaultInboundAction)"
        if ($p.DefaultInboundAction -ne 'Block') { $discovery.Issues.Add("Firewall $($p.Name) inbound not Block") }
    }
} catch { $discovery.Issues.Add("Firewall audit failed: $_") }
$discovery.Security.UAC = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' -EA SilentlyContinue).EnableLUA
$discovery.Security.SMB1 = (Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters' -Name SMB1 -EA SilentlyContinue).SMB1
$def = Get-Service WinDefend -EA SilentlyContinue
$discovery.Security.WinDefend = if ($def) { $def.Status.ToString() } else { 'absent' }

# Startup
Get-CimInstance Win32_StartupCommand -EA SilentlyContinue | ForEach-Object {
    $discovery.Startup += [ordered]@{ Name = $_.Name; Command = $_.Command }
}

# Backups
$bak = Get-ChildItem $backupsRoot -Directory -EA SilentlyContinue |
    Where-Object { $_.Name -notmatch '^_' } |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 1
$discovery.Backups = [ordered]@{
    Latest = if ($bak) { $bak.Name } else { 'none' }
    Count  = (Get-ChildItem $backupsRoot -Directory -EA SilentlyContinue |
        Where-Object { $_.Name -notmatch '^_' }).Count
}

# Benchmark
$sw = [Diagnostics.Stopwatch]::StartNew()
pwsh -NoProfile -Command "`$env:CI='1'; `$env:WORKSTATION_DASHBOARD='0'; . '$live'" 2>$null | Out-Null
$sw.Stop()
$discovery.Metrics = [ordered]@{ ProfileLoadMs = $sw.ElapsedMilliseconds }

$jsonPath = Join-Path $OutDir "discovery-$stamp.json"
$discovery | ConvertTo-Json -Depth 6 | Set-Content $jsonPath -Encoding UTF8
Write-Host "Discovery complete: $($discovery.Issues.Count) issues" -ForegroundColor $(if ($discovery.Issues.Count) { 'Yellow' } else { 'Green' })
Write-Host "Report: $jsonPath"
$discovery.Issues | ForEach-Object { Write-Host "  - $_" -ForegroundColor DarkYellow }
exit 0
