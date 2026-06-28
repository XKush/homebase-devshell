#
# KGreen.Workstation — unified command center module
# C:\Scripts\Workstation\modules\KGreen.Workstation.psm1
#

$ModuleRoot = $PSScriptRoot
$script:WSRoot = Split-Path $ModuleRoot -Parent

$loadOrder = @(
    'Private/Common.ps1'
    'Private/Errors.ru.ps1'
    'locale/ru/Dashboard.ru.ps1'
    'locale/ru/Hints.ru.ps1'
    'locale/ru/Trust.ru.ps1'
    'locale/ru/Hacker.ru.ps1'
    'locale/ru/Genesis.ru.ps1'
    'Private/HackerUI.ps1'
    'Private/Help.ru.ps1'
    'Private/HelpSystem.ps1'
    'Private/SelfCheck.ps1'
    'Private/BootCheck.ps1'
    'Private/Scan.ps1'
    'Private/CommandPalette.ps1'
    'Private/WindowsStatus.ps1'
    'Private/Pgp.ps1'
    'Private/TorSecurity.ps1'
    'Private/PrivacyMenu.ps1'
    'Private/Revision.ps1'
    'Shell.ps1'
    'Diagnostics.ps1'
    'Private/Genesis.ps1'
    'Private/Singularity.ps1'
    'Private/TrustSystem.ps1'
    'Network.ps1'
    'Maintenance.ps1'
    'Learning.ps1'
    'Recovery.ps1'
    'Workspace.ps1'
    'Dashboard.ps1'
    'HomeBase.ps1'
)

foreach ($rel in $loadOrder) {
    $path = Join-Path $ModuleRoot $rel
    if (-not (Test-Path $path)) {
        Write-Warning "KGreen.Workstation: missing component $rel"
        continue
    }
    . $path
}

$public = @(
    'projects', 'tools', 'scripts', 'Open-Project', 'sysinfo', 'admin', 'instrumenty'
    'gs', 'ga', 'gc', 'gp', 'gl', 'gd', 'gco', 'gb', 'glog'
    'Enter-Venv', 'New-Venv', 'which', 'touch', 'mkcd', 'whereami', 'explain'
    'doctor', 'healthcheck', 'sysreport', 'trustcheck', 'scan', 'windowsstatus'
    'singularity', 'genesis', 'dna', 'trustchain'
    'pgp-setup', 'pgp-repair', 'pgp-status', 'pgp-export', 'pgp-fingerprint', 'pgp-encrypt', 'pgp-decrypt', 'pgp-help'
    'tor-setup', 'tor-harden', 'tor-check', 'tor-status', 'tor-lock', 'tor-unlock', 'tor-help'
    'sec', 'privacy', 'sec-help', 'revise', 'poriadok'
    'Get-OperatorDna', 'Get-SingularityScore', 'Show-SingularityCockpit', 'Show-GenesisCertificate'
    'Get-SecurityReadinessReport', 'Show-SecurityStatusPanel'
    'Get-WindowsStatusReport', 'Show-WindowsStatus'
    'palette', 'menu', 'Invoke-CommandPalette', 'Show-HackerMenu'
    'Get-WorkstationCommandHealth', 'Get-WorkstationCommandRegistry'
    'Get-SystemTrustReport', 'Show-TrustReport', 'Test-CommandSelfCheck', 'Invoke-AllCommandSelfChecks'
    'Invoke-ToolCheck', 'Show-NetTools', 'Show-Toolbox', 'Invoke-SysAudit'
    'Get-WorkstationToolInventory', 'toolcheck', 'nettools', 'toolbox', 'sysaudit'
    'networkstatus', 'portscan', 'procexp', 'procmon', 'tcpview', 'cap', 'Find-SysinternalsTool'
    'cleanup', 'cleanlogs', 'updateall', 'backupconfig'
    'help', 'helpme', 'cheatsheet', 'quickstart', 'learn', 'komandy'
    'repairterminal', 'fixprofile', 'reloadprofile', 'restoreconfig'
    'workspace', 'devstart', 'logs', 'securitycheck', 'new-project', 'devinfo'
    'Show-Woc', 'Show-Jarvis', 'Show-WorkstationDashboard', 'Show-StartupCommandCenter'
    'Show-HomeBase', 'Show-CommandGroupsRu', 'Show-SystemToolsPanel', 'Show-WorkstationCommandHelp'
    'Get-WorkstationHelpCatalog'
    'workstationstatus', 'jarvis', 'dashboard', 'home', 'hack'
    'Write-CommandLog', 'Invoke-WorkstationCmd', 'Write-CommandHint', 'Get-HomeBaseTexts'
    'Test-HackerUIEnabled', 'Format-HackerBar', 'Write-HackerBanner', 'Show-HackerCommandMatrix'
)

Export-ModuleMember -Function $public -Variable WSRoot, WSLog, WSOwner
