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
        $out = Join-Path (Get-WorkstationLogsRoot) ("sysreport-$(Get-Date -Format 'yyyyMMdd-HHmmss').txt")
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
                if ($cmd -and $cmd.Parameters -and $cmd.Parameters.ContainsKey('Help')) { $helpOk = $true }
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

function Save-CommandHealthCache {
    param([string]$OutputPath)
    if (-not $OutputPath) {
        $OutputPath = Join-Path (Get-WorkstationLogsRoot) 'command-health.json'
    }
    $live = @(Get-WorkstationCommandHealth)
    $broken = @($live | Where-Object Status -eq 'BROKEN')
    $ok = @($live | Where-Object Status -eq 'OK')
    $health = [ordered]@{
        Timestamp       = (Get-Date).ToString('o')
        TotalCommands   = $live.Count
        Passed          = $ok.Count
        Broken          = $broken.Count
        ExecuteFailures = 0
        BrokenCommands  = @($broken | ForEach-Object { $_.Name })
        FailedExecution = @()
        Source          = 'Get-WorkstationCommandHealth'
    }
    $dir = Split-Path $OutputPath -Parent
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
    $health | ConvertTo-Json -Depth 4 | Set-Content $OutputPath -Encoding UTF8
}
