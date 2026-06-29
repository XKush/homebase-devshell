# HOME BASE — go: категории → действия, [следующий] из home, Enter=делает
#
# go / menu / palette  — двухуровневое меню (Ctrl+Alt+G или Ctrl+Alt+M)
# sec                  — только Tor+PGP (плоский список)
# Ctrl+Alt+K komandy   — текстовый справочник

$foldersLib = Join-Path ($script:WSRoot ?? 'C:\Scripts\Workstation') 'lib\WorkstationFolders.ps1'
$anonLib = Join-Path ($script:WSRoot ?? 'C:\Scripts\Workstation') 'lib\AnonymityKit.ps1'
if (Test-Path $foldersLib) { . $foldersLib }
if (Test-Path $anonLib) { . $anonLib }

$script:WorkstationMenuRecentPath = 'C:\Logs\Workstation\menu-recent.json'
$script:WorkstationMenuPreviewScript = Join-Path ($script:WSRoot ?? 'C:\Scripts\Workstation') 'lib\Invoke-MenuPreview.ps1'
$script:WorkstationFolderLayoutEnsured = $false
$script:WorkstationMenuHotkeysRegistered = $false

function Test-WorkstationFzfAvailable {
    return [bool](Get-Command fzf -ErrorAction SilentlyContinue)
}

function Get-WorkstationNavBindings {
    return [ordered]@{
        go      = @{ Chord = 'Ctrl+Alt+G'; Label = 'go';      Desc = 'категории → действия' }
        menu    = @{ Chord = 'Ctrl+Alt+M'; Label = 'menu';    Desc = '= go' }
        sec     = @{ Chord = 'Ctrl+Alt+S'; Label = 'anon';     Desc = 'швейцарский нож' }
        palette = @{ Chord = 'Ctrl+Alt+H'; Label = 'palette'; Desc = '= go' }
        komandy = @{ Chord = 'Ctrl+Alt+K'; Label = 'komandy'; Desc = 'справочник' }
        home    = @{ Chord = 'Ctrl+Alt+B'; Label = 'home';    Desc = 'обзор' }
    }
}

function Get-WorkstationMenuCategoryLabels {
    return [ordered]@{
        'папки'        = 'Папки и загрузки'
        'порядок'      = 'Порядок на диске'
        'система'      = 'Система и доверие'
        'разработка'   = 'Разработка'
        'сеть'         = 'Сеть'
        'anon'         = 'Швейцарский нож — анонимность'
        'обслуживание' = 'Терминал и восстановление'
        'справка'      = 'Обучение и справочник'
    }
}

function Get-WorkstationMenuCategoryOrder {
    return @('anon', 'папки', 'порядок', 'система', 'разработка', 'сеть', 'обслуживание', 'справка')
}

function Get-WorkstationMenuExcludedCatalog {
    return @(
        'go', 'menu', 'palette', 'nav', 'hack', 'jarvis', 'dashboard', 'home', 'privacy', 'poriadok', 'sec',
        'healthcheck', 'explain', 'quickstart', 'cheatsheet', 'cleanlogs', 'workstationstatus',
        'tor-help', 'pgp-help', 'singularity', 'genesis', 'dna', 'trustchain', 'toolbox'
    )
}

function Get-WorkstationMenuSkipIds {
    return @(
        'healthcheck'  # = doctor
        'home'         # Ctrl+Alt+B
        'logs-dir'     # = logs / та же папка
        'cleanlogs'    # часть cleanup
        'explain'      # komandy + Ctrl+/
        'quickstart'   # = help
        'cheatsheet'   # = komandy
    )
}

function Get-WorkstationPrivacyMenuItems {
    return @(Get-WorkstationAnonymityKitItems | ForEach-Object {
        @{ Action = $_.Id; Label = ($_.Label -replace '^[①②③④⑤⑥]\s*', '') }
    })
}

function Get-WorkstationSecurityMenuItems { Get-WorkstationPrivacyMenuItems }

function Get-WorkstationActionRegistry {
    param([string[]]$Groups)

    $std = if (Get-Command Get-WorkstationStandardFolders -ErrorAction SilentlyContinue) {
        Get-WorkstationStandardFolders
    } else {
        @{ Downloads = (Join-Path $env:USERPROFILE 'Downloads'); DownloadsArchive = 'C:\Downloads\Archive' }
    }

    $items = [System.Collections.Generic.List[hashtable]]::new()

    foreach ($row in @(
        @{ Group = 'папки'; Id = 'projects';          Label = 'Projects';         Run = 'projects'; Hint = 'C:\Projects' }
        @{ Group = 'папки'; Id = 'tools';             Label = 'Tools';            Run = 'tools'; Hint = 'C:\Tools' }
        @{ Group = 'папки'; Id = 'scripts';           Label = 'Scripts';          Run = 'scripts'; Hint = 'C:\Scripts' }
        @{ Group = 'папки'; Id = 'downloads';         Label = 'Загрузки';         Run = 'downloads'; Hint = $std.Downloads }
        @{ Group = 'папки'; Id = 'downloads-archive'; Label = 'Архив загрузок';   Run = 'folder:' + $std.DownloadsArchive; Hint = 'Installers' }
        @{ Group = 'папки'; Id = 'desktop';           Label = 'Рабочий стол';     Run = 'desktop'; Hint = $std.Desktop }
        @{ Group = 'папки'; Id = 'backups';           Label = 'Бэкапы';           Run = 'backups'; Hint = 'C:\Backups\Workstation' }
        @{ Group = 'папки'; Id = 'configs';           Label = 'Конфиги';          Run = 'configs'; Hint = 'C:\Configs\Workstation' }
        @{ Group = 'папки'; Id = 'networking';       Label = 'Networking';       Run = 'networking'; Hint = 'C:\Networking' }
        @{ Group = 'папки'; Id = 'logs-dir';         Label = 'Журналы (папка)';  Run = 'folder:C:\Logs\Workstation'; Hint = 'cd + файлы' }
        @{ Group = 'папки'; Id = 'security';          Label = 'Security';         Run = 'folder:' + $std.Security; Hint = 'Tor, PGP, аудит' }
        @{ Group = 'порядок'; Id = 'revise';          Label = 'полный порядок';   Run = 'revise'; Hint = 'doctor + trust + docs' }
        @{ Group = 'порядок'; Id = 'organize';         Label = 'структура папок';  Run = 'organize'; Hint = 'organize -WhatIf сначала' }
        @{ Group = 'порядок'; Id = 'sysaudit';        Label = 'аудит диска';      Run = 'sysaudit'; Hint = 'план без изменений' }
        @{ Group = 'порядок'; Id = 'cleanup';         Label = 'очистка';          Run = 'cleanup'; Hint = 'cleanup -WhatIf' }
        @{ Group = 'система'; Id = 'home';            Label = 'обзор HOME BASE';  Run = 'home'; Hint = 'trust, NEXT' }
        @{ Group = 'система'; Id = 'doctor';          Label = 'полная проверка';  Run = 'doctor'; Hint = '74+ тестов' }
        @{ Group = 'система'; Id = 'trustcheck';      Label = 'live trust';       Run = 'trustcheck'; Hint = 'integrity' }
        @{ Group = 'система'; Id = 'scan';            Label = 'быстрый scan';     Run = 'scan'; Hint = '~2 сек' }
        @{ Group = 'система'; Id = 'healthcheck';     Label = 'здоровье (кратко)'; Run = 'healthcheck'; Hint = 'легче doctor' }
        @{ Group = 'система'; Id = 'sysreport';       Label = 'отчёт системы';    Run = 'sysreport'; Hint = 'JSON + сводка' }
        @{ Group = 'система'; Id = 'instrumenty';     Label = 'инвентарь ПО';     Run = 'instrumenty'; Hint = 'что установлено' }
        @{ Group = 'система'; Id = 'sysinfo';         Label = 'сводка (fastfetch)'; Run = 'sysinfo'; Hint = 'one screen' }
        @{ Group = 'разработка'; Id = 'devstart';     Label = 'начало дня';       Run = 'devstart'; Hint = 'Projects + home' }
        @{ Group = 'разработка'; Id = 'workspace';   Label = 'git/venv здесь';   Run = 'workspace'; Hint = 'текущая папка' }
        @{ Group = 'разработка'; Id = 'new-project';  Label = 'новый проект';     Run = 'new-project'; Hint = 'нужны аргументы' }
        @{ Group = 'разработка'; Id = 'devinfo';      Label = 'среда разработки'; Run = 'devinfo'; Hint = 'git, python, pwsh' }
        @{ Group = 'разработка'; Id = 'logs';         Label = 'журналы WS';       Run = 'logs'; Hint = 'logs -Open' }
        @{ Group = 'разработка'; Id = 'whereami';     Label = 'где я';            Run = 'whereami'; Hint = 'pwd + git + venv' }
        @{ Group = 'сеть'; Id = 'nettools';           Label = 'сетевая панель';   Run = 'nettools'; Hint = 'Wi-Fi, DNS, порты' }
        @{ Group = 'сеть'; Id = 'networkstatus';     Label = 'IP и адаптеры';    Run = 'networkstatus'; Hint = 'быстро' }
        @{ Group = 'сеть'; Id = 'toolcheck';         Label = 'проверка утилит';  Run = 'toolcheck'; Hint = 'nmap, git, gh…' }
        @{ Group = 'сеть'; Id = 'portscan';          Label = 'скан портов';      Run = 'portscan'; Hint = 'portscan host' }
        @{ Group = 'сеть'; Id = 'tcpview';           Label = 'TCP соединения';   Run = 'tcpview'; Hint = 'Sysinternals' }
        @{ Group = 'сеть'; Id = 'cap';               Label = 'захват трафика';   Run = 'cap'; Hint = 'Wireshark/tshark' }
        @{ Group = 'обслуживание'; Id = 'repairterminal'; Label = 'починка терминала'; Run = 'repairterminal'; Hint = 'OMP, шрифты' }
        @{ Group = 'обслуживание'; Id = 'fixprofile'; Label = 'sync профиля';    Run = 'fixprofile'; Hint = 'канонический' }
        @{ Group = 'обслуживание'; Id = 'reloadprofile'; Label = 'перезагрузить профиль'; Run = 'reloadprofile'; Hint = 'после fixprofile' }
        @{ Group = 'обслуживание'; Id = 'restoreconfig'; Label = 'откат настроек'; Run = 'restoreconfig'; Hint = 'из бэкапа' }
        @{ Group = 'обслуживание'; Id = 'cleanlogs';  Label = 'обрезка логов';    Run = 'cleanlogs'; Hint = 'безопасно' }
        @{ Group = 'обслуживание'; Id = 'updateall';  Label = 'обновить пакеты';  Run = 'updateall'; Hint = 'winget + модули' }
        @{ Group = 'справка'; Id = 'komandy';         Label = 'все команды';      Run = 'komandy'; Hint = 'по группам' }
        @{ Group = 'справка'; Id = 'explain';         Label = 'справка по имени'; Run = 'explain'; Hint = 'explain doctor' }
        @{ Group = 'справка'; Id = 'help';            Label = 'обучение';         Run = 'help'; Hint = 'git, python…' }
        @{ Group = 'справка'; Id = 'learn';           Label = 'квесты';           Run = 'learn'; Hint = 'learn -Quest 1' }
        @{ Group = 'справка'; Id = 'quickstart';      Label = 'быстрый старт';    Run = 'quickstart'; Hint = '5 шагов' }
        @{ Group = 'справка'; Id = 'cheatsheet';      Label = 'шпаргалка';        Run = 'cheatsheet'; Hint = 'md' }
    )) { $items.Add($row) }

    foreach ($kit in (Get-WorkstationAnonymityKitItems)) {
        $run = if ($kit.Id -eq 'guide') { 'guide' } else { $kit.Run }
        $items.Add(@{
            Group = 'anon'
            Id    = $kit.Id
            Label = ($kit.Label -replace '^[①②③④⑤⑥]\s*', '')
            Run   = $run
            Hint  = if ($kit.Essential) { 'anon · essential' } else { 'anon · setup' }
        })
    }

    $skip = Get-WorkstationMenuSkipIds
    $all = @($items | Where-Object { $_.Id -notin $skip })
    if ($Groups -and $Groups.Count) {
        return @($all | Where-Object { $_.Group -in $Groups })
    }
    return $all
}

function Resolve-WorkstationRecommendationId {
    param([string]$Text)

    if ([string]::IsNullOrWhiteSpace($Text)) { return $null }
    if ($Text -match '→\s*(?<id>[a-z][a-z0-9\-]*)') { return $Matches.id }
    if ($Text -match ':\s*(?<rest>[^·—]+)') {
        $head = ($Matches.rest.Trim() -split '\s+')[0]
        if ($head -match '^(?<id>[a-z][a-z0-9\-]*)$') { return $Matches.id }
    }
    $known = @(
        'repairterminal', 'trustcheck', 'backupconfig', 'devstart', 'doctor', 'windowsstatus'
        'pgp-repair', 'pgp-setup', 'tor-browser', 'tor-harden', 'tor-check', 'toolcheck'
        'nettools', 'cleanup', 'organize', 'revise', 'sysaudit', 'anon', 'sec', 'go'
        'menu', 'komandy', 'projects', 'hack', 'home', 'scan'
    )
    if (Get-Command Get-WorkstationActionRegistry -ErrorAction SilentlyContinue) {
        $known = @(
            (Get-WorkstationActionRegistry | ForEach-Object { $_.Id })
            $known
        ) | Select-Object -Unique | Sort-Object { $_.Length } -Descending
    } else {
        $known = $known | Sort-Object { $_.Length } -Descending
    }
    foreach ($id in $known) {
        if ($Text -match [regex]::Escape($id)) { return $id }
    }
    if ($Text -match '^(?<id>[a-z][a-z0-9\-]*)') { return $Matches.id }
    return $null
}

function Get-WorkstationMenuPinnedIds {
    if (-not (Get-Command Get-WorkstationAnonymityKitItems -ErrorAction SilentlyContinue)) { return @() }
    return @((Get-WorkstationAnonymityKitItems | Where-Object { $_.Step -gt 0 } | ForEach-Object { $_.Id }))
}

function Get-WorkstationMenuNextSteps {
    $steps = [System.Collections.Generic.List[hashtable]]::new()
    $registry = Get-WorkstationActionRegistry
    $pinned = Get-WorkstationMenuPinnedIds

    if (Get-Command Get-AnonymityKitNextStepIds -ErrorAction SilentlyContinue) {
        foreach ($nid in (Get-AnonymityKitNextStepIds)) {
            if ($nid -in $pinned) { continue }
            $item = @($registry | Where-Object { $_.Id -eq $nid } | Select-Object -First 1)
            if ($item) { $steps.Add(@{ Id = $nid; Label = $item.Label; Item = $item }) }
        }
    }

    if (-not $steps.Count -and (Get-Command Get-HomeBaseRecommendationsRu -ErrorAction SilentlyContinue) -and
        (Get-Command Build-WocReport -ErrorAction SilentlyContinue) -and
        (Get-Command Get-SystemTrustReport -ErrorAction SilentlyContinue)) {
        try {
            $trust = Get-SystemTrustReport
            $report = Build-WocReport
            foreach ($text in (Get-HomeBaseRecommendationsRu -Report $report -Trust $trust)) {
                $id = Resolve-WorkstationRecommendationId -Text $text
                if (-not $id) { continue }
                if ($id -in $pinned) { continue }
                $item = @($registry | Where-Object { $_.Id -eq $id } | Select-Object -First 1)
                if (-not $item) { continue }
                $label = ($text -replace "^$id\s*[—\-→:]\s*", '').Trim()
                if (-not $label) { $label = $item.Label }
                $steps.Add(@{ Id = $id; Label = $label; Item = $item })
            }
        } catch { }
    }

    if (-not $steps.Count) {
        foreach ($d in @(
            @{ Id = 'devstart'; Label = 'начало дня' }
            @{ Id = 'organize'; Label = 'структура папок' }
        )) {
            if ($d.Id -in $pinned) { continue }
            $item = @($registry | Where-Object { $_.Id -eq $d.Id } | Select-Object -First 1)
            if ($item) { $steps.Add(@{ Id = $d.Id; Label = $d.Label; Item = $item }) }
        }
    }

    $seen = @{}
    $uniq = [System.Collections.Generic.List[hashtable]]::new()
    foreach ($s in $steps) {
        if ($seen[$s.Id]) { continue }
        $seen[$s.Id] = $true
        $uniq.Add($s)
        if ($uniq.Count -ge 5) { break }
    }
    return @($uniq)
}

function Format-WorkstationActionLine {
    param($Item, [string]$Prefix = '')
    $tag = if ($Prefix) { $Prefix } else { $Item.Group }
    "[$tag] $($Item.Id) - $($Item.Label)"
}

function Format-WorkstationCategoryLine {
    param([string]$GroupId, [int]$Count)
    $labels = Get-WorkstationMenuCategoryLabels
    $title = if ($labels.Contains($GroupId)) { $labels[$GroupId] } else { $GroupId }
    "[категория] $GroupId - $title ($Count)"
}

function Get-WorkstationMenuRecentIds {
    if (-not (Test-Path $script:WorkstationMenuRecentPath)) { return @() }
    try {
        $data = Get-Content $script:WorkstationMenuRecentPath -Raw | ConvertFrom-Json
        $raw = @($data.Ids | Select-Object -First 8)
    } catch { return @() }

    $registry = Get-WorkstationActionRegistry
    $regIds = @($registry | ForEach-Object { $_.Id })
    $valid = [System.Collections.Generic.List[string]]::new()
    foreach ($id in $raw) {
        if ($regIds -contains $id) { $valid.Add($id); continue }
        if (Get-Command $id -ErrorAction SilentlyContinue) { $valid.Add($id) }
    }

    if ($valid.Count -ne $raw.Count) {
        $dir = Split-Path $script:WorkstationMenuRecentPath -Parent
        if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
        @{ Ids = @($valid) } | ConvertTo-Json | Set-Content $script:WorkstationMenuRecentPath -Encoding UTF8
    }
    return @($valid)
}

function Add-WorkstationMenuRecent {
    param([Parameter(Mandatory)][string]$Id)

    $dir = Split-Path $script:WorkstationMenuRecentPath -Parent
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }

    $list = [System.Collections.Generic.List[string]]::new()
    $list.Add($Id)
    foreach ($old in (Get-WorkstationMenuRecentIds)) {
        if ($old -ne $Id) { $list.Add($old) }
        if ($list.Count -ge 8) { break }
    }
    @{ Ids = @($list) } | ConvertTo-Json | Set-Content $script:WorkstationMenuRecentPath -Encoding UTF8
}

function Show-WorkstationMenuContext {
    $pwdShort = ($PWD.Path -replace [regex]::Escape($env:USERPROFILE), '~')
    $trust = '—'
    if (Get-Command Get-SystemTrustReport -ErrorAction SilentlyContinue) {
        try {
            $t = Get-SystemTrustReport
            $trust = "$($t.Score)% $($t.Level)"
        } catch { }
    }
    $sec = '—'
    if (Get-Command Get-SecurityReadinessReport -ErrorAction SilentlyContinue) {
        try {
            $s = Get-SecurityReadinessReport
            $sec = "$($s.Level) $($s.Score)%"
        } catch { }
    }
    Write-HackerLine "pwd: $pwdShort  |  trust: $trust  |  sec: $sec" -Color DarkGray
    Write-HackerLine 'Enter=выполнить  Esc=назад  Ctrl+/=справка  Ctrl+Alt+S=anon' -Color DarkGray
}

function Get-WorkstationMenuPreviewText {
    param([Parameter(Mandatory)][string]$Line)

    if ($Line -match '^\[категория\] (\p{L}+) - (.+) \((\d+)\)') {
        return @("Enter → открыть категорию", $Matches[2], "$($Matches[3]) действий")
    }
    if ($Line -match '^\[nav\] all -') {
        return @('Enter → все команды', 'включая [cmd] из справочника', 'Esc → назад')
    }
    if ($Line -match '^\[назад\] back -') {
        return @('Enter → к категориям', 'Esc → выход')
    }
    if ($Line -match '^\[anon\] ([a-z0-9\-]+) - (.+)') {
        $id = $Matches[1]
        $item = Get-WorkstationActionRegistry | Where-Object { $_.Id -eq $id } | Select-Object -First 1
        if ($item) {
            return @("Enter → $($item.Run)", $Matches[2], 'швейцарский нож — анонимность')
        }
    }
    if ($Line -match '^\[следующий\] ([a-z0-9\-]+) - (.+)') {
        $id = $Matches[1]
        $item = Get-WorkstationActionRegistry | Where-Object { $_.Id -eq $id } | Select-Object -First 1
        if ($item) {
            return @("Enter → $($item.Run)", $Matches[2], 'из home — следующий шаг')
        }
    }

    if ($Line -match '\] ([a-z0-9\-]+) - (.+)') {
        $id = $Matches[1]
        $label = $Matches[2]
        $item = Get-WorkstationActionRegistry | Where-Object { $_.Id -eq $id } | Select-Object -First 1
        if ($item) {
            $run = if ($item.Run -like 'folder:*') { "открыть $($item.Run.Substring(7))" } else { $item.Run }
            $hint = if ($item.Hint) { $item.Hint } else { $label }
            return @("Enter → $run", $hint, 'Ctrl+/ → справка')
        }
        $catalog = Get-WorkstationHelpCatalog
        if ($catalog.Commands.ContainsKey($id)) {
            $c = $catalog.Commands[$id]
            return @("Enter → $id", $c.Description, "пример: $($c.Examples[0])")
        }
    }
    return @($Line)
}

function Get-WorkstationGoFzfItems {
    param(
        [string[]]$Groups,
        [switch]$IncludeCatalog,
        [ValidateSet('root', 'group', 'all', 'flat')][string]$View = 'root',
        [string]$ActiveGroup
    )

    $lines = [System.Collections.Generic.List[string]]::new()
    $registry = Get-WorkstationActionRegistry -Groups $Groups
    $known = @($registry | ForEach-Object { $_.Id })
    $labels = Get-WorkstationMenuCategoryLabels

    if ($View -eq 'root') {
        $seenRoot = @{}
        $pinned = Get-WorkstationMenuPinnedIds

        foreach ($rid in (Get-WorkstationMenuRecentIds)) {
            if ($rid -in $pinned) { continue }
            if ($seenRoot[$rid]) { continue }
            $item = $registry | Where-Object { $_.Id -eq $rid } | Select-Object -First 1
            if ($item) {
                $lines.Add((Format-WorkstationActionLine $item -Prefix 'недавно'))
                $seenRoot[$rid] = $true
            }
        }
        if ($lines.Count) { $lines.Add('[---] --- - ---') }

        if (-not $Groups -or $Groups.Count -eq 0) {
            foreach ($kit in @(Get-WorkstationAnonymityKitItems | Where-Object { $_.Step -gt 0 } | Sort-Object Step)) {
                if ($seenRoot[$kit.Id]) { continue }
                $lines.Add("[anon] $($kit.Id) - $($kit.Label)")
                $seenRoot[$kit.Id] = $true
            }
            if ((Get-WorkstationAnonymityKitItems | Where-Object { $_.Step -gt 0 }).Count) {
                $lines.Add('[---] --- - ---')
            }
        }

        foreach ($step in (Get-WorkstationMenuNextSteps)) {
            if ($seenRoot[$step.Id]) { continue }
            $lines.Add("[следующий] $($step.Id) - $($step.Label)")
            $seenRoot[$step.Id] = $true
        }
        if ((Get-WorkstationMenuNextSteps).Count) { $lines.Add('[---] --- - ---') }

        foreach ($g in (Get-WorkstationMenuCategoryOrder)) {
            $groupItems = @($registry | Where-Object { $_.Group -eq $g })
            if ($g -eq 'anon') {
                $groupItems = @($groupItems | Where-Object { $_.Id -notin $pinned })
            }
            $cnt = $groupItems.Count
            if ($cnt -gt 0) {
                $lines.Add((Format-WorkstationCategoryLine -GroupId $g -Count $cnt))
            }
        }
        $lines.Add('[nav] all - все команды')
        return @($lines)
    }

    if ($View -eq 'group' -and $ActiveGroup) {
        $lines.Add('[назад] back - к категориям')
        $lines.Add('[---] --- - ---')
        $pinned = if ($ActiveGroup -eq 'anon') { Get-WorkstationMenuPinnedIds } else { @() }
        foreach ($row in @($registry | Where-Object { $_.Group -eq $ActiveGroup -and $_.Id -notin $pinned })) {
            $lines.Add((Format-WorkstationActionLine $row))
        }
        return @($lines)
    }

    if ($View -in @('all', 'flat')) {
        if ($View -eq 'all') {
            $lines.Add('[назад] back - к категориям')
            $lines.Add('[---] --- - ---')
        }

        $seenLineIds = @{}

        foreach ($rid in (Get-WorkstationMenuRecentIds)) {
            $item = $registry | Where-Object { $_.Id -eq $rid } | Select-Object -First 1
            if ($item -and -not $seenLineIds[$item.Id]) {
                $lines.Add((Format-WorkstationActionLine $item -Prefix 'недавно'))
                $seenLineIds[$item.Id] = $true
            }
        }
        if ($lines.Count -gt 2 -or ($View -eq 'flat' -and $lines.Count)) { $lines.Add('[---] --- - ---') }

        foreach ($g in (Get-WorkstationMenuCategoryOrder)) {
            foreach ($row in @($registry | Where-Object { $_.Group -eq $g })) {
                if ($seenLineIds[$row.Id]) { continue }
                $lines.Add((Format-WorkstationActionLine $row))
                $seenLineIds[$row.Id] = $true
            }
        }

        if ($IncludeCatalog) {
            $lines.Add('[---] --- - ---')
            $catalog = Get-WorkstationHelpCatalog
            $exclude = Get-WorkstationMenuExcludedCatalog
            $groupOrder = @('Система', 'Безопасность', 'Сеть', 'Разработка', 'Обслуживание', 'Восстановление', 'Обучение', 'Навигация')
            foreach ($g in $groupOrder) {
                $cmds = $catalog.Commands.GetEnumerator() |
                    Where-Object {
                        $_.Value.Group -eq $g -and
                        $known -notcontains $_.Key -and
                        $exclude -notcontains $_.Key -and
                        -not $seenLineIds[$_.Key]
                    } |
                    Sort-Object Name
                foreach ($c in $cmds) {
                    if (-not (Get-Command $c.Key -ErrorAction SilentlyContinue)) { continue }
                    $lines.Add("[cmd] $($c.Key) - $($c.Value.Description)")
                    $seenLineIds[$c.Key] = $true
                }
            }
        }

        return @($lines)
    }

    return @($lines)
}

function Get-WorkstationGoItemByLine {
    param(
        [Parameter(Mandatory)][string]$Line,
        [string[]]$Groups
    )

    if ($Line -match '^\[категория\] (\p{L}+) -') {
        $gid = $Matches[1]
        if ((Get-WorkstationMenuCategoryOrder) -notcontains $gid) { return $null }
        return @{ Kind = 'nav'; Nav = "group:$gid" }
    }
    if ($Line -match '^\[nav\] all -') {
        return @{ Kind = 'nav'; Nav = 'all' }
    }
    if ($Line -match '^\[назад\] back -') {
        return @{ Kind = 'nav'; Nav = 'root' }
    }
    if ($Line -match '^\[anon\] ([a-z0-9\-]+) -') {
        $id = $Matches[1]
        $action = Get-WorkstationActionRegistry -Groups $Groups | Where-Object { $_.Id -eq $id } | Select-Object -First 1
        if ($action) { return @{ Kind = 'action'; Item = $action } }
    }
    if ($Line -match '^\[следующий\] ([a-z0-9\-]+) -') {
        $id = $Matches[1]
        $action = Get-WorkstationActionRegistry -Groups $Groups | Where-Object { $_.Id -eq $id } | Select-Object -First 1
        if ($action) { return @{ Kind = 'action'; Item = $action } }
    }

    if ($Line -notmatch '\] ([a-z0-9\-]+) -') { return $null }
    $id = $Matches[1]
    if ($id -in @('back', 'all', '---')) { return $null }

    $action = Get-WorkstationActionRegistry -Groups $Groups | Where-Object { $_.Id -eq $id } | Select-Object -First 1
    if ($action) { return @{ Kind = 'action'; Item = $action } }

    $catalog = Get-WorkstationHelpCatalog
    if ($catalog.Commands.ContainsKey($id)) {
        return @{ Kind = 'cmd'; Id = $id }
    }
    return $null
}

function Invoke-WorkstationActionRun {
    param(
        [Parameter(Mandatory)]$Item,
        [switch]$HelpOnly
    )

    if ($HelpOnly) {
        if ($Item.Run -in @('guide', 'docs', 'sec-help') -or $Item.Run -like 'folder:*') {
            Write-HackerLine "$($Item.Id): $($Item.Label)" -Color Cyan
            if ($Item.Hint) { Write-HackerLine $Item.Hint -Color DarkGray }
            return
        }
        $catalog = Get-WorkstationHelpCatalog
        if ($catalog.Commands.ContainsKey($Item.Id)) {
            Show-WorkstationCommandHelp -Name $Item.Id
        } else {
            Write-HackerLine "$($Item.Id) — $($Item.Label)" -Color Cyan
        }
        return
    }

    Add-WorkstationMenuRecent -Id $Item.Id
    Write-HackerLine ">> $($Item.Id)" -Color Green

    switch ($Item.Run) {
        'guide'    { Show-SecurityGuideRu; return }
        'sec-help' { Show-SecurityHelpRu; return }
        'docs'     {
            $doc = Join-Path $script:WSRoot 'docs\ru\TOR-MAX-SECURITY.md'
            if (Get-Command bat -ErrorAction SilentlyContinue) { bat $doc }
            elseif (Test-Path $doc) { Get-Content $doc | Select-Object -First 50 }
            return
        }
        'home'        { Show-HomeBase -Force -Mode minimal; return }
        'tor-browser' { Start-TorBrowserSession | Out-Null; return }
    }

    if ($Item.Run -like 'folder:*') {
        $path = $Item.Run.Substring(7)
        if (Get-Command Open-WorkstationFolder -ErrorAction SilentlyContinue) {
            Open-WorkstationFolder -Path $path -Label $Item.Label
        } else {
            if (-not (Test-Path $path)) { New-Item -ItemType Directory -Force -Path $path | Out-Null }
            Set-Location $path
            Write-HackerLine "→ $path" -Color DarkGreen
            if (Get-Command ll -ErrorAction SilentlyContinue) { ll } else { Get-ChildItem | Select-Object -First 12 }
        }
        return
    }

    if ($Item.Id -in @('new-project', 'explain', 'portscan', 'cap', 'pgp-encrypt', 'pgp-decrypt') -and -not $HelpOnly) {
        Show-WorkstationCommandHelp -Name $Item.Id
        return
    }

    if (Get-Command $Item.Run -ErrorAction SilentlyContinue) {
        & $Item.Run
        return
    }

    Write-HackerLine "не найдено: $($Item.Run)" -Color Red
}

function Invoke-WorkstationGoPick {
    param(
        [Parameter(Mandatory)][string[]]$Items,
        [string]$Header,
        [string]$Prompt = 'go> '
    )

    if (-not (Test-WorkstationFzfAvailable)) { return $null }

    $footer = 'Enter=выполнить | Ctrl+/=справка | Esc=назад'
    $prevOpts = $env:FZF_DEFAULT_OPTS
    $prevPreview = $env:FZF_PREVIEW_COMMAND
    $prevWindow = $env:FZF_PREVIEW_WINDOW

    if (Test-Path $script:WorkstationMenuPreviewScript) {
        $env:FZF_PREVIEW_COMMAND = "pwsh -NoProfile -File `"$($script:WorkstationMenuPreviewScript)`" -Line {}"
        $env:FZF_PREVIEW_WINDOW = 'right:45%:wrap'
    }

    $env:FZF_DEFAULT_OPTS = "--height 65% --layout=reverse --border --prompt=`"$Prompt`" --footer=`"$footer`""

    try {
        $pickItems = @($Items | Where-Object { $_ -notmatch '^\[---\]' })
        $raw = @($pickItems | fzf --expect=enter,ctrl-/ --header $Header)
    } finally {
        $env:FZF_DEFAULT_OPTS = $prevOpts
        $env:FZF_PREVIEW_COMMAND = $prevPreview
        $env:FZF_PREVIEW_WINDOW = $prevWindow
    }

    if (-not $raw -or $raw.Count -eq 0) { return $null }
    return [PSCustomObject]@{
        Key  = $raw[0].ToLower()
        Pick = if ($raw.Count -gt 1) { $raw[1] } else { $null }
    }
}

function Invoke-WorkstationGoMenu {
    param(
        [string[]]$Groups,
        [string]$Title = 'go — категории → действия',
        [scriptblock]$OnStart,
        [switch]$IncludeCatalog
    )

    if (-not (Test-WorkstationFzfAvailable)) {
        Invoke-WorkstationActionMenuFallback -Groups $Groups -Title $Title -OnStart $OnStart
        return
    }

    if (-not $script:WorkstationFolderLayoutEnsured -and (Get-Command Ensure-WorkstationFolderLayout -ErrorAction SilentlyContinue)) {
        Ensure-WorkstationFolderLayout -Quiet | Out-Null
        $script:WorkstationFolderLayoutEnsured = $true
    }

    if ($OnStart) { & $OnStart }
    Show-WorkstationMenuContext

    if (-not $PSBoundParameters.ContainsKey('IncludeCatalog') -and (-not $Groups -or $Groups.Count -eq 0)) {
        $IncludeCatalog = $true
    }

    $view = if ($Groups -and $Groups.Count) { 'flat' } else { 'root' }
    $activeGroup = $null

    while ($true) {
        $items = Get-WorkstationGoFzfItems -Groups $Groups -IncludeCatalog:$IncludeCatalog -View $view -ActiveGroup $activeGroup
        $header = switch ($view) {
            'root'  { $Title }
            'group' {
                $labels = Get-WorkstationMenuCategoryLabels
                $lbl = if ($labels.Contains($activeGroup)) { $labels[$activeGroup] } else { $activeGroup }
                "$Title → $lbl"
            }
            'all'   { "$Title → все команды" }
            'flat'  { $Title }
        }

        $result = Invoke-WorkstationGoPick -Items $items -Header $header
        if (-not $result -or -not $result.Pick -or $result.Pick -match '^\[---\]') {
            if ($view -eq 'group') { $view = 'root'; $activeGroup = $null; continue }
            if ($view -eq 'all') { $view = 'root'; continue }
            return
        }

        $resolved = Get-WorkstationGoItemByLine -Line $result.Pick -Groups $Groups
        if (-not $resolved) {
            Write-HackerLine "не разобрано: $($result.Pick)" -Color Yellow
            continue
        }

        if ($resolved.Kind -eq 'nav') {
            switch -Regex ($resolved.Nav) {
                '^root$' { $view = 'root'; $activeGroup = $null; continue }
                '^all$'  { $view = 'all'; continue }
                '^group:(?<g>.+)$' {
                    $view = 'group'
                    $activeGroup = $Matches.g
                    continue
                }
            }
            continue
        }

        $helpOnly = $result.Key -eq 'ctrl-/'

        if ($resolved.Kind -eq 'action') {
            Invoke-WorkstationActionRun -Item $resolved.Item -HelpOnly:$helpOnly
        } else {
            if ($helpOnly) {
                Show-WorkstationCommandHelp -Name $resolved.Id
            } elseif (Get-Command $resolved.Id -ErrorAction SilentlyContinue) {
                Add-WorkstationMenuRecent -Id $resolved.Id
                Write-HackerLine ">> $($resolved.Id)" -Color Green
                & $resolved.Id
            } else {
                Write-HackerLine "нет: $($resolved.Id)" -Color Yellow
            }
        }
    }
}

function Invoke-WorkstationActionMenu {
    param(
        [string[]]$Groups,
        [string]$Title = 'go — меню действий',
        [scriptblock]$OnStart
    )
    Invoke-WorkstationGoMenu -Groups $Groups -Title $Title -OnStart $OnStart -IncludeCatalog:(-not $Groups)
}

function Invoke-WorkstationCommandSearch {
    Invoke-WorkstationGoMenu -Title 'go — все команды' -IncludeCatalog
}

function Invoke-WorkstationActionMenuFallback {
    param([string[]]$Groups, [string]$Title, [scriptblock]$OnStart)
    if ($OnStart) { & $OnStart }
    Show-WorkstationMenuContext
    Write-HackerLine "$Title (без fzf)" -Color Yellow
    while ($true) {
        $registry = Get-WorkstationActionRegistry -Groups $Groups
        $i = 1; $map = @{}
        foreach ($row in $registry) {
            Write-HackerLine ("  [{0}] {1}" -f $i, (Format-WorkstationActionLine $row)) -Color White
            $map[$i] = $row; $i++
        }
        Write-HackerLine '  [0] выход' -Color DarkGray
        $ans = Read-Host 'номер'
        if ($ans -eq '0' -or [string]::IsNullOrWhiteSpace($ans)) { return }
        [int]$num = 0
        if ([int]::TryParse($ans, [ref]$num) -and $map.ContainsKey($num)) {
            Invoke-WorkstationActionRun -Item $map[$num]
        }
    }
}

function Invoke-WorkstationNavHub {
    param([ValidateSet('menu', 'palette', 'sec')][string]$Start = 'menu')
    switch ($Start) {
        'sec' {
            Invoke-WorkstationGoMenu -Groups @('anon') -Title 'anon — швейцарский нож' -OnStart { Show-SecurityStatusPanel } -IncludeCatalog:$false
            break
        }
        default { Invoke-WorkstationGoMenu }
    }
}

function Show-WorkstationNavBar {
    Write-HackerLine 'go (Ctrl+Alt+G) — [anon] + [следующий] + категории | anon (Ctrl+Alt+S) | home' -Color DarkGray
}

function Show-WorkstationMenuLegend { Show-WorkstationNavBar }

function Show-WorkstationMenuFallback { Invoke-WorkstationActionMenuFallback }

function Register-WorkstationMenuHotkeys {
    if (-not [Environment]::UserInteractive) { return }
    if (-not (Get-Module PSReadLine)) { return }
    if ($script:WorkstationMenuHotkeysRegistered) { return }
    $script:WorkstationMenuHotkeysRegistered = $true

    $ensure = {
        if (Get-Command Initialize-WorkstationModule -ErrorAction SilentlyContinue) {
            Initialize-WorkstationModule
        } elseif (-not (Get-Module KGreen.Workstation)) {
            $mod = Join-Path $script:WSRoot 'modules\KGreen.Workstation.psm1'
            Import-Module $mod -DisableNameChecking -Force -Scope Global -ErrorAction SilentlyContinue
        }
    }

    Set-PSReadLineKeyHandler -Chord 'Ctrl+Alt+G' -ScriptBlock {
        & $ensure
        if (Get-Command Invoke-WorkstationGoMenu -ErrorAction SilentlyContinue) { Invoke-WorkstationGoMenu }
    }
    Set-PSReadLineKeyHandler -Chord 'Ctrl+Alt+M' -ScriptBlock {
        & $ensure
        if (Get-Command Invoke-WorkstationGoMenu -ErrorAction SilentlyContinue) { Invoke-WorkstationGoMenu }
    }
    Set-PSReadLineKeyHandler -Chord 'Ctrl+Alt+H' -ScriptBlock {
        & $ensure
        if (Get-Command Invoke-WorkstationGoMenu -ErrorAction SilentlyContinue) { Invoke-WorkstationGoMenu }
    }
    Set-PSReadLineKeyHandler -Chord 'Ctrl+Alt+S' -ScriptBlock {
        & $ensure
        if (Get-Command anon -ErrorAction SilentlyContinue) { anon }
        elseif (Get-Command Invoke-WorkstationNavHub -ErrorAction SilentlyContinue) { Invoke-WorkstationNavHub -Start sec }
    }
    Set-PSReadLineKeyHandler -Chord 'Ctrl+Alt+K' -ScriptBlock {
        & $ensure
        if (Get-Command komandy -ErrorAction SilentlyContinue) { komandy }
    }
    Set-PSReadLineKeyHandler -Chord 'Ctrl+Alt+B' -ScriptBlock {
        & $ensure
        if (Get-Command Show-HomeBase -ErrorAction SilentlyContinue) { Show-HomeBase -Force -Mode minimal }
    }
}

function Test-WorkstationMenuIntegrity {
    $audit = Test-WorkstationGoMenuAudit
    return $audit
}

function Test-WorkstationGoMenuAudit {
    $fail = [System.Collections.Generic.List[string]]::new()
    $registry = Get-WorkstationActionRegistry
    $rootLines = Get-WorkstationGoFzfItems -View root
    $catalogCount = 0

    foreach ($d in ($registry | Group-Object Id | Where-Object Count -gt 1)) {
        $fail.Add("duplicate id: $($d.Name) x$($d.Count)")
    }

    foreach ($d in ($rootLines | Group-Object | Where-Object Count -gt 1)) {
        if ($d.Name -notmatch '^\[---\]') { $fail.Add("duplicate line: $($d.Name)") }
    }

    foreach ($d in ($registry | Group-Object Run | Where-Object Count -gt 1)) {
        $ids = ($d.Group | ForEach-Object { "$($_.Id)[$($_.Group)]" }) -join ', '
        if ($d.Name -like 'folder:*') {
            $fail.Add("duplicate folder: $ids")
        } else {
            $fail.Add("duplicate run '$($d.Name)': $ids")
        }
    }

    $pinned = Get-WorkstationMenuPinnedIds
    $rootIds = [System.Collections.Generic.List[string]]::new()
    foreach ($line in $rootLines) {
        if ($line -notmatch '\] ([a-z0-9\-]+) -') { continue }
        $id = $Matches[1]
        if ($id -in @('back', 'all', '---')) { continue }
        if ($rootIds -contains $id) { $fail.Add("root duplicate id: $id") }
        else { $rootIds.Add($id) }
    }

    foreach ($row in $registry) {
        if ($row.Run -in @('guide', 'docs', 'sec-help') -or $row.Run -like 'folder:*' -or $row.Id -eq 'new-project') { continue }
        if (-not (Get-Command $row.Run -ErrorAction SilentlyContinue)) {
            $fail.Add("missing cmd: $($row.Id) -> $($row.Run)")
        }
    }

    foreach ($line in $rootLines) {
        if ($line -match '^\[anon\]') {
            $p = Get-WorkstationGoItemByLine -Line $line
            if (-not $p) { $fail.Add("unparsed anon: $line") }
        }
    }

    if (Get-Command Test-AnonymityKitAudit -ErrorAction SilentlyContinue) {
        $kit = Test-AnonymityKitAudit
        if (-not $kit.OK) {
            foreach ($i in $kit.Issues) { $fail.Add("anon kit: $i") }
        }
        foreach ($w in $kit.Warnings) {
            # readiness hints only — not menu structure failures
        }
    }

    $views = @(
        @{ Name = 'root'; Group = $null }
        @{ Name = 'all'; Group = $null; All = $true }
    )
    foreach ($g in (Get-WorkstationMenuCategoryOrder)) {
        $views += @{ Name = "group:$g"; Group = $g }
    }

    foreach ($v in $views) {
        $lines = if ($v.All) {
            Get-WorkstationGoFzfItems -View all -IncludeCatalog
        } elseif ($v.Group) {
            Get-WorkstationGoFzfItems -View group -ActiveGroup $v.Group
        } else {
            Get-WorkstationGoFzfItems -View root
        }
        foreach ($line in $lines) {
            if ($line -match '^\[---\]') { continue }
            $p = Get-WorkstationGoItemByLine -Line $line
            if (-not $p) {
                $fail.Add("unparsed [$($v.Name)]: $line")
                continue
            }
            if ($p.Kind -eq 'cmd') {
                $catalogCount++
                if (-not (Get-Command $p.Id -ErrorAction SilentlyContinue)) {
                    $fail.Add("dead [cmd]: $($p.Id)")
                }
            }
        }
        if ($v.All) {
            $viewIds = @{}
            foreach ($line in $lines) {
                if ($line -notmatch '\] ([a-z0-9\-]+) -') { continue }
                $id = $Matches[1]
                if ($id -in @('back', 'all', '---')) { continue }
                if ($viewIds.ContainsKey($id)) {
                    $fail.Add("all-view duplicate id: $id")
                } else {
                    $viewIds[$id] = $true
                }
            }
        }
    }

    foreach ($s in (Get-WorkstationMenuNextSteps)) {
        $ok = ($registry | Where-Object { $_.Id -eq $s.Id }) -or (Get-Command $s.Id -ErrorAction SilentlyContinue)
        if (-not $ok) { $fail.Add("next step dead: $($s.Id)") }
    }

    if ((Get-Command Get-HomeBaseRecommendationsRu -ErrorAction SilentlyContinue) -and
        (Get-Command Build-WocReport -ErrorAction SilentlyContinue)) {
        try {
            $trust = Get-SystemTrustReport
            $report = Build-WocReport
            foreach ($t in (Get-HomeBaseRecommendationsRu -Report $report -Trust $trust)) {
                $id = Resolve-WorkstationRecommendationId -Text $t
                if (-not $id) { $fail.Add("home rec no id: $t"); continue }
                $ok = ($registry | Where-Object { $_.Id -eq $id }) -or (Get-Command $id -ErrorAction SilentlyContinue)
                if (-not $ok) { $fail.Add("home rec dead: $t -> $id") }
            }
        } catch {
            $fail.Add("home rec probe: $($_.Exception.Message)")
        }
    }

    if (-not (Get-Command go -ErrorAction SilentlyContinue)) { $fail.Add('missing: go') }
    if (-not (Test-WorkstationFzfAvailable)) { $fail.Add('missing: fzf') }
    if (-not (Test-Path $script:WorkstationMenuPreviewScript)) { $fail.Add('missing: preview script') }

    $prof = Join-Path $HOME 'Documents\PowerShell\Microsoft.PowerShell_profile.ps1'
    if (-not (Test-Path $prof)) { $fail.Add('missing: live profile') }
    elseif ((Get-Content $prof -Raw) -notmatch 'Register-WorkstationMenuHotkeys') {
        $fail.Add('profile: hotkeys not wired — run fixprofile')
    }

    return [PSCustomObject]@{
        OK     = ($fail.Count -eq 0)
        Issues = @($fail)
        Counts = @{
            lines    = $rootLines.Count
            registry = $registry.Count
            views    = $views.Count
            catalog  = $catalogCount
        }
    }
}

function nav {
    param([switch]$Help, [ValidateSet('menu', 'palette', 'sec')][string]$Start = 'menu')
    if (Test-ShowCommandHelp -Name 'nav' -Help:$Help) { return }
    Invoke-WorkstationCmd 'nav' { Invoke-WorkstationNavHub -Start $Start }
}

function go {
    param([switch]$Help)
    if (Test-ShowCommandHelp -Name 'go' -Help:$Help) { return }
    Invoke-WorkstationCmd 'go' { Invoke-WorkstationGoMenu }
}

# Legacy
function Get-WorkstationActionFzfItems { param([string[]]$Groups) Get-WorkstationGoFzfItems -Groups $Groups -View flat }
function Get-WorkstationActionByLine { param([string]$Line, [string[]]$Groups) $r = Get-WorkstationGoItemByLine -Line $Line -Groups $Groups; if ($r -and $r.Kind -eq 'action') { return $r.Item } }
function Get-WorkstationMainMenuItems { Get-WorkstationActionRegistry -Groups @('anon', 'порядок', 'система', 'разработка', 'сеть', 'папки') }
function Invoke-WorkstationMainMenuAction { param([string]$Key) $i = Get-WorkstationActionRegistry | ? Id -eq $Key | select -First 1; if ($i) { Invoke-WorkstationActionRun -Item $i } }
function Invoke-WorkstationSecurityMenuAction { param([string]$Action) $i = Get-WorkstationActionRegistry -Groups @('anon') | ? Run -eq $Action | select -First 1; if ($i) { Invoke-WorkstationActionRun -Item $i } else { Show-SecurityStatusPanel } }
function Get-WorkstationCommandSearchItems { Get-WorkstationGoFzfItems -View all -IncludeCatalog | Where-Object { $_ -match '^\[cmd\]' } }
function Invoke-WorkstationFzfAction { Invoke-WorkstationGoPick @args }
