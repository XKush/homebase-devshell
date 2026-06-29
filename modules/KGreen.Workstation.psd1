@{
    RootModule        = 'KGreen.Workstation.psm1'
    ModuleVersion     = '2.1.0'
    GUID              = '7f3a9c2e-4b81-4d5f-9e0a-1c8b6d4e2f90'
    Author            = 'KGreen'
    CompanyName       = 'KGreen'
    Copyright         = '(c) 2026 KGreen. All rights reserved.'
    Description       = 'DevReady — HomeBase DevShell command center for PowerShell 7 on Windows.'
    PowerShellVersion = '7.0'
    FunctionsToExport = @(
        'projects', 'tools', 'scripts', 'downloads', 'desktop', 'backups', 'configs', 'networking', 'Open-Project', 'sysinfo', 'admin', 'instrumenty'
        'gs', 'ga', 'gc', 'gp', 'gl', 'gd', 'gco', 'gb', 'glog'
        'Enter-Venv', 'New-Venv', 'which', 'touch', 'mkcd', 'whereami', 'explain'
        'doctor', 'healthcheck', 'sysreport', 'trustcheck', 'scan', 'windowsstatus'
        'singularity', 'genesis', 'dna', 'trustchain'
        'pgp-setup', 'pgp-repair', 'pgp-status', 'pgp-export', 'pgp-fingerprint', 'pgp-encrypt', 'pgp-decrypt', 'pgp-help'
        'tor-setup', 'tor-harden', 'tor-check', 'tor-status', 'tor-browser', 'tor-help'
        'sec', 'privacy', 'sec-help', 'anon', 'Test-AnonymityKitAudit', 'revise', 'poriadok'
        'Get-OperatorDna', 'Get-SingularityScore', 'Show-SingularityCockpit', 'Show-GenesisCertificate'
        'Get-SecurityReadinessReport', 'Show-SecurityStatusPanel'
        'Get-WindowsStatusReport', 'Show-WindowsStatus'
        'palette', 'menu', 'go', 'nav', 'Invoke-CommandPalette', 'Show-HackerMenu', 'Invoke-WorkstationNavHub', 'Invoke-WorkstationGoMenu', 'Invoke-WorkstationActionMenu', 'Register-WorkstationMenuHotkeys', 'Test-WorkstationMenuIntegrity', 'Test-WorkstationGoMenuAudit'
        'Get-WorkstationCommandHealth', 'Get-WorkstationCommandRegistry'
        'Get-SystemTrustReport', 'Show-TrustReport', 'Test-CommandSelfCheck', 'Invoke-AllCommandSelfChecks'
        'Invoke-ToolCheck', 'Show-NetTools', 'Show-Toolbox', 'Invoke-SysAudit'
        'Get-WorkstationToolInventory', 'toolcheck', 'nettools', 'toolbox', 'sysaudit'
        'networkstatus', 'portscan', 'procexp', 'procmon', 'tcpview', 'cap', 'Find-SysinternalsTool'
        'cleanup', 'cleanlogs', 'updateall', 'backupconfig', 'organize'
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
    VariablesToExport = @('WSRoot', 'WSLog', 'WSOwner')
    PrivateData       = @{
        PSData = @{
            Tags         = @('DevReady', 'HomeBase', 'DevShell', 'PowerShell', 'Windows', 'health-check', 'developer-experience', 'workstation-setup')
            LicenseUri   = 'https://opensource.org/licenses/MIT'
            ProjectUri   = 'https://github.com/XKush/homebase-devshell'
            ReleaseNotes = 'DevReady v2.1.0 — public brand, devready command, docs polish.'
        }
    }
}
