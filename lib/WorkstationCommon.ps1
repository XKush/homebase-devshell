# Workstation setup shared helpers
# C:\Scripts\Workstation\lib\WorkstationCommon.ps1

$pathsLib = Join-Path $PSScriptRoot 'HomeBasePaths.ps1'
if (Test-Path $pathsLib) { . $pathsLib }

function Get-WorkstationLogsRoot {
    if (Get-Command Get-HomeBasePath -ErrorAction SilentlyContinue) {
        return Get-HomeBasePath -Name Logs
    }
    return 'C:\Logs\Workstation'
}

function Get-WorkstationBackupsRoot {
    if (Get-Command Get-HomeBasePath -ErrorAction SilentlyContinue) {
        return Get-HomeBasePath -Name Backups
    }
    return 'C:\Backups\Workstation'
}

function Ensure-WorkstationModuleLoaded {
    param([string]$Root = 'C:\Scripts\Workstation')
    if (Get-Module KGreen.Workstation) { return $true }
    if ((Get-Command Get-WorkstationCommandHealth, Test-ShowCommandHelp -ErrorAction SilentlyContinue).Count -ge 2) {
        return $true
    }
    $modPath = Join-Path $Root 'modules\KGreen.Workstation.psm1'
    if (-not (Test-Path $modPath)) { return $false }
    Import-Module $modPath -DisableNameChecking -Force -Scope Global -ErrorAction Stop
    return [bool](Get-Module KGreen.Workstation)
}

function Test-WorkstationAdmin {
    $current = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
    return $current.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Assert-WorkstationAdmin {
    if (-not (Test-WorkstationAdmin)) {
        throw 'This script requires Administrator privileges. Run: Start-Process pwsh -Verb RunAs -ArgumentList ''-File ...'''
    }
}

function Get-WorkstationLogPath {
    param([string]$Name)
    $dir = Get-WorkstationLogsRoot
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
    return Join-Path $dir $Name
}

function Write-WorkstationLog {
    param(
        [string]$Message,
        [ValidateSet('INFO', 'WARN', 'ERROR', 'OK')]
        [string]$Level = 'INFO'
    )
    $line = "[{0}] [{1}] {2}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Level, $Message
    $logFile = Get-WorkstationLogPath 'workstation.log'
    Add-Content -Path $logFile -Value $line -Encoding UTF8
    $color = switch ($Level) {
        'OK'    { 'Green' }
        'WARN'  { 'Yellow' }
        'ERROR' { 'Red' }
        default { 'Gray' }
    }
    Write-Host $line -ForegroundColor $color
}

function Write-WorkstationStep {
    param([string]$Title)
    Write-Host ''
    Write-Host "==> $Title" -ForegroundColor Cyan
    Write-WorkstationLog $Title
}

function Backup-RegistryKey {
    param(
        [Parameter(Mandatory)][string]$Path,
        [string]$Label
    )
    $backupRoot = Join-Path (Get-WorkstationBackupsRoot) 'registry'
    if (-not (Test-Path $backupRoot)) {
        New-Item -ItemType Directory -Force -Path $backupRoot | Out-Null
    }
    $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
    $name = if ($Label) { $Label } else { ($Path -replace '[\\:*?"<>|]', '_') }
    $out = Join-Path $backupRoot "$stamp-$name.reg"
    $result = reg export $Path $out /y 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-WorkstationLog "Registry backup: $out" 'OK'
        return $out
    }
    Write-WorkstationLog "Registry backup skipped for $Path : $result" 'WARN'
    return $null
}

function Set-RegistryValueSafe {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)]$Value,
        [ValidateSet('String', 'ExpandString', 'DWord', 'QWord', 'MultiString', 'Binary')]
        [string]$Type = 'DWord'
    )
    if (-not (Test-Path $Path)) {
        New-Item -Path $Path -Force | Out-Null
        Write-WorkstationLog "Created registry path: $Path"
    }
    $existing = Get-ItemProperty -Path $Path -Name $Name -ErrorAction SilentlyContinue
    if ($null -eq $existing) {
        New-ItemProperty -Path $Path -Name $Name -Value $Value -PropertyType $Type -Force | Out-Null
    } else {
        Set-ItemProperty -Path $Path -Name $Name -Value $Value -Type $Type
    }
    Write-WorkstationLog "Set $Path\$Name = $Value"
}

function Invoke-WorkstationScript {
    param(
        [Parameter(Mandatory)][string]$Path,
        [hashtable]$Parameters = @{}
    )
    if (-not (Test-Path $Path)) { throw "Missing script: $Path" }
    Write-WorkstationStep (Split-Path $Path -Leaf)
    & $Path @Parameters
}

function Confirm-WorkstationAction {
    param(
        [string]$Message = 'Apply workstation changes?',
        [switch]$Force
    )
    if ($Force) { return $true }
    $answer = Read-Host "$Message [y/N]"
    return $answer -match '^(y|yes)$'
}

# Explicit policy: never touch Microsoft Defender AV
function Assert-DefenderUntouched {
    Write-WorkstationLog 'Policy: Microsoft Defender AV must remain disabled — no Defender enable/install actions in this suite.' 'INFO'
}

function Initialize-OpenSslPath {
    if (Get-Command openssl -ErrorAction SilentlyContinue) { return $true }
    foreach ($bin in @('C:\Program Files\OpenSSL-Win64\bin', 'C:\Program Files\OpenSSL\bin')) {
        if (Test-Path (Join-Path $bin 'openssl.exe')) {
            if ($env:Path -notlike "*$bin*") { $env:Path = "$env:Path;$bin" }
            return $true
        }
    }
    return $false
}
