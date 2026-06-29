#Requires -Version 7.0
<#
.SYNOPSIS
    Install workstation software via winget.
.NOTES
    Does NOT install or enable Microsoft Defender.
#>
param(
    [switch]$Force,
    [switch]$SkipOptional
)
. (Join-Path $PSScriptRoot '..\_Resolve-RepoRoot.ps1')
$repoRoot = Resolve-WorkstationRepoRoot -Start $PSScriptRoot
$script:WSRoot = $repoRoot

$ErrorActionPreference = 'Stop'
. (Join-Path $repoRoot 'lib\WorkstationCommon.ps1')
Assert-DefenderUntouched

$packages = @(
    @{ Id = 'Microsoft.PowerShell';          Name = 'PowerShell 7' }
    @{ Id = 'Microsoft.WindowsTerminal';     Name = 'Windows Terminal' }
    @{ Id = 'Git.Git';                       Name = 'Git' }
    @{ Id = 'Microsoft.VisualStudioCode';    Name = 'VS Code' }
    @{ Id = 'Python.Python.3.12';            Name = 'Python 3.12' }
    @{ Id = 'Microsoft.Sysinternals';        Name = 'Sysinternals Suite' }
    @{ Id = 'WiresharkFoundation.Wireshark'; Name = 'Wireshark' }
    @{ Id = 'Insecure.Nmap';                 Name = 'Nmap' }
    @{ Id = 'Fastfetch-cli.Fastfetch';       Name = 'Fastfetch' }
    @{ Id = '7zip.7zip';                     Name = '7-Zip' }
    @{ Id = 'KeePassXC.KeePassXC';            Name = 'KeePassXC' }
    @{ Id = 'Bitwarden.Bitwarden';           Name = 'Bitwarden' }
    @{ Id = 'voidtools.Everything';          Name = 'Everything' }
    @{ Id = 'Notepad++.Notepad++';           Name = 'Notepad++' }
    @{ Id = 'OBSProject.OBSStudio';          Name = 'OBS Studio' }
    @{ Id = 'JanDeDobbeleer.OhMyPosh';       Name = 'Oh My Posh' }
    @{ Id = 'junegunn.fzf';                  Name = 'fzf' }
    @{ Id = 'sharkdp.bat';                   Name = 'bat' }
    @{ Id = 'eza-community.eza';             Name = 'eza' }
    @{ Id = 'ajeetdsouza.zoxide';            Name = 'zoxide' }
)

if (-not $SkipOptional) {
    $packages += @(
        @{ Id = 'BurntSushi.ripgrep.MSVC'; Name = 'ripgrep' }
        @{ Id = 'Gyan.FFmpeg';             Name = 'FFmpeg' }
    )
}

$wingetArgs = @(
    'install', '--id', '', '-e',
    '--accept-package-agreements', '--accept-source-agreements',
    '--disable-interactivity'
)
if ($Force) { $wingetArgs += '--force' }

Write-WorkstationStep 'Installing packages via winget'
foreach ($pkg in $packages) {
    Write-Host "  -> $($pkg.Name) ($($pkg.Id))" -ForegroundColor Gray
    $args = $wingetArgs.Clone()
    $args[2] = $pkg.Id
    $proc = Start-Process -FilePath winget -ArgumentList $args -Wait -PassThru -NoNewWindow
    if ($proc.ExitCode -notin 0, -1978335189) {  # -1978335189 = already installed
        Write-WorkstationLog "winget exit $($proc.ExitCode) for $($pkg.Id)" 'WARN'
    } else {
        Write-WorkstationLog "Installed/verified $($pkg.Id)" 'OK'
    }
}

Write-WorkstationStep 'Installing PowerShell modules (user scope)'
$modules = @('PSReadLine', 'posh-git', 'Terminal-Icons')
foreach ($mod in $modules) {
    if (-not (Get-Module -ListAvailable $mod)) {
        Install-Module $mod -Scope CurrentUser -Force -AllowClobber -Repository PSGallery
        Write-WorkstationLog "Module installed: $mod" 'OK'
    } else {
        Write-WorkstationLog "Module present: $mod"
    }
}

Write-WorkstationStep 'Installing Nerd Font for terminal'
if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
    oh-my-posh font install CascadiaCode 2>&1 | Out-Null
    Write-WorkstationLog 'Caskaydia Cove Nerd Font install attempted' 'OK'
}

Write-WorkstationStep 'Software installation complete'
Write-Host @'

Single-line winget batch (re-run anytime):
  winget install -e --id Microsoft.PowerShell --id Microsoft.WindowsTerminal --id Git.Git --id Microsoft.VisualStudioCode --id Python.Python.3.12 --id Microsoft.Sysinternals --id WiresharkFoundation.Wireshark --id Insecure.Nmap --id Fastfetch-cli.Fastfetch --id 7zip.7zip --id KeePassXC.KeePassXC --id Bitwarden.Bitwarden --id voidtools.Everything --id Notepad++.Notepad++ --id OBSProject.OBSStudio --id JanDeDobbeleer.OhMyPosh --id junegunn.fzf --id sharkdp.bat --id eza-community.eza --id ajeetdsouza.zoxide --accept-package-agreements --accept-source-agreements --disable-interactivity

'@ -ForegroundColor DarkGray
