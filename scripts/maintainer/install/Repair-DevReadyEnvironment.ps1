#Requires -Version 7.0
<#
.SYNOPSIS
    Repair DevReady environment from doctor failures (winget + PSGallery + local scripts).
.NOTES
    Safe sources only: winget official repos, PSGallery. Never enables Defender.
#>
[CmdletBinding()]
param(
    [ValidateSet('Core', 'Full')]
    [string]$Tier = 'Core',
    [Parameter(Mandatory)]
    [string[]]$FailedChecks,
    [switch]$InstallMissingTools
)

$ErrorActionPreference = 'Continue'
. (Join-Path $PSScriptRoot '..\_Resolve-RepoRoot.ps1')
$repoRoot = Resolve-WorkstationRepoRoot -Start $PSScriptRoot
. (Join-Path $repoRoot 'lib\HomeBasePaths.ps1')
. (Join-Path $repoRoot 'lib\WorkstationCommon.ps1')
Assert-DefenderUntouched

$isFull = ($Tier -eq 'Full')
$doTools = $InstallMissingTools -or $isFull
$failedText = ($FailedChecks -join ' | ')

function Write-RepairAction {
    param([string]$Message)
    Write-Host "  [fix] $Message" -ForegroundColor Cyan
}

function Install-WingetPackage {
    param(
        [Parameter(Mandatory)][string]$Id,
        [string]$Label
    )
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        Write-WorkstationLog "winget unavailable — cannot install $Id" 'WARN'
        return $false
    }
    $name = if ($Label) { $Label } else { $Id }
    Write-RepairAction "winget install $name ($Id)"
    $args = @(
        'install', '--id', $Id, '-e',
        '--accept-package-agreements', '--accept-source-agreements',
        '--disable-interactivity'
    )
    $proc = Start-Process -FilePath winget -ArgumentList $args -Wait -PassThru -NoNewWindow
    if ($proc.ExitCode -in 0, -1978335189) {
        Write-WorkstationLog "winget OK: $Id" 'OK'
        return $true
    }
    Write-WorkstationLog "winget exit $($proc.ExitCode) for $Id" 'WARN'
    return $false
}

function Install-PowerShellModuleSafe {
    param([Parameter(Mandatory)][string]$Name)
    if (Get-Module -ListAvailable $Name) { return $true }
    if (-not (Get-PSRepository -Name PSGallery -ErrorAction SilentlyContinue)) {
        Register-PSRepository -Default -ErrorAction SilentlyContinue
    }
    Write-RepairAction "Install-Module $Name (PSGallery)"
    try {
        Install-Module $Name -Scope CurrentUser -Force -AllowClobber -Repository PSGallery -ErrorAction Stop
        Write-WorkstationLog "Module installed: $Name" 'OK'
        return $true
    } catch {
        Write-WorkstationLog "Module install failed: $Name — $_" 'WARN'
        return $false
    }
}

function Repair-DevShellShims {
    $shimDir = Join-Path $env:LOCALAPPDATA 'Microsoft\WindowsApps'
    if (-not (Test-Path $shimDir)) {
        New-Item -ItemType Directory -Force -Path $shimDir | Out-Null
    }
    $devshellPs1 = Join-Path $repoRoot 'devshell.ps1'
    @"
@echo off
pwsh -NoLogo -File "$devshellPs1" %*
"@ | Set-Content -Path (Join-Path $shimDir 'devshell.cmd') -Encoding ASCII
    @"
@echo off
pwsh -NoLogo -File "$devshellPs1" doctor %*
"@ | Set-Content -Path (Join-Path $shimDir 'devready.cmd') -Encoding ASCII
    $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
    if ($userPath -notlike "*$shimDir*") {
        $joined = if ([string]::IsNullOrWhiteSpace($userPath)) { $shimDir } else { "$userPath;$shimDir" }
        [Environment]::SetEnvironmentVariable('Path', $joined, 'User')
    }
    Write-RepairAction 'PATH shims (devready.cmd, devshell.cmd)'
}

function Repair-StandardFolders {
    $folderNames = @('Tools', 'Scripts', 'Projects', 'Logs', 'Backups', 'Security', 'Networking', 'Configs', 'Temp')
    foreach ($name in $folderNames) {
        $path = Get-HomeBasePath -Name $name
        if (-not (Test-Path $path)) {
            New-Item -ItemType Directory -Force -Path $path | Out-Null
            Write-RepairAction "Created folder: $path"
        }
    }
}

$wingetByTool = @{
    git        = @{ Id = 'Git.Git'; Name = 'Git' }
    pwsh       = @{ Id = 'Microsoft.PowerShell'; Name = 'PowerShell 7' }
    python     = @{ Id = 'Python.Python.3.12'; Name = 'Python 3.12' }
    winget     = @{ Id = 'Microsoft.AppInstaller'; Name = 'App Installer' }
    'oh-my-posh' = @{ Id = 'JanDeDobbeleer.OhMyPosh'; Name = 'Oh My Posh' }
    fzf        = @{ Id = 'junegunn.fzf'; Name = 'fzf' }
    bat        = @{ Id = 'sharkdp.bat'; Name = 'bat' }
    eza        = @{ Id = 'eza-community.eza'; Name = 'eza' }
    zoxide     = @{ Id = 'ajeetdsouza.zoxide'; Name = 'zoxide' }
    fastfetch  = @{ Id = 'Fastfetch-cli.Fastfetch'; Name = 'Fastfetch' }
}

Write-WorkstationStep 'DevReady auto-repair'
Write-Host "  Tier: $Tier | Sources: winget, PSGallery, local install scripts" -ForegroundColor DarkGray

if ($failedText -match 'Directory missing') {
    Repair-StandardFolders
}

if ($failedText -match 'profile|OMP config|Live PS7 profile|UTF-8|Windows Terminal') {
    Write-RepairAction 'Install-ShellProfile.ps1'
    & (Resolve-WorkstationScript -Name 'Install-ShellProfile.ps1' -Start $PSScriptRoot) -Force
}

if ($failedText -match 'PATH|OpenSSL|keepassxc|veracrypt') {
    Write-RepairAction 'Fix-WorkstationPath.ps1'
    & (Resolve-WorkstationScript -Name 'Fix-WorkstationPath.ps1' -Start $PSScriptRoot)
}

if ($failedText -match 'command-health|command center|WOC module|Core commands') {
    $cmdTest = Join-Path $repoRoot 'scripts\maintainer\test\Test-WorkstationCommands.ps1'
    if (Test-Path $cmdTest) {
        Write-RepairAction 'Test-WorkstationCommands.ps1 -Quick'
        & $cmdTest -Quick
    }
}

if ($failedText -match 'Module missing: PSReadLine') {
    $null = Install-PowerShellModuleSafe -Name 'PSReadLine'
}
if ($doTools -and $failedText -match 'Module missing: posh-git') {
    $null = Install-PowerShellModuleSafe -Name 'posh-git'
}
if ($doTools -and $failedText -match 'Module missing: Terminal-Icons') {
    $null = Install-PowerShellModuleSafe -Name 'Terminal-Icons'
}

if ($failedText -match 'Tool missing|git not working') {
    $coreTools = @('git')
    $fullTools = @('python', 'winget', 'oh-my-posh', 'fzf', 'bat', 'eza', 'zoxide', 'fastfetch')
    $toInstall = $coreTools + $(if ($doTools) { $fullTools } else { @() })
    foreach ($tool in $toInstall) {
        if ($failedText -notmatch $tool) { continue }
        if (Get-Command $tool -ErrorAction SilentlyContinue) { continue }
        if (-not $wingetByTool.ContainsKey($tool)) { continue }
        $pkg = $wingetByTool[$tool]
        $null = Install-WingetPackage -Id $pkg.Id -Label $pkg.Name
    }
}

if ($failedText -match 'OMP render|OMP error|Font status') {
    if ($doTools -and (Get-Command winget -ErrorAction SilentlyContinue)) {
        $null = Install-WingetPackage -Id 'JanDeDobbeleer.OhMyPosh' -Label 'Oh My Posh'
    }
    $fontScript = Resolve-WorkstationScript -Name 'Repair-WorkstationFonts.ps1' -Start $PSScriptRoot
    if (Test-Path $fontScript) {
        Write-RepairAction 'Repair-WorkstationFonts.ps1'
        & $fontScript -Force
    }
}

if ($failedText -match 'devready|devshell|shim' -or -not (Test-Path (Join-Path $env:LOCALAPPDATA 'Microsoft\WindowsApps\devready.cmd'))) {
    Repair-DevShellShims
}

$configPath = Join-Path $repoRoot 'Config\homebase.defaults.json'
if (Test-Path $configPath) {
    $cfg = Get-Content $configPath -Raw | ConvertFrom-Json
    $escaped = $repoRoot.TrimEnd('\').Replace('\', '\\')
    if ([string]$cfg.RepositoryRoot -ne $escaped) {
        $cfg.RepositoryRoot = $escaped
        $cfg | ConvertTo-Json -Depth 5 | Set-Content $configPath -Encoding UTF8
        Write-RepairAction 'Patched Config repository root'
    }
}
[Environment]::SetEnvironmentVariable('WORKSTATION_ROOT', $repoRoot, 'User')
[Environment]::SetEnvironmentVariable('HOMEBASE_DEVSHELL_ROOT', $repoRoot, 'User')
$env:WORKSTATION_ROOT = $repoRoot
$env:HOMEBASE_DEVSHELL_ROOT = $repoRoot

# Refresh PATH after winget / repair
$machinePath = [Environment]::GetEnvironmentVariable('Path', 'Machine')
$userPath    = [Environment]::GetEnvironmentVariable('Path', 'User')
$env:Path    = "$machinePath;$userPath"

Write-WorkstationStep 'Auto-repair pass complete'
Write-Host '  Re-run: devready' -ForegroundColor DarkGray
