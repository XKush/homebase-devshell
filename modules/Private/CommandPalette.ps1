# fzf command palette + interactive hacker menu

function Get-CommandPaletteItems {
    $catalog = Get-WorkstationHelpCatalog
    $items = [System.Collections.Generic.List[string]]::new()

    foreach ($entry in Get-WorkstationCommandRegistry) {
        $name = $entry.Name
        $help = $catalog.Commands[$name]
        $desc = if ($help) { $help.Description } else { $entry.Module }
        $group = if ($help) { $help.Group } else { '?' }
        $items.Add("[$group] $name — $desc")
    }

    $items.Add('[ACTION] sec — SHADOW OPS (Tor + PGP menu)')
    $items.Add('[ACTION] revise — навести порядок (doctor+trust+sec)')
    $items.Add('[ACTION] tor-check — preflight перед Tor')
    $items.Add('[ACTION] scan — быстрый integrity scan')
    $items.Add('[ACTION] palette — это меню')
    return @($items)
}

function Invoke-CommandPalette {
    if (-not (Get-Command fzf -ErrorAction SilentlyContinue)) {
        Write-HackerLine 'fzf не установлен — используйте komandy или sec -Guide' -Color Yellow
        komandy
        return
    }

    $env:FZF_DEFAULT_OPTS = '--height 50% --layout=reverse --border --prompt="CMD> "'
    $pick = Get-CommandPaletteItems | fzf --header 'HOME BASE // palette · Enter=help · sec=безопасность'
    if (-not $pick) { return }

    if ($pick -match '\] ([a-z\-]+) —') {
        $cmd = $Matches[1]
            switch ($cmd) {
            'palette' { return }
            'scan'    { scan; return }
            'sec'     { sec; return }
            'revise'  { revise; return }
        }
        Show-WorkstationCommandHelp -Name $cmd
        Write-HackerLine "запуск: $cmd  ·  help: $cmd -help" -Color DarkGreen
    }
}

function Show-HackerMenu {
    if (-not (Get-Command fzf -ErrorAction SilentlyContinue)) {
        Show-HomeBase -Force -Mode full
        return
    }

    $menu = @(
        '── COCKPIT ──'
        '1 · FULL COCKPIT — home / telemetry'
        '2 · SINGULARITY — operator seal'
        '── SECURITY ──'
        '3 · SHADOW OPS — sec (Tor + PGP menu)'
        '4 · TOR PREFLIGHT — tor-check'
        '── OPS ──'
        '5 · QUICK SCAN — scan'
        '6 · REVISE — poriadok (sync + doctor + trust)'
        '7 · TRUST PROBE — trustcheck'
        '8 · HEALTH — doctor'
        '9 · NETWORK — nettools'
        '── NAV ──'
        '0 · PALETTE — palette'
        'A · DEV START — devstart'
        'B · PALETTE — palette'
        'C · TOOLS — instrumenty'
        'D · CATALOG — komandy'
    )

    $env:FZF_DEFAULT_OPTS = '--height 55% --layout=reverse --border --prompt="HACK> "'
    $pick = $menu | fzf --header 'HOME BASE // menu · sec=Tor+PGP · Esc=exit'
    if (-not $pick) { return }
    if ($pick -match '^──') { Show-HackerMenu; return }

    switch -Regex ($pick) {
        'FULL COCKPIT' { Show-HomeBase -Force -Mode normal; break }
        'SINGULARITY'  { singularity; break }
        'SHADOW OPS'   { sec; break }
        'TOR PREFLIGHT'{ tor-check; break }
        'QUICK SCAN'   { scan; break }
        'REVISE'       { revise; break }
        'TRUST'        { trustcheck; break }
        'HEALTH'       { doctor; break }
        'NETWORK'      { nettools; break }
        'DEV START'    { devstart; break }
        'PALETTE'      { Invoke-CommandPalette; break }
        'TOOLS'        { instrumenty; break }
        'CATALOG'      { komandy; break }
        default        { sec }
    }
}

function palette {
    param([switch]$Help)
    if (Test-ShowCommandHelp -Name 'palette' -Help:$Help) { return }
    Invoke-WorkstationCmd 'palette' { Invoke-CommandPalette }
}

function menu {
    param([switch]$Help)
    if (Test-ShowCommandHelp -Name 'menu' -Help:$Help) { return }
    Invoke-WorkstationCmd 'menu' { Show-HackerMenu }
}
