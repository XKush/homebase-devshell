#Requires -Version 7.0
<#
.SYNOPSIS
    Install GnuPG (OpenPGP) for encrypted messaging and file signing.
.NOTES
    Does not generate keys — run Configure-PgpIdentity.ps1 or pgp-setup after install.
#>
param([switch]$Force)

$ErrorActionPreference = 'Continue'
. (Join-Path $PSScriptRoot '..\_Resolve-RepoRoot.ps1')
$repoRoot = Resolve-WorkstationRepoRoot -Start $PSScriptRoot
$script:WSRoot = $repoRoot
. (Join-Path $repoRoot 'lib\WorkstationCommon.ps1')
Assert-DefenderUntouched

Write-WorkstationStep 'GnuPG (OpenPGP) installation'

if (Get-Command gpg -ErrorAction SilentlyContinue) {
    Write-WorkstationLog "GnuPG already present: $(gpg --version | Select-Object -First 1)" 'OK'
} else {
    $args = @('install', '-e', '--id', 'GnuPG.GnuPG', '--accept-package-agreements', '--accept-source-agreements', '--disable-interactivity')
    if ($Force) { $args += '--force' }
    $proc = Start-Process -FilePath winget -ArgumentList $args -Wait -PassThru -NoNewWindow
    if ($proc.ExitCode -notin 0, -1978335189) {
        Write-WorkstationLog "winget exit $($proc.ExitCode) for GnuPG" 'WARN'
    } else {
        Write-WorkstationLog 'GnuPG installed' 'OK'
    }
}

# Ensure PATH
$gpgBins = @(
    'C:\Program Files (x86)\GnuPG\bin'
    'C:\Program Files\GnuPG\bin'
)
. (Join-Path $PSScriptRoot '..\_Resolve-RepoRoot.ps1')
$repoRoot = Resolve-WorkstationRepoRoot -Start $PSScriptRoot
$script:WSRoot = $repoRoot
$userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
foreach ($bin in $gpgBins) {
    if ((Test-Path $bin) -and $userPath -notlike "*$bin*") {
        [Environment]::SetEnvironmentVariable('Path', "$userPath;$bin", 'User')
        $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
        Write-WorkstationLog "Added to PATH: $bin" 'OK'
    }
}

& (Resolve-WorkstationScript -Name 'Fix-WorkstationPath.ps1' -Start $PSScriptRoot) | Out-Null

Write-WorkstationStep 'Validate GnuPG'
if (Get-Command gpg -ErrorAction SilentlyContinue) {
    gpg --version | Select-Object -First 2 | ForEach-Object { Write-WorkstationLog $_ 'OK' }
    Write-Host "`n  Next: Configure-PgpIdentity.ps1  or  pgp-setup" -ForegroundColor Cyan
    exit 0
}

Write-WorkstationLog 'gpg not on PATH — open new terminal after install' 'WARN'
exit 1
