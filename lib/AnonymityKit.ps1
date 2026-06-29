# Швейцарский нож — только анонимность (Tor + PGP + сессия)

function Get-WorkstationAnonymityKitItems {
    return @(
        @{ Id = 'tor-check';       Label = '① preflight — перед сессией';  Run = 'tor-check';       Step = 1; Essential = $true }
        @{ Id = 'guide';           Label = '② порядок сессии';             Run = 'guide';           Step = 2; Essential = $true }
        @{ Id = 'tor-browser';     Label = '③ открыть Tor Browser';        Run = 'tor-browser';   Step = 3; Essential = $true }
        @{ Id = 'pgp-fingerprint';  Label = '④ отпечаток PGP';              Run = 'pgp-fingerprint'; Step = 4; Essential = $true }
        @{ Id = 'pgp-encrypt';     Label = '⑤ шифровать файл';             Run = 'pgp-encrypt';   Step = 5; Essential = $true }
        @{ Id = 'tor-status';      Label = '⑥ после сессии — статус';      Run = 'tor-status';      Step = 6; Essential = $true }
        @{ Id = 'tor-harden';      Label = 'усилить Tor (разово)';         Run = 'tor-harden';      Step = 0; Essential = $true }
        @{ Id = 'tor-setup';       Label = 'установить Tor Browser';       Run = 'tor-setup';       Step = 0; Essential = $true }
        @{ Id = 'pgp-repair';      Label = 'ключ PGP — донастройка';       Run = 'pgp-repair';      Step = 0; Essential = $true }
        @{ Id = 'pgp-status';      Label = 'ключи PGP — список';           Run = 'pgp-status';      Step = 0; Essential = $true }
        @{ Id = 'backupconfig';    Label = 'бэкап ключей и конфигов';      Run = 'backupconfig';    Step = 0; Essential = $true }
        @{ Id = 'securitycheck';   Label = 'UAC + firewall (Windows)';     Run = 'securitycheck';   Step = 0; Essential = $false }
        @{ Id = 'sec-help';        Label = 'правила SHADOW OPS';           Run = 'sec-help';        Step = 0; Essential = $false }
    )
}

function Get-WorkstationAnonymityKitEssentialIds {
    return @((Get-WorkstationAnonymityKitItems | Where-Object { $_.Essential } | ForEach-Object { $_.Id }))
}

function Get-AnonymityKitSupportTools {
    return @(
        @{ Name = 'KeePassXC'; Cmd = 'keepassxc'; Exe = 'C:\Program Files\KeePassXC\KeePassXC.exe'; Winget = 'KeePassXC.KeePassXC' }
        @{ Name = 'VeraCrypt'; Cmd = 'veracrypt'; Exe = 'C:\Program Files\VeraCrypt\VeraCrypt.exe'; Winget = 'IDRIX.VeraCrypt' }
        @{ Name = 'gpg';       Cmd = 'gpg';       Exe = $null; Winget = $null }
    )
}

function Test-AnonymityKitSupportTools {
    $rows = [System.Collections.Generic.List[object]]::new()
    foreach ($t in (Get-AnonymityKitSupportTools)) {
        $ok = [bool](Get-Command $t.Cmd -ErrorAction SilentlyContinue)
        if (-not $ok -and $t.Exe -and (Test-Path $t.Exe)) { $ok = $true }
        $rows.Add([PSCustomObject]@{
            Tool   = $t.Name
            OK     = $ok
            Hint   = if ($ok) { 'OK' } elseif ($t.Winget) { "winget install -e --id $($t.Winget)" } else { 'install gpg / GnuPG' }
            Winget = $t.Winget
        })
    }
    return @($rows)
}

function Get-AnonymityKitNextStepIds {
    if (-not (Get-Command Get-SecurityReadinessReport -ErrorAction SilentlyContinue)) {
        return @('tor-setup', 'pgp-repair', 'tor-harden')
    }
    $r = Get-SecurityReadinessReport
    $steps = [System.Collections.Generic.List[string]]::new()
    if (-not $r.TorReady) { $steps.Add('tor-setup') }
    elseif (-not $r.Hardened) { $steps.Add('tor-harden') }
    if (-not $r.PgpReady) { $steps.Add('pgp-repair') }
    if (-not $r.TorReady -or -not $r.Hardened -or -not $r.PgpReady) {
        return @($steps | Select-Object -Unique)
    }
    return @()
}

function Start-TorBrowserSession {
    . (Join-Path $PSScriptRoot 'TorCommon.ps1')
    $tor = Find-TorBrowserExe
    if (-not $tor) {
        Write-HackerLine 'Tor Browser не найден → tor-setup' -Color Red
        return $false
    }
    Start-Process -FilePath $tor
    Write-HackerLine 'Tor Browser запущен — только .onion, без обычных сайтов в этой сессии' -Color Green
    return $true
}

function Test-AnonymityKitAudit {
    $fail = [System.Collections.Generic.List[string]]::new()
    $warn = [System.Collections.Generic.List[string]]::new()

    foreach ($kit in (Get-WorkstationAnonymityKitItems)) {
        if ($kit.Run -in @('guide', 'sec-help') -or $kit.Run -like 'folder:*') { continue }
        if ($kit.Id -eq 'tor-browser') {
            if (-not (Get-Command Start-TorBrowserSession -ErrorAction SilentlyContinue)) {
                $fail.Add('missing: Start-TorBrowserSession')
            }
            continue
        }
        if (-not (Get-Command $kit.Run -ErrorAction SilentlyContinue)) {
            $fail.Add("missing cmd: $($kit.Id) -> $($kit.Run)")
        }
    }

    if (Get-Command Invoke-TorPreflightCheck -ErrorAction SilentlyContinue) {
        foreach ($c in (Invoke-TorPreflightCheck)) {
            if (-not $c.Ok -and $c.Check -notmatch 'Defender') {
                $warn.Add("$($c.Check): $($c.Hint)")
            }
        }
    } else {
        $fail.Add('missing: Invoke-TorPreflightCheck')
    }

    foreach ($t in (Test-AnonymityKitSupportTools)) {
        if (-not $t.OK -and $t.Tool -eq 'gpg') { $fail.Add('missing: gpg (PGP)') }
        elseif (-not $t.OK) { $warn.Add("$($t.Tool): $($t.Hint)") }
    }

    if (-not (Test-Path 'C:\Security')) { $warn.Add('C:\Security missing — organize or go → anon') }

    return [PSCustomObject]@{
        OK       = ($fail.Count -eq 0)
        Issues   = @($fail)
        Warnings = @($warn)
        KitCount = (Get-WorkstationAnonymityKitItems).Count
        Essential = (Get-WorkstationAnonymityKitEssentialIds).Count
    }
}
