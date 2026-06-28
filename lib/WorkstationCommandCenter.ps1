# Deprecated shim — use Import-Module KGreen.Workstation
# C:\Scripts\Workstation\lib\WorkstationCommandCenter.ps1

$mod = Join-Path (Split-Path $PSScriptRoot -Parent) 'modules\KGreen.Workstation.psm1'
if (Test-Path $mod) {
    Import-Module $mod -DisableNameChecking -Force -ErrorAction SilentlyContinue
}
