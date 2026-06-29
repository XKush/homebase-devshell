# Maintenance — обслуживание системы

function cleanlogs {
    param([int]$KeepDays = 30, [switch]$WhatIf, [switch]$Help)
    if (Test-ShowCommandHelp -Name 'cleanup' -Help:$Help) { return }
    $tempDirs = @([System.IO.Path]::GetTempPath(), (Join-Path $env:LOCALAPPDATA 'Temp'))
    Write-Host "  Безопасная очистка (логи/бэкапы/temp старше $KeepDays дн.)..." -ForegroundColor Cyan

    $valDir = Get-WorkstationLogsRoot
    if (Test-Path $valDir) {
        Get-ChildItem $valDir -Filter 'validation-*.json' | Sort-Object Name -Descending | Select-Object -Skip 10 | ForEach-Object {
            if ($WhatIf) { Write-Host "  Будет удалено: $($_.Name)" -ForegroundColor DarkGray }
            else { Remove-Item $_.FullName -Force; Write-Host "  Удалено: $($_.Name)" -ForegroundColor DarkGray }
        }
        $log = Join-Path $valDir 'workstation.log'
        if ((Test-Path $log) -and ((Get-Item $log).Length -gt 5MB)) {
            if (-not $WhatIf) {
                Get-Content $log -Tail 2000 | Set-Content ($log + '.tmp') -Encoding UTF8
                Move-Item ($log + '.tmp') $log -Force
                Write-Host '  Обрезан workstation.log (оставлено 2000 строк)' -ForegroundColor DarkGray
            }
        }
    }

    $bakRoot = Get-WorkstationBackupsRoot
    if (Test-Path $bakRoot) {
        $dirs = Get-ChildItem $bakRoot -Directory -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -ne '_Archive' } |
            Sort-Object LastWriteTime -Descending
        foreach ($d in ($dirs | Select-Object -Skip 8)) {
            if ($WhatIf) {
                Write-Host "  Будет архивирован бэкап: $($d.Name)" -ForegroundColor DarkGray
                continue
            }
            $archive = Join-Path $bakRoot '_Archive'
            if (-not (Test-Path $archive)) { New-Item -ItemType Directory -Path $archive -Force | Out-Null }
            $dest = Join-Path $archive $d.Name
            if (Test-Path $dest) { continue }
            Move-Item $d.FullName $dest -Force
            Write-Host "  Архивирован бэкап: $($d.Name)" -ForegroundColor DarkGray
        }
    }

    $cutoff = (Get-Date).AddDays(-$KeepDays)
    foreach ($td in $tempDirs) {
        if (-not (Test-Path $td)) { continue }
        Get-ChildItem $td -File -ErrorAction SilentlyContinue |
            Where-Object { $_.LastWriteTime -lt $cutoff -and $_.Extension -in @('.tmp', '.log', '.cache') } |
            ForEach-Object {
                if ($WhatIf) { Write-Host "  Будет удалён temp: $($_.Name)" -ForegroundColor DarkGray }
                else { Remove-Item $_.FullName -Force -ErrorAction SilentlyContinue }
            }
    }
    Write-Host '  Очистка завершена.' -ForegroundColor Green
}

function cleanup {
    param([switch]$Help, [switch]$WhatIf, [int]$KeepDays = 30)
    if (Test-ShowCommandHelp -Name 'cleanup' -Help:$Help) { return }
    Invoke-WorkstationCmd 'cleanup' { cleanlogs -KeepDays $KeepDays -WhatIf:$WhatIf }
}

function updateall {
    param([switch]$Help)
    if (Test-ShowCommandHelp -Name 'updateall' -Help:$Help) { return }
    Invoke-WorkstationCmd 'updateall' {
        Write-Host '  Обновление пакетов winget...' -ForegroundColor Cyan
        winget upgrade --all --accept-package-agreements --accept-source-agreements --disable-interactivity
        Write-Host '  Обновление модулей PowerShell...' -ForegroundColor Cyan
        foreach ($mod in @('PSReadLine', 'posh-git', 'Terminal-Icons')) {
            if (Get-Module -ListAvailable $mod) {
                Update-Module $mod -Force -ErrorAction SilentlyContinue
                Write-Host "  Обновлён: $mod" -ForegroundColor DarkGray
            }
        }
        Write-Host '  Готово. Перезапустите терминал после обновления инструментов.' -ForegroundColor Green
    }
}

function backupconfig {
    param([switch]$Help)
    if (Test-ShowCommandHelp -Name 'backupconfig' -Help:$Help) { return }
    Invoke-WorkstationCmd 'backupconfig' {
        & (Join-Path $script:WSRoot 'scripts\maintainer\invoke\Backup-Configuration.ps1') -Force
        $global:LASTEXITCODE = 0
    }
}

function organize {
    param([switch]$Help, [switch]$WhatIf, [switch]$Force)
    if (Test-ShowCommandHelp -Name 'organize' -Help:$Help) { return }
    Invoke-WorkstationCmd 'organize' {
        if (Get-Command Ensure-WorkstationFolderLayout -ErrorAction SilentlyContinue) {
            Ensure-WorkstationFolderLayout -Quiet | Out-Null
        }
        & (Join-Path $script:WSRoot 'scripts\maintainer\invoke\Invoke-WorkstationOrganization.ps1') -WhatIf:$WhatIf -Force:$Force
        $global:LASTEXITCODE = 0
    }
}
