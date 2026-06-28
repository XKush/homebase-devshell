# Самопроверка команд — каждая команда проверяет себя до и после выполнения

$script:SelfCheckDeps = @{
    doctor          = @('Validate-Workstation.ps1')
    sysreport       = @('Validate-Workstation.ps1', 'Invoke-SystemDiscovery.ps1')
    nettools        = @('Show-NetTools', 'Invoke-ToolCheck')
    toolcheck       = @('Invoke-ToolCheck', 'Get-WorkstationToolInventory')
    toolbox         = @('Show-Toolbox')
    sysaudit        = @('Invoke-OrganizationAudit.ps1', 'Invoke-SystemDiscovery.ps1')
    backupconfig    = @('Backup-Configuration.ps1')
    repairterminal  = @('Invoke-TerminalRecovery.ps1')
    restoreconfig   = @('Rollback-Workstation.ps1')
    home            = @('Show-HomeBase', 'Build-WocReport')
    hack            = @('Show-HomeBase', 'Build-WocReport')
    jarvis          = @('Show-HomeBase')
    trustcheck      = @('Get-SystemTrustReport')
    scan            = @('Invoke-QuickScan', 'Get-SystemTrustReport')
    windowsstatus   = @('Get-WindowsStatusReport', 'Show-WindowsStatus')
    singularity     = @('Show-SingularityCockpit', 'Get-OperatorDna', 'Add-TrustChainBlock')
    genesis         = @('Get-OperatorDna', 'Export-GenesisCertificate', 'Add-TrustChainBlock')
    dna             = @('Get-OperatorDna')
    trustchain      = @('Test-TrustChainIntegrity', 'Show-TrustChain')
    palette         = @('Invoke-CommandPalette', 'Get-WorkstationHelpCatalog')
    menu            = @('Show-HackerMenu')
    sec             = @('Get-SecurityReadinessReport', 'Show-SecurityStatusPanel')
    privacy         = @('Get-SecurityReadinessReport', 'Show-SecurityStatusPanel')
    'sec-help'      = @('Show-SecurityHelpRu')
    'tor-check'     = @('Invoke-TorPreflightCheck')
    'tor-status'    = @('Find-TorBrowserExe', 'Get-TorSecurityState')
    'pgp-status'    = @('Get-PgpIdentityMeta')
    'pgp-repair'    = @('Repair-PgpIdentity.ps1')
    revise          = @('Invoke-WorkstationRevision.ps1')
    poriadok        = @('Invoke-WorkstationRevision.ps1')
    instrumenty     = @('Show-SystemToolsPanel', 'Get-WorkstationToolInventory')
    komandy         = @('Show-CommandGroupsRu', 'Get-WorkstationHelpCatalog')
}

function Test-CommandSelfCheck {
    param(
        [Parameter(Mandatory)][string]$Name,
        [ValidateSet('Pre', 'Post')][string]$Phase = 'Pre'
    )

    $result = [ordered]@{
        Command = $Name
        Phase   = $Phase
        OK      = $true
        Detail  = $null
        Checks  = @()
    }

    # 1. Команда существует
    $cmd = Get-Command $Name -ErrorAction SilentlyContinue
    if (-not $cmd) {
        $result.OK = $false
        $result.Detail = "Команда ``$Name`` не найдена в сессии"
        return [PSCustomObject]$result
    }
    $result.Checks += 'command_exists'

    # 2. Backend из реестра
    $entry = @(Get-WorkstationCommandRegistry | Where-Object { $_.Name -eq $Name } | Select-Object -First 1)
    if ($entry) {
        $backend = $entry.Backend
        if ($backend -ne $Name) {
            $be = Get-Command $backend -ErrorAction SilentlyContinue
            if (-not $be) {
                $result.OK = $false
                $result.Detail = "Backend ``$backend`` не загружен для ``$Name``"
                return [PSCustomObject]$result
            }
            $result.Checks += 'backend_exists'
        }
    }

    # 3. Параметр -help (Post-фаза — опционально мягче)
    if ($Phase -eq 'Pre' -and $cmd.Parameters -and -not $cmd.Parameters.ContainsKey('Help')) {
        $result.OK = $false
        $result.Detail = "У ``$Name`` нет параметра -help (считается сломанной)"
        return [PSCustomObject]$result
    }
    if ($cmd.Parameters.ContainsKey('Help')) { $result.Checks += 'help_param' }

    # 4. Зависимости (файлы и функции)
    if ($script:SelfCheckDeps.ContainsKey($Name)) {
        foreach ($dep in $script:SelfCheckDeps[$Name]) {
            if ($dep -match '\.ps1$') {
                $path = Join-Path $script:WSRoot $dep
                if (-not (Test-Path $path)) {
                    $result.OK = $false
                    $result.Detail = "Файл ``$dep`` отсутствует"
                    return [PSCustomObject]$result
                }
                $result.Checks += "file:$dep"
            } else {
                if (-not (Get-Command $dep -ErrorAction SilentlyContinue)) {
                    $result.OK = $false
                    $result.Detail = "Зависимость ``$dep`` не найдена"
                    return [PSCustomObject]$result
                }
                $result.Checks += "fn:$dep"
            }
        }
    }

    return [PSCustomObject]$result
}

function Invoke-AllCommandSelfChecks {
    $registry = Get-WorkstationCommandRegistry
    $results = foreach ($entry in $registry) {
        $pre = Test-CommandSelfCheck -Name $entry.Name -Phase Pre
        [PSCustomObject]@{
            Command = $entry.Name
            OK      = $pre.OK
            Detail  = $pre.Detail
            Checks  = @($pre.Checks)
        }
    }
    return @($results)
}
