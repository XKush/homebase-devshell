#Requires -Version 7.0
param([Parameter(Mandatory)][string]$Line)

$root = if ($env:WORKSTATION_ROOT -and (Test-Path $env:WORKSTATION_ROOT)) {
    $env:WORKSTATION_ROOT
} else {
    'C:\Scripts\Workstation'
}
$mod = Join-Path $root 'modules\KGreen.Workstation.psm1'
if (Test-Path $mod) { Import-Module $mod -Force -ErrorAction SilentlyContinue }

if (-not (Get-Command Get-WorkstationMenuPreviewText -ErrorAction SilentlyContinue)) {
    Write-Output $Line
    exit 0
}

Get-WorkstationMenuPreviewText -Line $Line | ForEach-Object { Write-Output $_ }
