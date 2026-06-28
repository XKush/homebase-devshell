# Shared command center infrastructure
$script:WSRoot = 'C:\Scripts\Workstation'
$script:WSLog  = 'C:\Logs\Workstation\commands.log'
$script:WSOwner = 'KGreen'

if (-not $env:WORKSTATION_LANG) { $env:WORKSTATION_LANG = 'ru' }
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
        @{ Name = 'palette';          Backend = 'palette';          Module = 'Palette';      Safe = $null }
        @{ Name = 'menu';             Backend = 'menu';             Module = 'Palette';      Safe = $null }
        @{ Name = 'toolcheck';        Backend = 'Invoke-ToolCheck'; Module = 'Network';      Safe = 'toolcheck' }
        @{ Name = 'nettools';         Backend = 'Show-NetTools';    Module = 'Network';      Safe = 'nettools' }
        @{ Name = 'toolbox';          Backend = 'Show-Toolbox';     Module = 'Network';      Safe = 'toolbox' }
        @{ Name = 'sysaudit';         Backend = 'Invoke-SysAudit';  Module = 'Network';      Safe = 'sysaudit' }
        @{ Name = 'networkstatus';    Backend = 'networkstatus';    Module = 'Network';      Safe = 'networkstatus' }
        @{ Name = 'workspace';        Backend = 'workspace';        Module = 'Workspace';    Safe = 'workspace' }
        @{ Name = 'devstart';         Backend = 'devstart';         Module = 'Workspace';    Safe = 'devstart' }
        @{ Name = 'projects';         Backend = 'projects';         Module = 'Shell';        Safe = 'projects' }
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
