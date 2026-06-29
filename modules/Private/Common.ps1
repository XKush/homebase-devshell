# Shared command center infrastructure
if (-not $script:WSRoot) { $script:WSRoot = 'C:\Scripts\Workstation' }

function Get-WorkstationCommandsLogPath {
    if (Get-Command Get-HomeBasePath -ErrorAction SilentlyContinue) {
        return Join-Path (Get-HomeBasePath -Name Logs) 'commands.log'
    }
    return 'C:\Logs\Workstation\commands.log'
}

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
    if (Get-Module KGreen.Workstation) { return $true }
    if ((Get-Command Get-WorkstationCommandHealth, Test-ShowCommandHelp -ErrorAction SilentlyContinue).Count -ge 2) {
        return $true
    }
    $modPath = Join-Path $script:WSRoot 'modules\KGreen.Workstation.psm1'
    if (-not (Test-Path $modPath)) { return $false }
    Import-Module $modPath -DisableNameChecking -Force -Scope Global -ErrorAction SilentlyContinue
    return [bool](Get-Module KGreen.Workstation)
}
$script:WSLog  = Get-WorkstationCommandsLogPath
$script:WSOwner = 'KGreen'

if (-not $env:WORKSTATION_LANG) { $env:WORKSTATION_LANG = 'en' }
if (-not $env:WORKSTATION_TRUST_MODE) { $env:WORKSTATION_TRUST_MODE = 'strict' }

function Write-CommandLog {
    param([string]$Command, [string]$Result, [string]$Detail = '')
    $dir = Split-Path $script:WSLog -Parent
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
    $line = "[{0}] {1} -> {2} {3}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Command, $Result, $Detail
    Add-Content -Path $script:WSLog -Value $line -Encoding UTF8
}

function Invoke-WorkstationCmd {
    param(
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][scriptblock]$Action,
        [switch]$SkipSelfCheck
    )

    if (-not $SkipSelfCheck -and (Get-Command Test-CommandSelfCheck -ErrorAction SilentlyContinue)) {
        $pre = Test-CommandSelfCheck -Name $Name -Phase Pre
        if (-not $pre.OK) {
            $msg = if (Get-Command Get-TrustMessage -ErrorAction SilentlyContinue) {
                Get-TrustMessage 'SelfCheckFailed' -Detail $pre.Detail
            } else { "Самопроверка: $($pre.Detail)" }
            Write-Host $msg -ForegroundColor Red
            Write-CommandLog $Name 'FAIL' "precheck: $($pre.Detail)"
            throw $msg
        }
    }

    try {
        & $Action

        if (-not $SkipSelfCheck -and (Get-Command Test-CommandSelfCheck -ErrorAction SilentlyContinue)) {
            $post = Test-CommandSelfCheck -Name $Name -Phase Post
            if (-not $post.OK) {
                Write-CommandLog $Name 'WARN' "postcheck: $($post.Detail)"
            }
        }

        Write-CommandLog $Name 'OK'

        if (Get-Command Write-CommandHint -ErrorAction SilentlyContinue) {
            Write-CommandHint -Name $Name
        }
    } catch {
        if ($_.Exception.Message -match 'Самопроверка') { throw }
        if (Get-Command Translate-WorkstationError -ErrorAction SilentlyContinue) {
            Write-Host (Translate-WorkstationError -Message $_.Exception.Message -Command $Name) -ForegroundColor Red
        } else {
            Write-Host "Ошибка в ${Name}: $($_.Exception.Message)" -ForegroundColor Red
            Write-Host 'Подсказка: doctor · trustcheck · repairterminal' -ForegroundColor DarkGray
        }
        Write-CommandLog $Name 'FAIL' $_.Exception.Message
        throw
    }
}

function Get-WorkstationCommandRegistry {
    return @(
        @{ Name = 'doctor';           Backend = 'doctor';           Module = 'Diagnostics';  Safe = '$env:CI=1; doctor' }
        @{ Name = 'healthcheck';      Backend = 'healthcheck';      Module = 'Diagnostics';  Safe = 'healthcheck' }
        @{ Name = 'sysreport';        Backend = 'sysreport';        Module = 'Diagnostics';  Safe = 'sysreport' }
        @{ Name = 'trustcheck';       Backend = 'trustcheck';       Module = 'Trust';        Safe = 'trustcheck' }
        @{ Name = 'scan';             Backend = 'scan';             Module = 'Scan';         Safe = 'scan -Quiet' }
        @{ Name = 'windowsstatus';    Backend = 'windowsstatus';    Module = 'Windows';     Safe = 'windowsstatus -Quiet' }
        @{ Name = 'singularity';      Backend = 'singularity';      Module = 'Genesis';     Safe = $null }
        @{ Name = 'genesis';          Backend = 'genesis';          Module = 'Genesis';     Safe = $null }
        @{ Name = 'dna';              Backend = 'dna';              Module = 'Genesis';     Safe = 'dna' }
        @{ Name = 'trustchain';       Backend = 'trustchain';       Module = 'Genesis';     Safe = 'trustchain' }
        @{ Name = 'sec';              Backend = 'sec';              Module = 'Privacy';      Safe = 'sec -Status' }
        @{ Name = 'anon';             Backend = 'anon';             Module = 'Privacy';      Safe = 'anon -Audit' }
        @{ Name = 'sec-help';         Backend = 'sec-help';         Module = 'Privacy';      Safe = 'sec-help' }
        @{ Name = 'revise';           Backend = 'revise';           Module = 'Revision';    Safe = 'revise -Quick' }
        @{ Name = 'poriadok';         Backend = 'poriadok';         Module = 'Revision';    Safe = 'revise -Quick' }
        @{ Name = 'organize';         Backend = 'organize';         Module = 'Maintenance'; Safe = 'organize -WhatIf' }
        @{ Name = 'privacy';          Backend = 'privacy';          Module = 'Privacy';      Safe = 'sec -Status' }
        @{ Name = 'pgp-setup';        Backend = 'pgp-setup';        Module = 'Pgp';          Safe = $null }
        @{ Name = 'pgp-repair';       Backend = 'pgp-repair';       Module = 'Pgp';          Safe = $null }
        @{ Name = 'pgp-status';       Backend = 'pgp-status';       Module = 'Pgp';          Safe = 'pgp-status' }
        @{ Name = 'pgp-export';       Backend = 'pgp-export';       Module = 'Pgp';          Safe = $null }
        @{ Name = 'pgp-fingerprint';  Backend = 'pgp-fingerprint';  Module = 'Pgp';          Safe = 'pgp-fingerprint' }
        @{ Name = 'pgp-help';         Backend = 'pgp-help';         Module = 'Pgp';          Safe = 'pgp-help' }
        @{ Name = 'pgp-encrypt';      Backend = 'pgp-encrypt';      Module = 'Pgp';          Safe = $null }
        @{ Name = 'pgp-decrypt';      Backend = 'pgp-decrypt';      Module = 'Pgp';          Safe = $null }
        @{ Name = 'tor-setup';        Backend = 'tor-setup';        Module = 'Tor';          Safe = $null }
        @{ Name = 'tor-harden';       Backend = 'tor-harden';       Module = 'Tor';          Safe = $null }
        @{ Name = 'tor-check';        Backend = 'tor-check';        Module = 'Tor';          Safe = 'tor-check' }
        @{ Name = 'tor-browser';      Backend = 'tor-browser';      Module = 'Tor';          Safe = 'tor-browser' }
        @{ Name = 'tor-status';       Backend = 'tor-status';       Module = 'Tor';          Safe = 'tor-status' }
        @{ Name = 'tor-help';         Backend = 'tor-help';         Module = 'Tor';          Safe = 'tor-help' }
        @{ Name = 'palette';          Backend = 'palette';          Module = 'Palette';      Safe = $null }
        @{ Name = 'menu';             Backend = 'menu';             Module = 'Palette';      Safe = $null }
        @{ Name = 'go';               Backend = 'go';               Module = 'Palette';      Safe = $null }
        @{ Name = 'nav';              Backend = 'nav';              Module = 'Palette';      Safe = $null }
        @{ Name = 'toolcheck';        Backend = 'Invoke-ToolCheck'; Module = 'Network';      Safe = 'toolcheck' }
        @{ Name = 'nettools';         Backend = 'Show-NetTools';    Module = 'Network';      Safe = 'nettools' }
        @{ Name = 'toolbox';          Backend = 'Show-Toolbox';     Module = 'Network';      Safe = 'toolbox' }
        @{ Name = 'sysaudit';         Backend = 'Invoke-SysAudit';  Module = 'Network';      Safe = 'sysaudit' }
        @{ Name = 'networkstatus';    Backend = 'networkstatus';    Module = 'Network';      Safe = 'networkstatus' }
        @{ Name = 'portscan';         Backend = 'portscan';         Module = 'Network';      Safe = 'portscan -Help' }
        @{ Name = 'workspace';        Backend = 'workspace';        Module = 'Workspace';    Safe = 'workspace' }
        @{ Name = 'devstart';         Backend = 'devstart';         Module = 'Workspace';    Safe = 'devstart' }
        @{ Name = 'projects';         Backend = 'projects';         Module = 'Shell';        Safe = 'projects' }
        @{ Name = 'downloads';        Backend = 'downloads';        Module = 'Shell';        Safe = 'downloads' }
        @{ Name = 'desktop';           Backend = 'desktop';          Module = 'Shell';        Safe = 'desktop' }
        @{ Name = 'backups';          Backend = 'backups';          Module = 'Shell';        Safe = 'backups' }
        @{ Name = 'configs';          Backend = 'configs';          Module = 'Shell';        Safe = 'configs' }
        @{ Name = 'networking';       Backend = 'networking';       Module = 'Shell';        Safe = 'networking' }
        @{ Name = 'cleanup';          Backend = 'cleanup';          Module = 'Maintenance';  Safe = 'cleanup -WhatIf' }
        @{ Name = 'backupconfig';     Backend = 'backupconfig';     Module = 'Maintenance';  Safe = 'backupconfig' }
        @{ Name = 'restoreconfig';    Backend = 'restoreconfig';    Module = 'Recovery';     Safe = 'restoreconfig' }
        @{ Name = 'repairterminal';   Backend = 'repairterminal';   Module = 'Recovery';     Safe = $null }
        @{ Name = 'securitycheck';    Backend = 'securitycheck';    Module = 'Workspace';    Safe = 'securitycheck' }
        @{ Name = 'learn';            Backend = 'learn';            Module = 'Learning';     Safe = 'learn -Topic git' }
        @{ Name = 'cheatsheet';       Backend = 'cheatsheet';       Module = 'Learning';     Safe = 'cheatsheet' }
        @{ Name = 'quickstart';       Backend = 'quickstart';       Module = 'Learning';     Safe = 'quickstart' }
        @{ Name = 'helpme';           Backend = 'helpme';           Module = 'Learning';     Safe = 'helpme' }
        @{ Name = 'logs';             Backend = 'logs';             Module = 'Workspace';    Safe = 'logs' }
        @{ Name = 'jarvis';           Backend = 'Show-HomeBase';    Module = 'Dashboard';    Safe = 'Show-HomeBase -Mode minimal -Force -NoHeal' }
        @{ Name = 'dashboard';        Backend = 'dashboard';        Module = 'Dashboard';    Safe = 'dashboard' }
        @{ Name = 'home';             Backend = 'home';             Module = 'Dashboard';    Safe = 'home' }
        @{ Name = 'hack';             Backend = 'hack';             Module = 'Dashboard';    Safe = 'hack' }
        @{ Name = 'workstationstatus'; Backend = 'workstationstatus'; Module = 'Dashboard'; Safe = 'workstationstatus -Mode minimal' }
        @{ Name = 'updateall';        Backend = 'updateall';        Module = 'Maintenance';  Safe = $null }
        @{ Name = 'new-project';      Backend = 'new-project';      Module = 'Workspace';    Safe = $null }
        @{ Name = 'devinfo';          Backend = 'devinfo';          Module = 'Workspace';    Safe = 'devinfo' }
        @{ Name = 'sysinfo';          Backend = 'sysinfo';          Module = 'Shell';        Safe = 'sysinfo' }
        @{ Name = 'fixprofile';       Backend = 'fixprofile';       Module = 'Recovery';     Safe = $null }
        @{ Name = 'reloadprofile';    Backend = 'reloadprofile';    Module = 'Recovery';     Safe = $null }
        @{ Name = 'komandy';          Backend = 'komandy';          Module = 'Learning';     Safe = 'komandy' }
        @{ Name = 'instrumenty';      Backend = 'instrumenty';      Module = 'Shell';        Safe = 'instrumenty' }
    )
}
