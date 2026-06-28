# Tor Browser discovery + hardening helpers

$script:TorBrowserExeCache = $null

function Find-TorBrowserExe {
    if ($script:TorBrowserExeCache -and (Test-Path $script:TorBrowserExeCache)) {
        return $script:TorBrowserExeCache
    }

    $candidates = @(
        "$env:USERPROFILE\Desktop\Tor Browser\Browser\firefox.exe"
        "$env:USERPROFILE\Downloads\Tor Browser\Browser\firefox.exe"
        "${env:ProgramFiles}\Tor Browser\Browser\firefox.exe"
        "${env:ProgramFiles(x86)}\Tor Browser\Browser\firefox.exe"
    )
    foreach ($p in $candidates) {
        if (Test-Path $p) {
            $script:TorBrowserExeCache = $p
            return $p
        }
    }

    $state = Get-TorSecurityState
    if ($state -and $state.TorBrowser -and (Test-Path $state.TorBrowser)) {
        $script:TorBrowserExeCache = $state.TorBrowser
        return $state.TorBrowser
    }

    $found = Get-ChildItem -Path $env:USERPROFILE -Filter 'firefox.exe' -Recurse -Depth 5 -ErrorAction SilentlyContinue |
        Where-Object { $_.FullName -match 'Tor Browser\\Browser\\firefox\.exe$' } |
        Select-Object -First 1
    if ($found) {
        $script:TorBrowserExeCache = $found.FullName
        return $found.FullName
    }
    return $null
}

function Find-TorBrowserRoot {
    $exe = Find-TorBrowserExe
    if (-not $exe) { return $null }
    return (Split-Path (Split-Path $exe -Parent) -Parent)
}

function Get-TorSecurityStatePath { 'C:\Security\tor\tor-security.json' }

function Get-TorSecurityState {
    $path = Get-TorSecurityStatePath
    if (Test-Path $path) {
        try { return Get-Content $path -Raw | ConvertFrom-Json } catch { }
    }
    return $null
}

function Set-TorSecurityState {
    param([hashtable]$Data)
    $dir = Split-Path (Get-TorSecurityStatePath) -Parent
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
    $Data | ConvertTo-Json | Set-Content (Get-TorSecurityStatePath) -Encoding UTF8
}

function Write-TorBrowserUserJs {
    param([string]$ProfileDir)

    if ([string]::IsNullOrWhiteSpace($ProfileDir)) {
        throw 'Tor profile path is empty — launch Tor Browser once, then tor-harden'
    }
    if (-not (Test-Path $ProfileDir)) {
        New-Item -ItemType Directory -Force -Path $ProfileDir | Out-Null
    }

    $userJs = Join-Path $ProfileDir 'user.js'
    @'
// KGreen HOME BASE — Tor session hardening (do not edit manually unless you know why)
user_pref("media.peerconnection.enabled", false);
user_pref("media.peerconnection.ice.default_address_only", true);
user_pref("media.peerconnection.ice.no_host", true);
user_pref("geo.enabled", false);
user_pref("dom.battery.enabled", false);
user_pref("network.dns.disableIPv6", true);
user_pref("privacy.trackingprotection.enabled", true);
user_pref("privacy.trackingprotection.socialtracking.enabled", true);
user_pref("browser.safebrowsing.malware.enabled", false);
user_pref("browser.safebrowsing.phishing.enabled", false);
user_pref("extensions.pocket.enabled", false);
user_pref("browser.sessionstore.privacy_level", 2);
user_pref("privacy.clearOnShutdown.cache", true);
user_pref("privacy.clearOnShutdown.cookies", true);
user_pref("privacy.clearOnShutdown.history", true);
user_pref("privacy.clearOnShutdown.sessions", true);
'@ | Set-Content $userJs -Encoding UTF8

    return $userJs
}

function Get-TorBrowserProfileDir {
    $root = Find-TorBrowserRoot
    if (-not $root) { return $null }
    $data = Join-Path $root 'Browser\TorBrowser\Data\Browser'
    if (-not (Test-Path $data)) { return $null }

    $default = Join-Path $data 'profile.default'
    if (Test-Path $default) { return $default }

    $profile = Get-ChildItem $data -Directory -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -match '^profile\.' } |
        Sort-Object Name |
        Select-Object -First 1
    if ($profile) { return $profile.FullName }
    return $default
}

function Ensure-TorBrowserProfileDir {
    $profile = Get-TorBrowserProfileDir
    if ($profile) { return $profile }

    $root = Find-TorBrowserRoot
    if (-not $root) { return $null }

    $data = Join-Path $root 'Browser\TorBrowser\Data\Browser'
    $default = Join-Path $data 'profile.default'
    if (-not (Test-Path $data)) {
        New-Item -ItemType Directory -Force -Path $data | Out-Null
    }
    if (-not (Test-Path $default)) {
        New-Item -ItemType Directory -Force -Path $default | Out-Null
    }
    return $default
}

function Get-KGreenTorFirewallRules {
    Get-NetFirewallRule -ErrorAction SilentlyContinue |
        Where-Object { $_.DisplayName -like 'KGreen-Tor-*' }
}

function Remove-KGreenTorFirewallRules {
    Get-KGreenTorFirewallRules | Remove-NetFirewallRule -ErrorAction SilentlyContinue
}

function Test-TorKillSwitchActive {
    $rules = Get-KGreenTorFirewallRules | Where-Object { $_.Enabled -eq 'True' }
    if ($rules) { return $true }
    return $env:WORKSTATION_TOR_LOCK -eq '1'
}

function Enable-TorKillSwitch {
    if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
            [Security.Principal.WindowsBuiltInRole]::Administrator)) {
        throw 'tor-lock requires Administrator (firewall rules).'
    }

    $torExe = Find-TorBrowserExe
    if (-not $torExe) { throw 'Tor Browser not found — run tor-setup first.' }

    $torDir = Split-Path $torExe -Parent
    Remove-KGreenTorFirewallRules

    $ruleCommon = @{ Group = 'KGreen-Tor-Lock'; Direction = 'Outbound'; Profile = 'Any'; Enabled = 'True' }

    New-NetFirewallRule @ruleCommon -DisplayName 'KGreen-Tor-Allow-TorBrowser' `
        -Action Allow -Program $torExe | Out-Null

    $torProcess = Join-Path $torDir 'TorBrowser\Tor\tor.exe'
    if (Test-Path $torProcess) {
        New-NetFirewallRule @ruleCommon -DisplayName 'KGreen-Tor-Allow-tor' `
            -Action Allow -Program $torProcess | Out-Null
    }

    $blockPrograms = @(
        "${env:ProgramFiles}\Google\Chrome\Application\chrome.exe"
        "${env:ProgramFiles(x86)}\Google\Chrome\Application\chrome.exe"
        "${env:ProgramFiles}\Microsoft\Edge\Application\msedge.exe"
        "${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe"
        "${env:ProgramFiles}\Mozilla Firefox\firefox.exe"
        "${env:ProgramFiles(x86)}\Mozilla Firefox\firefox.exe"
        "${env:ProgramFiles}\BraveSoftware\Brave-Browser\Application\brave.exe"
    )
    foreach ($prog in $blockPrograms) {
        if (-not (Test-Path $prog)) { continue }
        if ($prog -like "$torDir*") { continue }
        $name = Split-Path $prog -Leaf
        New-NetFirewallRule @ruleCommon -DisplayName "KGreen-Tor-Block-$name" `
            -Action Block -Program $prog | Out-Null
    }

    [Environment]::SetEnvironmentVariable('WORKSTATION_TOR_LOCK', '1', 'User')
}

function Disable-TorKillSwitch {
    if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
            [Security.Principal.WindowsBuiltInRole]::Administrator)) {
        throw 'tor-unlock requires Administrator.'
    }
    Remove-KGreenTorFirewallRules
    [Environment]::SetEnvironmentVariable('WORKSTATION_TOR_LOCK', $null, 'User')
}

function Invoke-TorPreflightCheck {
    $checks = [System.Collections.Generic.List[object]]::new()

    $tor = Find-TorBrowserExe
    $checks.Add([PSCustomObject]@{
        Check = 'Tor Browser installed'
        Ok    = [bool]$tor
        Hint  = if ($tor) { 'OK' } else { 'tor-setup' }
    })

    $pgp = $null
    if (Get-Command Initialize-GpgPath -ErrorAction SilentlyContinue) {
        Initialize-GpgPath | Out-Null
        if (Get-Command Get-GpgPrimaryFingerprint -ErrorAction SilentlyContinue) {
            $pgp = Get-GpgPrimaryFingerprint
        }
    }
    if (-not $pgp -and (Get-Command gpg -ErrorAction SilentlyContinue)) {
        $pgpLine = gpg --list-secret-keys --with-colons 2>$null | Where-Object { $_ -match '^fpr:' } | Select-Object -First 1
        $pgp = if ($pgpLine) { ($pgpLine -split ':')[9] } else { $null }
    }
    $checks.Add([PSCustomObject]@{
        Check = 'PGP key ready'
        Ok    = [bool]$pgp
        Hint  = if ($pgp) { $pgp.Substring(0, 16) + '…' } else { 'pgp-repair / pgp-setup' }
    })

    $state = Get-TorSecurityState
    $checks.Add([PSCustomObject]@{
        Check = 'Tor profile hardened'
        Ok    = [bool]($state -and $state.Hardened)
        Hint  = if ($state -and $state.Hardened) { 'OK' } else { 'tor-harden' }
    })

    $lock = Test-TorKillSwitchActive
    $checks.Add([PSCustomObject]@{
        Check = 'Kill switch (clearnet browsers blocked)'
        Ok    = $lock
        Hint  = if ($lock) { 'ACTIVE' } else { 'tor-lock (admin) before session' }
    })

    $checks.Add([PSCustomObject]@{
        Check = 'Defender stays OFF (your policy)'
        Ok    = $true
        Hint  = 'manual AV — do not re-enable Defender'
    })

    return $checks
}
