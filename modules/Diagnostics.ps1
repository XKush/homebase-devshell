# Diagnostics — doctor, healthcheck, sysreport

function doctor {
    param([switch]$Help)
    if (Test-ShowCommandHelp -Name 'doctor' -Help:$Help) { return }
    Invoke-WorkstationCmd 'doctor' {
        Write-Host "`n  Проверка здоровья системы...`n" -ForegroundColor Cyan
        $script = Join-Path $script:WSRoot 'Validate-Workstation.ps1'
        & $script -StartupBudgetMs 600
        if ($LASTEXITCODE -eq 0) {
            Write-Host "`n  Doctor: все проверки пройдены." -ForegroundColor Green
        } else {
            Write-Host "`n  Doctor: найдены проблемы — попробуйте repairterminal" -ForegroundColor Yellow
        }
    }
}

function healthcheck {
    param([switch]$Help)
    if (Test-ShowCommandHelp -Name 'healthcheck' -Help:$Help) { return }
    doctor
}

function sysreport {
    param([switch]$Help)
    if (Test-ShowCommandHelp -Name 'sysreport' -Help:$Help) { return }
    Invoke-WorkstationCmd 'sysreport' {
        $out = Join-Path 'C:\Logs\Workstation' ("sysreport-$(Get-Date -Format 'yyyyMMdd-HHmmss').txt")
        & (Join-Path $script:WSRoot 'Invoke-SystemDiscovery.ps1') | Out-Null
        & (Join-Path $script:WSRoot 'Validate-Workstation.ps1') -StartupBudgetMs 650 | Tee-Object -FilePath $out
        Write-Host "  Отчёт сохранён: $out" -ForegroundColor Green
    }
}

function Get-WorkstationCommandHealth {
    $results = [System.Collections.Generic.List[object]]::new()
    foreach ($entry in Get-WorkstationCommandRegistry) {
        $name = $entry.Name
        $backend = $entry.Backend
        $exists = [bool](Get-Command $name -ErrorAction SilentlyContinue)
        $backendExists = if ($backend -eq $name) { $exists } else { [bool](Get-Command $backend -ErrorAction SilentlyContinue) }
        $helpOk = $false
        if ($exists) {
            try {
                $cmd = Get-Command $name -ErrorAction SilentlyContinue
                if ($cmd -and $cmd.Parameters.ContainsKey('Help')) { $helpOk = $true }
            } catch { }
        }
        $results.Add([PSCustomObject]@{
            Name           = $name
            Backend        = $backend
            Module         = $entry.Module
            Exists         = $exists
            BackendExists  = $backendExists
            Loads          = $exists -and $backendExists
            Help           = $helpOk
            Status         = if ($exists -and $backendExists -and $helpOk) { 'OK' } elseif ($exists -and $backendExists) { 'NO_HELP' } else { 'BROKEN' }
        })
    }
    return @($results)
}
