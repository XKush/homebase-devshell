# Deprecated shim — commands live in KGreen.Workstation module
# C:\Scripts\Workstation\lib\WorkstationHelpers.ps1

$mod = Join-Path (Split-Path $PSScriptRoot -Parent) 'modules\KGreen.Workstation.psm1'
if (Test-Path $mod) {
    Import-Module $mod -DisableNameChecking -Force -ErrorAction SilentlyContinue
}
