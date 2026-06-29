# Product version SSOT helpers — read modules/KGreen.Workstation.psd1 first.
# C:\Scripts\Workstation\lib\DevShellProduct.ps1

function Get-DevShellProductVersionFromRoot {
    param([Parameter(Mandatory)][string]$RepoRoot)
    $psd1 = Join-Path $RepoRoot 'modules\KGreen.Workstation.psd1'
    if (Test-Path -LiteralPath $psd1) {
        return [string](Import-PowerShellDataFile -Path $psd1).ModuleVersion
    }
    $versionFile = Join-Path $RepoRoot 'VERSION'
    if (Test-Path -LiteralPath $versionFile) {
        return (Get-Content -LiteralPath $versionFile -Raw).Trim()
    }
    return '3.1.0'
}
