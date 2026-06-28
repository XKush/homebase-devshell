#Requires -Version 7.0
param([string]$OutPath = 'C:\Scripts\Workstation\docs\ru\QUICKREF.md')

Import-Module 'C:\Scripts\Workstation\modules\KGreen.Workstation.psm1' -DisableNameChecking -Force -ErrorAction SilentlyContinue

$dir = Split-Path $OutPath -Parent
if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }

$catalog = Get-WorkstationHelpCatalog
$lines = @(
    '# HOME BASE — Quick Reference (RU)'
    ''
    "Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm')"
    ''
    '## Команды быстрого доступа'
    ''
    '| Команда | Назначение |'
    '|---------|------------|'
)

foreach ($g in @('Система','Сеть','Разработка','Обслуживание','Восстановление','Обучение')) {
    $lines += ''
    $lines += "## $g"
    $lines += ''
    $cmds = $catalog.Commands.GetEnumerator() | Where-Object { $_.Value.Group -eq $g } | Sort-Object Name
    foreach ($c in $cmds) {
        $v = $c.Value
        $lines += "- **$($c.Key)** — $($v.Description) → ``$($v.Examples[0])``"
    }
}

$lines += @(
    ''
    '## Режимы'
    ''
    '- `hack` / `menu` — max cockpit / fzf menu'
    '- `scan` — быстрый probe'
    '- `palette` — fzf palette (Ctrl+Alt+H)'
    '- `trustcheck` — live integrity'
    ''
    '## Env'
    ''
    '- WORKSTATION_STARTUP_MODE = minimal|normal|full'
    '- WORKSTATION_TRUST_MODE = strict|normal|fast'
    '- WORKSTATION_HACKER_UI = 1'
    ''
)

$lines -join "`n" | Set-Content $OutPath -Encoding UTF8
Write-Host "  Cheatsheet: $OutPath" -ForegroundColor Green
