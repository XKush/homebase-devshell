# Recovery — восстановление

function repairterminal {
    param([switch]$Help)
    if (Test-ShowCommandHelp -Name 'repairterminal' -Help:$Help) { return }
    Invoke-WorkstationCmd 'repairterminal' {
        Write-Host '  Восстановление терминала (шрифты, OMP, WT, fastfetch)...' -ForegroundColor Cyan
        & (Join-Path $script:WSRoot 'scripts\maintainer\invoke\Invoke-TerminalRecovery.ps1')
    }
}

function fixprofile {
    param([switch]$Help)
    if (Test-ShowCommandHelp -Name 'fixprofile' -Help:$Help) { return }
    repairterminal
}

function reloadprofile {
    param([switch]$Help)
    if (Test-ShowCommandHelp -Name 'reloadprofile' -Help:$Help) { return }
    Invoke-WorkstationCmd 'reloadprofile' {
        . $PROFILE
        Write-Host '  Профиль перезагружен.' -ForegroundColor Green
    }
}

function restoreconfig {
    param([string]$BackupFolder, [switch]$Help)
    if (Test-ShowCommandHelp -Name 'restoreconfig' -Help:$Help) { return }
    Invoke-WorkstationCmd 'restoreconfig' {
        $args = @('-Force')
        if ($BackupFolder) { $args += '-BackupFolder', $BackupFolder }
        $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
        if (-not $isAdmin) {
            Write-Host '  Восстановление требует прав администратора. Запуск...' -ForegroundColor Yellow
            $argList = @('-NoProfile', '-File', (Join-Path $script:WSRoot 'scripts\maintainer\invoke\Rollback-Workstation.ps1'), '-Force')
            if ($BackupFolder) { $argList += '-BackupFolder', $BackupFolder }
            Start-Process pwsh -Verb RunAs -ArgumentList $argList
            return
        }
        & (Join-Path $script:WSRoot 'scripts\maintainer\invoke\Rollback-Workstation.ps1') @args
    }
}
