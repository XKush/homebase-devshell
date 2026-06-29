#Requires -Version 7.0
<#
.SYNOPSIS
    Sync docs/ru from live help catalog + registry drift check.
#>
param(
    [switch]$DocsOnly,
    [switch]$CheckOnly
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '..\_Resolve-RepoRoot.ps1')
$repoRoot = Resolve-WorkstationRepoRoot -Start $PSScriptRoot
$script:WSRoot = $repoRoot
. (Join-Path $repoRoot 'lib\WorkstationCommon.ps1')
$wsRoot = Get-HomeBasePath -Name RepositoryRoot
Ensure-WorkstationModuleLoaded -Root $wsRoot | Out-Null

$catalog = Get-WorkstationHelpCatalog
$registry = Get-WorkstationCommandRegistry
$exported = (Get-Command -Module KGreen.Workstation).Name

$drift = [System.Collections.Generic.List[string]]::new()
foreach ($entry in $registry) {
    if ($exported -notcontains $entry.Name) {
        $drift.Add("registry → export missing: $($entry.Name)")
    }
    if (-not $catalog.Commands.ContainsKey($entry.Name)) {
        $drift.Add("registry → help missing: $($entry.Name)")
    }
}

$groupOrder = @('Система', 'Безопасность', 'Сеть', 'Разработка', 'Обслуживание', 'Восстановление', 'Обучение', 'Навигация')

if (-not $CheckOnly) {
    $quickPath = Join-Path $wsRoot 'docs\ru\QUICKREF.md'
    $cmdPath = Join-Path $wsRoot 'docs\ru\COMMANDS.md'
    $stamp = Get-Date -Format 'yyyy-MM-dd HH:mm'

    $quick = @(
        '# HOME BASE — Quick Reference (RU)'
        ''
        "Generated: $stamp"
        ''
        '## Быстрый доступ'
        ''
        '| Команда | Назначение |'
        '|---------|------------|'
        '| `sec` | Tor + PGP |'
        '| `menu` | Главное меню |'
        '| `palette` | Поиск команд (fzf) |'
        '| `trustcheck` | Live integrity |'
        '| `tor-check` | Preflight Tor |'
        ''
    )

    foreach ($g in $groupOrder) {
        $quick += ''
        $quick += "## $g"
        $quick += ''
        $cmds = $catalog.Commands.GetEnumerator() | Where-Object { $_.Value.Group -eq $g } | Sort-Object Name
        foreach ($c in $cmds) {
            $v = $c.Value
            $quick += "- **$($c.Key)** — $($v.Description) → ``$($v.Examples[0])``"
        }
    }

    $quick += @(
        ''
        '## Tor + PGP — порядок'
        ''
        '1. `sec` или `tor-check`'
        '2. `tor-harden` (один раз)'
        '3. Tor Browser + `pgp-fingerprint`'
        '4. закрой Tor Browser после сессии'
        ''
        '## Переменные'
        ''
        '- WORKSTATION_STARTUP_MODE = minimal|normal|full'
        '- WORKSTATION_TRUST_MODE = strict|normal|fast'
        '- WORKSTATION_HACKER_UI = 1'
        ''
    )

    $commands = @(
        '# Команды HOME BASE'
        ''
        "Generated: $stamp"
        ''
        'Справка: ``имя -help`` · меню: ``sec`` · ``menu``'
        ''
    )

    foreach ($g in $groupOrder) {
        $desc = $catalog.Groups[$g]
        $commands += "## $g"
        if ($desc) { $commands += '' ; $commands += "_$desc_" ; $commands += '' }
        $commands += '| Команда | Описание |'
        $commands += '|---------|----------|'
        $cmds = $catalog.Commands.GetEnumerator() | Where-Object { $_.Value.Group -eq $g } | Sort-Object Name
        foreach ($c in $cmds) {
            $commands += "| ``$($c.Key)`` | $($c.Value.Description) |"
        }
        $commands += ''
    }

    $quick -join "`n" | Set-Content $quickPath -Encoding UTF8
    $commands -join "`n" | Set-Content $cmdPath -Encoding UTF8
    Write-Host "  Docs synced: $quickPath" -ForegroundColor Green
    Write-Host "  Docs synced: $cmdPath" -ForegroundColor Green
}

if ($drift.Count) {
    Write-Host "  Registry drift ($($drift.Count)):" -ForegroundColor Yellow
    $drift | ForEach-Object { Write-Host "    $_" -ForegroundColor Yellow }
    if ($CheckOnly) { exit 1 }
} else {
    Write-Host '  Registry/help/export: OK' -ForegroundColor Green
}

if ($CheckOnly) { exit 0 }
