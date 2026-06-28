# Система самодокументирования команд HOME BASE

function Show-WorkstationCommandHelp {
    param(
        [Parameter(Mandatory)][string]$Name
    )

    $catalog = Get-WorkstationHelpCatalog
    $entry = $catalog.Commands[$Name]

    if (-not $entry) {
        Write-Host "`n  Справка для ``$Name`` не найдена." -ForegroundColor Yellow
        Write-Host "  Попробуйте: komandy | helpme | home`n" -ForegroundColor DarkGray
        return
    }

    $related = ($entry.Related | ForEach-Object { $_ }) -join ', '

    Write-Host ''
    Write-Host '  --------------------------------' -ForegroundColor DarkCyan
    Write-Host "  Название:     $($entry.Title)" -ForegroundColor Cyan
    Write-Host "  Описание:     $($entry.Description)" -ForegroundColor White
    Write-Host "  Что делает:   $($entry.Does)" -ForegroundColor White
    Write-Host "  Когда:        $($entry.When)" -ForegroundColor White
    Write-Host "  Как запускать: $($entry.How)" -ForegroundColor Green
    Write-Host "  Группа:       [$($entry.Group)]" -ForegroundColor Yellow
    Write-Host '  Примеры:' -ForegroundColor White
    foreach ($ex in $entry.Examples) {
        Write-Host "    $ex" -ForegroundColor DarkGray
    }
    Write-Host "  Связанные:    $related" -ForegroundColor DarkGray
    Write-Host '  --------------------------------' -ForegroundColor DarkCyan
    Write-Host "  Подсказка: любая команда поддерживает ``имя -help``" -ForegroundColor DarkGray
    Write-Host ''
}

function Test-ShowCommandHelp {
    param(
        [Parameter(Mandatory)][string]$Name,
        [switch]$Help
    )
    if ($Help) {
        Show-WorkstationCommandHelp -Name $Name
        return $true
    }
    return $false
}

function Show-CommandGroupsRu {
    $catalog = Get-WorkstationHelpCatalog
    $P = if (Get-Command Get-HackerPalette -ErrorAction SilentlyContinue) { Get-HackerPalette } else { @{ Cyan = 'Cyan'; Muted = 'DarkGray'; Neon = 'Green' } }

    Write-Host ''
    if (Test-HackerUIEnabled) {
        Write-HackerSection -Tag 'DOC' -Title 'COMMAND CATALOG — полный реестр' -Color $P.Cyan
    } else {
        Write-Host '  ═══════════════════════════════════════════════════════' -ForegroundColor Cyan
        Write-Host '  КОМАНДЫ ПО ГРУППАМ — HOME BASE' -ForegroundColor Cyan
    }

    foreach ($groupName in @('Система','Безопасность','Сеть','Разработка','Обслуживание','Восстановление','Обучение','Навигация')) {
        $desc = $catalog.Groups[$groupName]
        Write-Host ''
        Write-Host "  [$groupName]" -ForegroundColor Yellow
        Write-Host "  $desc" -ForegroundColor $P.Muted
        Write-HackerRule -Width 56

        $cmds = $catalog.Commands.GetEnumerator() | Where-Object { $_.Value.Group -eq $groupName }
        foreach ($c in ($cmds | Sort-Object Name)) {
            $v = $c.Value
            Write-Host ("  {0,-18} {1}" -f $c.Key, $v.Description) -ForegroundColor White
            Write-Host ("  {0,-18} >> {1}" -f '', $v.Examples[0]) -ForegroundColor $P.Muted
        }
    }
    Write-Host ''
    Write-HackerLine '>> ``команда -help`` · trustcheck · hack' -Color $P.Neon
    Write-Host ''
}

function Show-SystemToolsPanel {
    if (Test-HackerUIEnabled) {
        Show-HackerToolsGrid -Inventory (Get-WorkstationToolInventory)
        return
    }

    $ruCatalog = Get-WorkstationToolCatalogRu
    $inv = Get-WorkstationToolInventory

    foreach ($tool in $ruCatalog) {
        $item = $inv | Where-Object { $_.Name -eq $tool.Name -or $_.Command -eq $tool.Cmd } | Select-Object -First 1
        $status = if ($item) {
            switch ($item.Status) {
                'OK' { 'OK' }
                'optional' { 'Необязательный' }
                default { 'Отсутствует' }
            }
        } else { 'Неизвестно' }

        $statusCol = switch ($status) {
            'OK' { 'Green' }
            'Необязательный' { 'DarkGray' }
            'Отсутствует' { 'Red' }
            default { 'Yellow' }
        }

        $path = if ($item -and $item.Path) { ($item.Path -replace [regex]::Escape($env:USERPROFILE), '~') } else { '—' }

        Write-Host "  $($tool.Name)" -ForegroundColor Cyan
        Write-Host "    Что это:   $($tool.What)" -ForegroundColor White
        Write-Host "    Зачем:     $($tool.Why)" -ForegroundColor DarkGray
        Write-Host "    Запуск:    $($tool.Example)" -ForegroundColor Green
        Write-Host "    Путь:      $path" -ForegroundColor DarkGray
        Write-Host "    Статус:    $status" -ForegroundColor $statusCol
        Write-Host ''
    }

    Write-Host '  Полная проверка: toolcheck | nettools' -ForegroundColor DarkGray
    Write-Host ''
}
