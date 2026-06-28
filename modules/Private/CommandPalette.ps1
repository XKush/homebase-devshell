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

    $items.Add('[ACTION] scan — быстрый integrity scan')
    $items.Add('[ACTION] palette — это меню')
    return @($items)
}

function Invoke-CommandPalette {
    if (-not (Get-Command fzf -ErrorAction SilentlyContinue)) {
        Write-HackerLine 'fzf не установлен — используйте komandy' -Color Yellow
        komandy
        return
    }

    $env:FZF_DEFAULT_OPTS = '--height 50% --layout=reverse --border --prompt="CMD> "'
    $pick = Get-CommandPaletteItems | fzf --header 'HOME BASE // command palette (Enter=help, Ctrl-E=run)'
    if (-not $pick) { return }

    if ($pick -match '\] ([a-z\-]+) —') {
        $cmd = $Matches[1]
        if ($cmd -eq 'palette') { return }
        if ($cmd -eq 'scan') { scan; return }
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
        '1 · FULL COCKPIT — hack (max mode)'
        '2 · QUICK SCAN — scan'
        '3 · TRUST PROBE — trustcheck'
        '4 · HEALTH — doctor'
        '5 · NETWORK — nettools'
        '6 · DEV START — devstart'
        '7 · COMMAND PALETTE — palette'
        '8 · TOOLS — instrumenty'
        '9 · CATALOG — komandy'
    )

    $env:FZF_DEFAULT_OPTS = '--height 40% --layout=reverse --border --prompt="HACK> "'
    $pick = $menu | fzf --header 'HOME BASE // hacker menu'
    if (-not $pick) { return }

    switch -Regex ($pick) {
        'FULL COCKPIT' { Show-HomeBase -Force -Mode full; break }
        'QUICK SCAN'   { scan; break }
        'TRUST'        { trustcheck; break }
        'HEALTH'       { doctor; break }
        'NETWORK'      { nettools; break }
        'DEV START'    { devstart; break }
        'PALETTE'      { Invoke-CommandPalette; break }
        'TOOLS'        { instrumenty; break }
        'CATALOG'      { komandy; break }
        default        { Show-HomeBase -Force -Mode full }
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
