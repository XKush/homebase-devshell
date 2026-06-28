# Dashboard — HOME BASE / hack cockpit

$wocPath = Join-Path $script:WSRoot 'lib\WorkstationOperationsCenter.ps1'
if (Test-Path $wocPath) { . $wocPath }

function Show-Woc { Show-HomeBase @PSBoundParameters }
function Show-Jarvis { Show-HomeBase @args }
function Show-WorkstationDashboard { Show-HomeBase @args }
function Show-StartupCommandCenter { Show-HomeBase @args }

function workstationstatus {
    param(
        [switch]$Help,
        [ValidateSet('minimal','normal','full')][string]$Mode = 'full'
    )
    if (Test-ShowCommandHelp -Name 'workstationstatus' -Help:$Help) { return }
    Invoke-WorkstationCmd 'workstationstatus' { Show-HomeBase -Force -Mode $Mode -NoHeal }
}

function hack {
    param([switch]$Help)
    if (Test-ShowCommandHelp -Name 'hack' -Help:$Help) { return }
    Invoke-WorkstationCmd 'hack' {
        if (Get-Command fzf -ErrorAction SilentlyContinue) { Show-HackerMenu }
        else { Show-HomeBase -Force -Mode full }
    }
}

function jarvis {
    param([switch]$Help)
    if (Test-ShowCommandHelp -Name 'jarvis' -Help:$Help) { return }
    Invoke-WorkstationCmd 'jarvis' { Show-HomeBase -Force -Mode full }
}

function dashboard {
    param([switch]$Help)
    if (Test-ShowCommandHelp -Name 'dashboard' -Help:$Help) { return }
    hack
}

function home {
    param([switch]$Help)
    if (Test-ShowCommandHelp -Name 'home' -Help:$Help) { return }
    Invoke-WorkstationCmd 'home' { Show-HomeBase -Force -Mode normal }
}
