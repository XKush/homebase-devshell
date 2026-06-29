#Requires -Version 7.0
<#
.SYNOPSIS
    Dry-run plan for DevReady install — no winget, no file changes.
.DESCRIPTION
    Used by devshell init. Prints what install.ps1 would do without executing.
#>
[CmdletBinding()]
param(
    [string]$InstallPath = (Join-Path $env:USERPROFILE '.homebase\devshell'),
    [string]$RepoUrl = 'https://github.com/XKush/homebase-devshell.git',
    [switch]$SkipTools,
    [switch]$WithTools
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '..\_Resolve-RepoRoot.ps1')
$root = Resolve-WorkstationRepoRoot -Start $PSScriptRoot

$psd1 = Join-Path $root 'modules\KGreen.Workstation.psd1'
$version = if (Test-Path $psd1) { (Import-PowerShellDataFile $psd1).ModuleVersion } else { 'unknown' }
$tag = "v$version"

$installTools = if ($PSBoundParameters.ContainsKey('WithTools')) {
    $WithTools
} elseif ($PSBoundParameters.ContainsKey('SkipTools')) {
    -not $SkipTools
} else {
    $true
}

$installScript = Join-Path $root 'install.ps1'
$pin = Get-Content $installScript -Raw | Select-String -Pattern "DevShellReleaseTag = '(v[^']+)'" | ForEach-Object { $_.Matches.Groups[1].Value }
if ($pin) { $tag = $pin }

$shimDir = Join-Path $env:LOCALAPPDATA 'Microsoft\WindowsApps'
$hasGit = [bool](Get-Command git -ErrorAction SilentlyContinue)
$pwshOk = $PSVersionTable.PSVersion.Major -ge 7
$inRepo = Test-Path (Join-Path $root 'lib\HomeBasePaths.ps1')
$releaseZip = "https://github.com/XKush/homebase-devshell/releases/download/$tag/devready-$tag.zip"
$releaseSha = "https://github.com/XKush/homebase-devshell/releases/download/$tag/devready-$tag.sha256.txt"
$inspectUrl = "https://github.com/XKush/homebase-devshell/blob/$tag/install.ps1"

function Write-PlanStep {
    param([string]$Phase, [string]$Detail, [string]$Status = 'DRY-RUN')
    Write-Host ("[{0}] {1}" -f $Status, $Phase) -ForegroundColor Cyan
    if ($Detail) {
        foreach ($line in ($Detail -split "`n")) {
            Write-Host "       $line" -ForegroundColor DarkGray
        }
    }
}

Write-Host ''
Write-Host 'DevReady init — install plan (dry-run)' -ForegroundColor Green
Write-Host "Product $version · Platform spec 1.0.0 LOCKED · no changes will be made" -ForegroundColor DarkGray
Write-Host ''

Write-PlanStep 'Preflight' @(
    "PowerShell 7+: $(if ($pwshOk) { 'OK (' + $PSVersionTable.PSVersion + ')' } else { 'FAIL — install pwsh first' })"
    "git on PATH: $(if ($hasGit) { 'yes' } else { 'no — clone zip or install Git' })"
    "Repository root: $root"
    "Inspect install.ps1: $inspectUrl"
)

Write-PlanStep 'Acquire product tree' @(
    if ($inRepo) {
        "Use existing checkout (no clone): $root"
    } elseif ($hasGit) {
        "git clone --branch $tag --depth 1 $RepoUrl `"$InstallPath`""
    } else {
        "Download zip: $releaseZip"
        "Verify SHA256: $releaseSha"
        "Expand-Archive → `"$InstallPath`""
        "pwsh -File `"$InstallPath\install.ps1`" -SkipClone"
    }
)

Write-PlanStep 'User environment' @(
    "WORKSTATION_ROOT = $InstallPath"
    'HOMEBASE_DEVSHELL_ROOT = (same)'
    'WORKSTATION_LANG = en'
    "PATH shim dir: $shimDir"
    '  devshell.cmd → devshell.ps1'
    '  devready.cmd → devshell.ps1 doctor'
)

Write-PlanStep 'Bootstrap (Install-Workstation.ps1)' @(
    'Folders: Tools, Scripts, Projects, Logs, Backups, Security, Networking, Configs, Temp'
    'Backup-Configuration.ps1'
    if ($installTools) {
        'Install-Software.ps1 — winget packages (SKIPPED in Core-only / -SkipTools path)'
        '  Microsoft.PowerShell, WindowsTerminal, Git, VS Code, Python 3.12'
        '  Oh My Posh, fzf, bat, eza, zoxide, ripgrep, …'
        '  PS modules: PSReadLine, posh-git, Terminal-Icons'
    } else {
        'Install-Software.ps1 — SKIPPED (-SkipTools / Core path)'
    }
    'Install-ShellProfile.ps1 — deploy canonical profile'
    'Admin scripts — SKIPPED (OSS default -SkipAdmin)'
    'Configure-GitIdentity.ps1 · Fix-WorkstationPath.ps1'
    'Validate-Workstation — SKIPPED during product install (-SkipValidation)'
)

Write-PlanStep 'Post-bootstrap' @(
    'Test-WorkstationCommands.ps1 -Quick (command-health cache)'
    'devshell doctor -Tier Core'
)

Write-PlanStep 'You run' @(
    if ($installTools) {
        "pwsh -File `"$installScript`""
    } else {
        "pwsh -File `"$installScript`" -SkipTools"
    }
    '# or from repo:'
    'devshell install -SkipTools'
    ''
    'Then: close terminal → new window → devready'
)

Write-Host ''
Write-Host 'Nothing was installed. Run devshell install or install.ps1 when ready.' -ForegroundColor Yellow
Write-Host ''
