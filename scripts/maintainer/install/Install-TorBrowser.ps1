#Requires -Version 7.0
<#
.SYNOPSIS
    Install Tor Browser (official bundle).
#>
param([switch]$Force)

$ErrorActionPreference = 'Continue'
. (Join-Path $PSScriptRoot '..\_Resolve-RepoRoot.ps1')
$repoRoot = Resolve-WorkstationRepoRoot -Start $PSScriptRoot
$script:WSRoot = $repoRoot
. (Join-Path $repoRoot 'lib\WorkstationCommon.ps1')
. (Join-Path $repoRoot 'lib\TorCommon.ps1')
Assert-DefenderUntouched

Write-WorkstationStep 'Tor Browser installation'

$torExe = Find-TorBrowserExe
if ($torExe -and -not $Force) {
    Write-WorkstationLog "Tor Browser already present: $torExe" 'OK'
    exit 0
}

$args = @(
    'install', '-e', '--id', 'TorProject.TorBrowser'
    '--accept-package-agreements', '--accept-source-agreements', '--disable-interactivity'
)
. (Join-Path $PSScriptRoot '..\_Resolve-RepoRoot.ps1')
$repoRoot = Resolve-WorkstationRepoRoot -Start $PSScriptRoot
$script:WSRoot = $repoRoot
if ($Force) { $args += '--force' }
$proc = Start-Process -FilePath winget -ArgumentList $args -Wait -PassThru -NoNewWindow
if ($proc.ExitCode -notin 0, -1978335189) {
    Write-WorkstationLog "winget exit $($proc.ExitCode) for Tor Browser" 'WARN'
} else {
    Write-WorkstationLog 'Tor Browser installed' 'OK'
}

$torExe = Find-TorBrowserExe
if ($torExe) {
    Write-WorkstationLog "Path: $torExe" 'OK'
    Write-Host "`n  Next: tor-harden  or  Configure-TorSecurity.ps1" -ForegroundColor Cyan
    exit 0
}

Write-WorkstationLog 'Tor Browser not found — install manually from torproject.org' 'WARN'
exit 1
