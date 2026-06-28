# Deprecated shim — WOC loaded via KGreen.Workstation Dashboard component
# C:\Scripts\Workstation\lib\WorkstationJarvis.ps1

if (-not (Get-Command Show-Woc -ErrorAction SilentlyContinue)) {
    $mod = Join-Path (Split-Path $PSScriptRoot -Parent) 'modules\KGreen.Workstation.psm1'
    if (Test-Path $mod) { Import-Module $mod -DisableNameChecking -Force -ErrorAction SilentlyContinue }
}
