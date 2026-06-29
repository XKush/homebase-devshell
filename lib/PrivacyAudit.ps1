# Privacy audit library — read-only checks + scoring (no system changes)
# C:\Scripts\Workstation\lib\PrivacyAudit.ps1

function Get-PrivacyRegistryDword {
    param([string]$Path, [string]$Name)
    try {
        $v = Get-ItemProperty -Path $Path -Name $Name -ErrorAction Stop
        return $v.$Name
    } catch { return $null }
}

function New-PrivacyCheck {
    param(
        [Parameter(Mandatory)][string]$Id,
        [Parameter(Mandatory)][string]$Label,
        [ValidateSet('Pass', 'Warn', 'Fail', 'Info')]
        [string]$Status,
        [string]$Detail = '',
        [int]$Weight = 5
    )
    [PSCustomObject]@{
        Id     = $Id
        Label  = $Label
        Status = $Status
        Detail = $Detail
        Weight = $Weight
    }
}

function Get-PrivacyRiskLevel {
    param(
        [int]$Score,
        $ScoringConfig
    )
    $high = 85
    $medium = 65
    if ($ScoringConfig -and $ScoringConfig.riskLevels) {
        if ($null -ne $ScoringConfig.riskLevels.high) { $high = [int]$ScoringConfig.riskLevels.high }
        if ($null -ne $ScoringConfig.riskLevels.medium) { $medium = [int]$ScoringConfig.riskLevels.medium }
    }
    if ($Score -ge $high) { return 'High privacy' }
    if ($Score -ge $medium) { return 'Medium privacy' }
    return 'Low privacy'
}

function Get-PrivacyScoringConfig {
    param($Profile)
    $defaults = @{
        maxScore       = 100
        warnMultiplier = 0.5
        riskLevels     = @{ high = 85; medium = 65 }
        weights        = @{}
    }
    if (-not $Profile -or -not $Profile.scoring) { return $defaults }
    $s = $Profile.scoring
    if ($null -ne $s.maxScore) { $defaults.maxScore = [int]$s.maxScore }
    if ($null -ne $s.warnMultiplier) { $defaults.warnMultiplier = [double]$s.warnMultiplier }
    if ($s.riskLevels) {
        if ($null -ne $s.riskLevels.high) { $defaults.riskLevels.high = [int]$s.riskLevels.high }
        if ($null -ne $s.riskLevels.medium) { $defaults.riskLevels.medium = [int]$s.riskLevels.medium }
    }
    if ($s.weights) {
        foreach ($p in $s.weights.PSObject.Properties) {
            $defaults.weights[$p.Name] = [int]$p.Value
        }
    }
    return $defaults
}

function Set-PrivacyCheckWeights {
    param(
        [object[]]$Checks,
        $ScoringConfig
    )
    if (-not $ScoringConfig -or -not $ScoringConfig.weights) { return $Checks }
    foreach ($c in $Checks) {
        if ($ScoringConfig.weights.ContainsKey($c.Id)) {
            $c.Weight = [int]$ScoringConfig.weights[$c.Id]
        }
    }
    return $Checks
}

function Get-PrivacyCheckDeduction {
    param([object]$Check, $ScoringConfig)
    if ($Check.Weight -le 0) { return 0 }
    $mult = if ($ScoringConfig -and $ScoringConfig.warnMultiplier) { [double]$ScoringConfig.warnMultiplier } else { 0.5 }
    switch ($Check.Status) {
        'Fail' { return $Check.Weight }
        'Warn' { return [math]::Ceiling($Check.Weight * $mult) }
        default { return 0 }
    }
}

function Get-PrivacyAuditContext {
    param([string]$RepoRoot)
    $elevated = $false
    if (Get-Command Test-WorkstationAdmin -ErrorAction SilentlyContinue) {
        $elevated = Test-WorkstationAdmin
    } else {
        $id = [Security.Principal.WindowsIdentity]::GetCurrent()
        $elevated = ([Security.Principal.WindowsPrincipal]$id).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    }
    $profile = Get-PrivacyProfile -RepoRoot $RepoRoot
    $scoring = Get-PrivacyScoringConfig -Profile $profile
    $limitations = [System.Collections.Generic.List[string]]::new()
    if (-not $elevated) {
        $limitations.Add('HKLM policy checks may be incomplete without elevation')
        $limitations.Add('DNS/DoH fixes require elevation')
    }
    [PSCustomObject]@{
        RepoRoot    = $RepoRoot
        Elevated    = $elevated
        Profile     = $profile
        Scoring     = $scoring
        Limitations = $limitations
        Offline     = $true
    }
}

function ConvertTo-PrivacyReportDocument {
    param(
        [Parameter(Mandatory)][object]$Report,
        [string]$ProductVersion = '0.0.0',
        [object]$Context
    )
    $scoring = if ($Report.ScoringConfig) { $Report.ScoringConfig } elseif ($Context) { $Context.Scoring } else { Get-PrivacyScoringConfig -Profile $null }
    $checkRows = foreach ($c in $Report.Checks) {
        [ordered]@{
            id         = $c.Id
            label      = $c.Label
            status     = $c.Status
            detail     = $c.Detail
            weight     = $c.Weight
            deduction  = (Get-PrivacyCheckDeduction -Check $c -ScoringConfig $scoring)
        }
    }
    [ordered]@{
        reportSchemaVersion = '1.0.0'
        productVersion      = $ProductVersion
        timestamp           = $Report.Timestamp
        host                = $env:COMPUTERNAME
        scope               = $Report.Scope
        elevated            = if ($Context) { $Context.Elevated } else { $null }
        offlineCapable      = $true
        limitations         = if ($Context) { @($Context.Limitations) } else { @() }
        score               = [ordered]@{
            value     = $Report.Score
            max       = if ($scoring.maxScore) { [int]$scoring.maxScore } else { 100 }
            riskLevel = $Report.RiskLevel
        }
        summary             = [ordered]@{
            pass = $Report.PassCount
            warn = $Report.WarnCount
            fail = $Report.FailCount
            info = $Report.InfoCount
        }
        checks              = @($checkRows)
    }
}

function Test-DnsOverHttpsConfigured {
    try {
        $doh = Get-DnsClientDohServerAddress -ErrorAction Stop
        return @($doh).Count -gt 0
    } catch { return $false }
}

function Get-PrivacyConfigPath {
    param([string]$RepoRoot)
    $userPath = Join-Path $env:USERPROFILE '.homebase\privacy.json'
    if (Test-Path $userPath) { return $userPath }
    if ($RepoRoot) {
        $default = Join-Path $RepoRoot 'Config\privacy.defaults.json'
        if (Test-Path $default) { return $default }
    }
    return $null
}

function Get-PrivacyProfile {
    param([string]$RepoRoot)
    $path = Get-PrivacyConfigPath -RepoRoot $RepoRoot
    if (-not $path) { return $null }
    try { return Get-Content $path -Raw | ConvertFrom-Json } catch { return $null }
}

function Get-SystemPrivacyChecks {
    param($Context)

    $elevated = if ($Context) { $Context.Elevated } else { $true }
    $checks = [System.Collections.Generic.List[object]]::new()

    # DNS over HTTPS
    if (Test-DnsOverHttpsConfigured) {
        $checks.Add((New-PrivacyCheck -Id 'doh' -Label 'DNS over HTTPS' -Status Pass -Detail 'DoH templates configured'))
    } else {
        $checks.Add((New-PrivacyCheck -Id 'doh' -Label 'DNS over HTTPS' -Status Warn -Detail 'DoH not configured — devshell privacy -Fix can enable'))
    }

    # DNS servers (info)
    try {
        $dns = Get-DnsClientServerAddress -AddressFamily IPv4 -ErrorAction Stop |
            Where-Object { $_.ServerAddresses } | Select-Object -First 1
        $addrs = if ($dns) { $dns.ServerAddresses -join ', ' } else { 'unknown' }
        $checks.Add((New-PrivacyCheck -Id 'dns' -Label 'DNS servers' -Status Info -Detail $addrs -Weight 0))
    } catch {
        $checks.Add((New-PrivacyCheck -Id 'dns' -Label 'DNS servers' -Status Info -Detail 'unable to read' -Weight 0))
    }

    # VPN
    $vpnActive = $false
    $vpnName = $null
    try {
        $vpn = Get-VpnConnection -ErrorAction SilentlyContinue | Where-Object { $_.ConnectionStatus -eq 'Connected' } | Select-Object -First 1
        if ($vpn) { $vpnActive = $true; $vpnName = $vpn.Name }
    } catch { }
    if (-not $vpnActive) {
        $tun = Get-NetAdapter -ErrorAction SilentlyContinue |
            Where-Object { $_.Status -eq 'Up' -and $_.InterfaceDescription -match 'WireGuard|TAP|TUN|OpenVPN|Wintun' } |
            Select-Object -First 1
        if ($tun) { $vpnActive = $true; $vpnName = $tun.InterfaceDescription }
    }
    if ($vpnActive) {
        $checks.Add((New-PrivacyCheck -Id 'vpn' -Label 'VPN' -Status Pass -Detail "Active: $vpnName"))
    } else {
        $checks.Add((New-PrivacyCheck -Id 'vpn' -Label 'VPN' -Status Info -Detail 'VPN not detected' -Weight 0))
    }

    # Telemetry
    $tel = Get-PrivacyRegistryDword 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection' 'AllowTelemetry'
    if ($tel -eq 0) {
        $checks.Add((New-PrivacyCheck -Id 'telemetry' -Label 'Telemetry' -Status Pass -Detail 'Minimal/disabled'))
    } elseif ($null -eq $tel -and -not $elevated) {
        $checks.Add((New-PrivacyCheck -Id 'telemetry' -Label 'Telemetry' -Status Info -Detail 'HKLM policy unreadable without elevation' -Weight 0))
    } elseif ($null -eq $tel) {
        $checks.Add((New-PrivacyCheck -Id 'telemetry' -Label 'Telemetry' -Status Warn -Detail 'Default Windows level'))
    } else {
        $checks.Add((New-PrivacyCheck -Id 'telemetry' -Label 'Telemetry' -Status Warn -Detail "Level $tel"))
    }

    # Advertising ID
    $adId = Get-PrivacyRegistryDword 'HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo' 'Enabled'
    if ($adId -eq 0) {
        $checks.Add((New-PrivacyCheck -Id 'adid' -Label 'Advertising ID' -Status Pass))
    } else {
        $checks.Add((New-PrivacyCheck -Id 'adid' -Label 'Advertising ID' -Status Warn -Detail 'Enabled'))
    }

    # Location
    $loc = Get-PrivacyRegistryDword 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors' 'DisableLocation'
    if ($loc -eq 1) {
        $checks.Add((New-PrivacyCheck -Id 'location' -Label 'Location services' -Status Pass -Detail 'Disabled by policy'))
    } else {
        $locUser = Get-PrivacyRegistryDword 'HKCU:\Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location' 'Value'
        if ($locUser -eq 'Deny') {
            $checks.Add((New-PrivacyCheck -Id 'location' -Label 'Location services' -Status Pass -Detail 'Denied for apps'))
        } else {
            $checks.Add((New-PrivacyCheck -Id 'location' -Label 'Location services' -Status Warn -Detail 'May be enabled'))
        }
    }

    # Clipboard history
    $clip = Get-PrivacyRegistryDword 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System' 'AllowClipboardHistory'
    if ($clip -eq 0) {
        $checks.Add((New-PrivacyCheck -Id 'clipboard' -Label 'Clipboard history' -Status Pass -Detail 'Disabled'))
    } else {
        $clipUser = Get-PrivacyRegistryDword 'HKCU:\Software\Microsoft\Clipboard' 'EnableClipboardHistory'
        if ($clipUser -eq 0) {
            $checks.Add((New-PrivacyCheck -Id 'clipboard' -Label 'Clipboard history' -Status Pass))
        } else {
            $checks.Add((New-PrivacyCheck -Id 'clipboard' -Label 'Clipboard history' -Status Warn -Detail 'May retain history'))
        }
    }

    # Recent files / activity
    $track = Get-PrivacyRegistryDword 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'Start_TrackProgs'
    $recent = Get-PrivacyRegistryDword 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer' 'ShowRecent'
    if ($track -eq 0 -and $recent -eq 0) {
        $checks.Add((New-PrivacyCheck -Id 'recent' -Label 'Recent files' -Status Pass))
    } else {
        $checks.Add((New-PrivacyCheck -Id 'recent' -Label 'Recent files' -Status Warn -Detail 'Start/recent tracking may be on'))
    }

    # Search highlights
    $highlights = Get-PrivacyRegistryDword 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Search' 'EnableDynamicContentInWSB'
    if ($highlights -eq 0) {
        $checks.Add((New-PrivacyCheck -Id 'searchhl' -Label 'Search highlights' -Status Pass))
    } elseif ($null -eq $highlights) {
        $checks.Add((New-PrivacyCheck -Id 'searchhl' -Label 'Search highlights' -Status Info -Detail 'Default' -Weight 0))
    } else {
        $checks.Add((New-PrivacyCheck -Id 'searchhl' -Label 'Search highlights' -Status Warn))
    }

    # Windows Search indexing (info)
    $wsearch = Get-Service WSearch -ErrorAction SilentlyContinue
    if ($wsearch) {
        $st = if ($wsearch.Status -eq 'Running') { 'Running' } else { $wsearch.StartType.ToString() }
        $checks.Add((New-PrivacyCheck -Id 'wsearch' -Label 'Windows Search indexing' -Status Info -Detail $st -Weight 0))
    }

    # SmartScreen (informational — we do not disable)
    $smart = Get-PrivacyRegistryDword 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System' 'EnableSmartScreen'
    if ($smart -eq 0) {
        $checks.Add((New-PrivacyCheck -Id 'smartscreen' -Label 'SmartScreen' -Status Info -Detail 'Disabled by policy' -Weight 0))
    } else {
        $checks.Add((New-PrivacyCheck -Id 'smartscreen' -Label 'SmartScreen' -Status Info -Detail 'Enabled (recommended)' -Weight 0))
    }

    # BitLocker
    try {
        $bl = Get-BitLockerVolume -MountPoint 'C:' -ErrorAction Stop
        if ($bl.ProtectionStatus -eq 'On') {
            $checks.Add((New-PrivacyCheck -Id 'bitlocker' -Label 'BitLocker' -Status Pass -Detail $bl.VolumeStatus))
        } else {
            $checks.Add((New-PrivacyCheck -Id 'bitlocker' -Label 'BitLocker' -Status Warn -Detail 'C: not encrypted'))
        }
    } catch {
        $checks.Add((New-PrivacyCheck -Id 'bitlocker' -Label 'BitLocker' -Status Info -Detail 'Unavailable on this edition' -Weight 0))
    }

    # Secure Boot
    try {
        if (Confirm-SecureBootUEFI) {
            $checks.Add((New-PrivacyCheck -Id 'secureboot' -Label 'Secure Boot' -Status Pass))
        } else {
            $checks.Add((New-PrivacyCheck -Id 'secureboot' -Label 'Secure Boot' -Status Warn -Detail 'Disabled or legacy BIOS'))
        }
    } catch {
        $checks.Add((New-PrivacyCheck -Id 'secureboot' -Label 'Secure Boot' -Status Info -Detail 'Check unavailable' -Weight 0))
    }

    # TPM
    try {
        $tpm = Get-Tpm -ErrorAction Stop
        if ($tpm.TpmPresent -and $tpm.TpmReady) {
            $checks.Add((New-PrivacyCheck -Id 'tpm' -Label 'TPM' -Status Pass))
        } elseif ($tpm.TpmPresent) {
            $checks.Add((New-PrivacyCheck -Id 'tpm' -Label 'TPM' -Status Warn -Detail 'Present but not ready'))
        } else {
            $checks.Add((New-PrivacyCheck -Id 'tpm' -Label 'TPM' -Status Warn -Detail 'Not present'))
        }
    } catch {
        $checks.Add((New-PrivacyCheck -Id 'tpm' -Label 'TPM' -Status Info -Detail 'Check skipped' -Weight 0))
    }

    # Time sync
    $w32 = Get-Service W32Time -ErrorAction SilentlyContinue
    if ($w32 -and $w32.Status -eq 'Running') {
        $checks.Add((New-PrivacyCheck -Id 'timesync' -Label 'Time sync' -Status Pass -Detail 'W32Time running'))
    } else {
        $checks.Add((New-PrivacyCheck -Id 'timesync' -Label 'Time sync' -Status Warn -Detail 'W32Time not running'))
    }

    # Public Wi-Fi profile
    try {
        $pub = Get-NetConnectionProfile -ErrorAction Stop | Where-Object { $_.NetworkCategory -eq 'Public' }
        if ($pub) {
            $checks.Add((New-PrivacyCheck -Id 'wifi' -Label 'Public Wi-Fi profile' -Status Pass -Detail ($pub.InterfaceAlias -join ', ')))
        } else {
            $priv = Get-NetConnectionProfile -ErrorAction SilentlyContinue | Select-Object -First 1
            $cat = if ($priv) { $priv.NetworkCategory } else { 'unknown' }
            $checks.Add((New-PrivacyCheck -Id 'wifi' -Label 'Network profile' -Status Info -Detail "Category: $cat" -Weight 0))
        }
    } catch {
        $checks.Add((New-PrivacyCheck -Id 'wifi' -Label 'Network profile' -Status Info -Detail 'Unable to read' -Weight 0))
    }

    # Camera / microphone (capability store)
    foreach ($cap in @(
        @{ Id = 'camera'; Path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\webcam'; Name = 'Camera' }
        @{ Id = 'mic'; Path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\microphone'; Name = 'Microphone' }
    )) {
        $val = Get-PrivacyRegistryDword $cap.Path 'Value'
        if ($val -eq 'Deny') {
            $checks.Add((New-PrivacyCheck -Id $cap.Id -Label $cap.Name -Status Pass -Detail 'Denied for apps'))
        } elseif ($val -eq 'Allow') {
            $checks.Add((New-PrivacyCheck -Id $cap.Id -Label $cap.Name -Status Warn -Detail 'Allowed for some apps'))
        } else {
            $checks.Add((New-PrivacyCheck -Id $cap.Id -Label $cap.Name -Status Info -Detail 'User-controlled default' -Weight 0))
        }
    }

    return @($checks)
}

function Get-BrowserPrivacyChecks {
    param(
        [ValidateSet('Chrome', 'Edge', 'Firefox', 'All')][string]$Browser = 'All',
        $Context
    )

    $elevated = if ($Context) { $Context.Elevated } else { $true }

    $checks = [System.Collections.Generic.List[object]]::new()
    $targets = if ($Browser -eq 'All') { @('Chrome', 'Edge', 'Firefox') } else { @($Browser) }

    foreach ($b in $targets) {
        $installed = $false
        switch ($b) {
            'Chrome' {
                $installed = Test-Path "${env:ProgramFiles}\Google\Chrome\Application\chrome.exe"
                if (-not $installed) { $installed = Test-Path "${env:ProgramFiles(x86)}\Google\Chrome\Application\chrome.exe" }
                if (-not $installed) {
                    $checks.Add((New-PrivacyCheck -Id 'chrome-missing' -Label 'Chrome' -Status Info -Detail 'Not installed' -Weight 0))
                    continue
                }
                $doh = Get-PrivacyRegistryDword 'HKLM:\SOFTWARE\Policies\Google\Chrome' 'DnsOverHttpsMode'
                if ($doh -eq 'secure') {
                    $checks.Add((New-PrivacyCheck -Id 'chrome-doh' -Label 'Chrome DNS over HTTPS' -Status Pass))
                } elseif (-not $elevated) {
                    $checks.Add((New-PrivacyCheck -Id 'chrome-doh' -Label 'Chrome DNS over HTTPS' -Status Info -Detail 'HKLM policy unreadable without elevation' -Weight 0))
                } else {
                    $checks.Add((New-PrivacyCheck -Id 'chrome-doh' -Label 'Chrome DNS over HTTPS' -Status Warn -Detail 'Not enforced via policy'))
                }
                $third = Get-PrivacyRegistryDword 'HKLM:\SOFTWARE\Policies\Google\Chrome' 'BlockThirdPartyCookies'
                if ($third -eq 1) {
                    $checks.Add((New-PrivacyCheck -Id 'chrome-cookies' -Label 'Chrome third-party cookies' -Status Pass -Detail 'Blocked by policy'))
                } elseif (-not $elevated) {
                    $checks.Add((New-PrivacyCheck -Id 'chrome-cookies' -Label 'Chrome third-party cookies' -Status Info -Detail 'HKLM policy unreadable without elevation' -Weight 0))
                } else {
                    $checks.Add((New-PrivacyCheck -Id 'chrome-cookies' -Label 'Chrome third-party cookies' -Status Warn -Detail 'Not blocked by policy'))
                }
            }
            'Edge' {
                $installed = Test-Path "${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe"
                if (-not $installed) {
                    $checks.Add((New-PrivacyCheck -Id 'edge-missing' -Label 'Edge' -Status Info -Detail 'Not installed' -Weight 0))
                    continue
                }
                $doh = Get-PrivacyRegistryDword 'HKLM:\SOFTWARE\Policies\Microsoft\Edge' 'DnsOverHttpsMode'
                if ($doh -eq 'secure') {
                    $checks.Add((New-PrivacyCheck -Id 'edge-doh' -Label 'Edge DNS over HTTPS' -Status Pass))
                } elseif (-not $elevated) {
                    $checks.Add((New-PrivacyCheck -Id 'edge-doh' -Label 'Edge DNS over HTTPS' -Status Info -Detail 'HKLM policy unreadable without elevation' -Weight 0))
                } else {
                    $checks.Add((New-PrivacyCheck -Id 'edge-doh' -Label 'Edge DNS over HTTPS' -Status Warn -Detail 'Not enforced via policy'))
                }
                $sync = Get-PrivacyRegistryDword 'HKLM:\SOFTWARE\Policies\Microsoft\Edge' 'SyncDisabled'
                if ($sync -eq 1) {
                    $checks.Add((New-PrivacyCheck -Id 'edge-sync' -Label 'Edge sync' -Status Pass -Detail 'Disabled by policy'))
                } elseif (-not $elevated) {
                    $checks.Add((New-PrivacyCheck -Id 'edge-sync' -Label 'Edge sync' -Status Info -Detail 'HKLM policy unreadable without elevation' -Weight 0))
                } else {
                    $checks.Add((New-PrivacyCheck -Id 'edge-sync' -Label 'Edge sync' -Status Warn -Detail 'Browser sync may be on'))
                }
            }
            'Firefox' {
                $ffRoot = Join-Path $env:APPDATA 'Mozilla\Firefox'
                if (-not (Test-Path $ffRoot)) {
                    $checks.Add((New-PrivacyCheck -Id 'ff-missing' -Label 'Firefox' -Status Info -Detail 'Not installed' -Weight 0))
                    continue
                }
                $profilesIni = Join-Path $ffRoot 'profiles.ini'
                $prefsPath = $null
                if (Test-Path $profilesIni) {
                    $ini = Get-Content $profilesIni -Raw
                    if ($ini -match 'Path=(.+Default.+)\r?\n') {
                        $rel = $Matches[1].Trim()
                        $prefsPath = Join-Path $ffRoot $rel
                    }
                }
                $prefsFile = if ($prefsPath) { Join-Path $prefsPath 'prefs.js' } else { $null }
                $prefs = if ($prefsFile -and (Test-Path $prefsFile)) { Get-Content $prefsFile -Raw } else { '' }

                if ($prefs -match 'network\.trr\.mode",\s*(\d+)') {
                    $mode = [int]$Matches[1]
                    if ($mode -ge 2) {
                        $checks.Add((New-PrivacyCheck -Id 'ff-doh' -Label 'Firefox DNS over HTTPS' -Status Pass -Detail "TRR mode $mode"))
                    } else {
                        $checks.Add((New-PrivacyCheck -Id 'ff-doh' -Label 'Firefox DNS over HTTPS' -Status Warn -Detail "TRR mode $mode"))
                    }
                } else {
                    $checks.Add((New-PrivacyCheck -Id 'ff-doh' -Label 'Firefox DNS over HTTPS' -Status Warn -Detail 'TRR not configured in prefs'))
                }

                if ($prefs -match 'dom\.security\.https_only_mode",\s*true') {
                    $checks.Add((New-PrivacyCheck -Id 'ff-https' -Label 'Firefox HTTPS-Only' -Status Pass))
                } else {
                    $checks.Add((New-PrivacyCheck -Id 'ff-https' -Label 'Firefox HTTPS-Only' -Status Warn -Detail 'Disabled or default'))
                }

                if ($prefs -match 'privacy\.trackingprotection\.enabled",\s*true') {
                    $checks.Add((New-PrivacyCheck -Id 'ff-etp' -Label 'Firefox Enhanced Tracking Protection' -Status Pass))
                } else {
                    $checks.Add((New-PrivacyCheck -Id 'ff-etp' -Label 'Firefox Enhanced Tracking Protection' -Status Info -Detail 'Default or custom' -Weight 0))
                }
            }
        }
    }
    return @($checks)
}

function Get-TorReadinessChecks {
  param([string]$RepoRoot)
    $checks = [System.Collections.Generic.List[object]]::new()

    if ($RepoRoot -and (Test-Path (Join-Path $RepoRoot 'lib\TorCommon.ps1'))) {
        . (Join-Path $RepoRoot 'lib\TorCommon.ps1')
    }

    $torExe = if (Get-Command Find-TorBrowserExe -ErrorAction SilentlyContinue) { Find-TorBrowserExe } else { $null }
    if ($torExe) {
        $ver = (Get-Item $torExe).VersionInfo.ProductVersion
        $checks.Add((New-PrivacyCheck -Id 'tor-installed' -Label 'Tor Browser installed' -Status Pass -Detail $ver))
        $state = if (Get-Command Get-TorSecurityState -ErrorAction SilentlyContinue) { Get-TorSecurityState } else { $null }
        if ($state -and $state.Hardened) {
            $checks.Add((New-PrivacyCheck -Id 'tor-hardened' -Label 'Tor profile hardened' -Status Pass))
        } else {
            $checks.Add((New-PrivacyCheck -Id 'tor-hardened' -Label 'Tor profile hardened' -Status Warn -Detail 'Run tor-harden after first launch'))
        }
    } else {
        $checks.Add((New-PrivacyCheck -Id 'tor-installed' -Label 'Tor Browser installed' -Status Warn -Detail 'Not found — optional for Tor readiness'))
    }

    return @($checks)
}

function Get-VpnAuditChecks {
    $checks = [System.Collections.Generic.List[object]]::new()

    $wg = Get-Command wireguard -ErrorAction SilentlyContinue
    if (-not $wg) { $wg = Test-Path "${env:ProgramFiles}\WireGuard\wireguard.exe" }
    $checks.Add((New-PrivacyCheck -Id 'wireguard' -Label 'WireGuard' -Status $(if ($wg) { 'Pass' } else { 'Info' }) -Detail $(if ($wg) { 'Installed' } else { 'Not detected' }) -Weight $(if ($wg) { 0 } else { 0 })))

    $ovpn = Test-Path "${env:ProgramFiles}\OpenVPN\bin\openvpn.exe"
    if (-not $ovpn) { $ovpn = Test-Path "${env:ProgramFiles(x86)}\OpenVPN\bin\openvpn.exe" }
    $checks.Add((New-PrivacyCheck -Id 'openvpn' -Label 'OpenVPN' -Status $(if ($ovpn) { 'Pass' } else { 'Info' }) -Detail $(if ($ovpn) { 'Installed' } else { 'Not detected' }) -Weight 0))

    $tun = @(Get-NetAdapter -ErrorAction SilentlyContinue | Where-Object {
        $_.InterfaceDescription -match 'WireGuard|TAP|TUN|Wintun|OpenVPN'
    })
    if ($tun.Count) {
        $checks.Add((New-PrivacyCheck -Id 'tun' -Label 'TUN/TAP adapter' -Status Pass -Detail ($tun.Name -join ', ')))
    } else {
        $checks.Add((New-PrivacyCheck -Id 'tun' -Label 'TUN/TAP adapter' -Status Info -Detail 'None detected' -Weight 0))
    }

    $vpnActive = $false
    try {
        $vpn = Get-VpnConnection -ErrorAction SilentlyContinue | Where-Object { $_.ConnectionStatus -eq 'Connected' }
        if ($vpn) { $vpnActive = $true }
    } catch { }
    if (-not $vpnActive) {
        $up = Get-NetAdapter -ErrorAction SilentlyContinue | Where-Object {
            $_.Status -eq 'Up' -and $_.InterfaceDescription -match 'WireGuard|TAP|TUN|Wintun'
        }
        if ($up) { $vpnActive = $true }
    }
    if ($vpnActive) {
        $checks.Add((New-PrivacyCheck -Id 'vpn-active' -Label 'VPN active' -Status Pass))
    } else {
        $checks.Add((New-PrivacyCheck -Id 'vpn-active' -Label 'VPN active' -Status Info -Detail 'Not connected' -Weight 0))
    }

    # DNS leak heuristic (no external query)
    if ($vpnActive) {
        try {
            $dns = Get-DnsClientServerAddress -AddressFamily IPv4 -ErrorAction Stop |
                Where-Object { $_.ServerAddresses } | Select-Object -First 1
            $leakRisk = $dns -and ($dns.ServerAddresses -notmatch '^(10\.|172\.(1[6-9]|2[0-9]|3[01])\.|192\.168\.|127\.)')
            if ($leakRisk) {
                $checks.Add((New-PrivacyCheck -Id 'dns-leak' -Label 'DNS leak risk' -Status Warn -Detail 'Public DNS while VPN up — verify VPN DNS'))
            } else {
                $checks.Add((New-PrivacyCheck -Id 'dns-leak' -Label 'DNS leak risk' -Status Pass -Detail 'No obvious public DNS on active adapter'))
            }
        } catch {
            $checks.Add((New-PrivacyCheck -Id 'dns-leak' -Label 'DNS leak risk' -Status Info -Detail 'Unable to assess' -Weight 0))
        }
    }

    $killHint = $false
    try {
        $fw = Get-NetFirewallProfile -ErrorAction Stop | Where-Object { $_.Name -eq 'Public' -and $_.DefaultOutboundAction -eq 'Block' }
        if ($fw) { $killHint = $true }
    } catch { }
    if ($killHint) {
        $checks.Add((New-PrivacyCheck -Id 'killswitch' -Label 'Kill switch' -Status Info -Detail 'Strict outbound on Public profile — verify VPN kill switch' -Weight 0))
    } else {
        $checks.Add((New-PrivacyCheck -Id 'killswitch' -Label 'Kill switch' -Status Info -Detail 'Not detected — rely on VPN client settings' -Weight 0))
    }

    return @($checks)
}

function Get-OpsecChecks {
    param([string]$RepoRoot)

    $ctx = Get-PrivacyAuditContext -RepoRoot $RepoRoot
    $checks = [System.Collections.Generic.List[object]]::new()
    foreach ($c in (Get-SystemPrivacyChecks -Context $ctx)) { $checks.Add($c) }

    $vpn = Get-VpnAuditChecks | Where-Object { $_.Id -in @('vpn-active', 'dns-leak') }
    foreach ($c in $vpn) { $checks.Add($c) }

    # Microsoft account / OneDrive heuristics
    $msa = Get-PrivacyRegistryDword 'HKCU:\Software\Microsoft\IdentityCRL' 'StoredIdentities'
    $onedrive = Test-Path (Join-Path $env:USERPROFILE 'OneDrive')
    if ($onedrive) {
        $checks.Add((New-PrivacyCheck -Id 'onedrive' -Label 'OneDrive' -Status Warn -Detail 'Folder present — sync may be active'))
    } else {
        $checks.Add((New-PrivacyCheck -Id 'onedrive' -Label 'OneDrive' -Status Pass -Detail 'Not detected'))
    }

    try {
        $edgeSync = Get-PrivacyRegistryDword 'HKLM:\SOFTWARE\Policies\Microsoft\Edge' 'SyncDisabled'
        if ($edgeSync -eq 1) {
            $checks.Add((New-PrivacyCheck -Id 'browser-sync' -Label 'Browser sync' -Status Pass -Detail 'Edge sync disabled by policy'))
        } else {
            $checks.Add((New-PrivacyCheck -Id 'browser-sync' -Label 'Browser sync' -Status Warn -Detail 'Edge/Chrome may sync to cloud accounts'))
        }
    } catch { }

    return @($checks)
}

function Measure-PrivacyScore {
    param(
        [object[]]$Checks,
        $ScoringConfig
    )
    $max = if ($ScoringConfig -and $ScoringConfig.maxScore) { [int]$ScoringConfig.maxScore } else { 100 }
    $score = $max
    foreach ($c in $Checks) {
        $score -= (Get-PrivacyCheckDeduction -Check $c -ScoringConfig $ScoringConfig)
    }
    return [math]::Max(0, [math]::Min($max, $score))
}

function Get-PrivacyAuditReport {
    param(
        [ValidateSet('System', 'Browser', 'Tor', 'Vpn', 'Opsec')]
        [string]$Scope = 'System',
        [string]$RepoRoot,
        [string]$Browser = 'All',
        [string]$ProductVersion = '0.0.0'
    )

    $ctx = Get-PrivacyAuditContext -RepoRoot $RepoRoot
    $checks = switch ($Scope) {
        'System'  { Get-SystemPrivacyChecks -Context $ctx }
        'Browser' { Get-BrowserPrivacyChecks -Browser $Browser -Context $ctx }
        'Tor'     { Get-TorReadinessChecks -RepoRoot $RepoRoot }
        'Vpn'     { Get-VpnAuditChecks }
        'Opsec'   { Get-OpsecChecks -RepoRoot $RepoRoot }
    }

    $null = Set-PrivacyCheckWeights -Checks $checks -ScoringConfig $ctx.Scoring
    $score = Measure-PrivacyScore -Checks $checks -ScoringConfig $ctx.Scoring
    [PSCustomObject]@{
        Timestamp      = (Get-Date).ToString('o')
        Scope          = $Scope
        Score          = $score
        RiskLevel      = Get-PrivacyRiskLevel -Score $score -ScoringConfig $ctx.Scoring
        Checks         = @($checks)
        PassCount      = @($checks | Where-Object Status -eq 'Pass').Count
        WarnCount      = @($checks | Where-Object Status -eq 'Warn').Count
        FailCount      = @($checks | Where-Object Status -eq 'Fail').Count
        InfoCount      = @($checks | Where-Object Status -eq 'Info').Count
        Context        = $ctx
        ScoringConfig  = $ctx.Scoring
        ProductVersion = $ProductVersion
    }
}

function Write-PrivacyAuditReport {
    param(
        [Parameter(Mandatory)][object]$Report,
        [string]$Title = 'Privacy',
        [switch]$Quiet
    )

    if ($Quiet) { return $Report }

    $titleMap = @{
        System  = 'Privacy audit'
        Browser = 'Browser privacy audit'
        Tor     = 'Tor readiness'
        Vpn     = 'VPN audit'
        Opsec   = 'OPSEC check'
    }
    $hdr = if ($titleMap.ContainsKey($Report.Scope)) { $titleMap[$Report.Scope] } else { $Title }

    Write-Host ''
    Write-Host $hdr -ForegroundColor Cyan
    if ($Report.Context -and -not $Report.Context.Elevated) {
        Write-Host '  (standard user — HKLM checks may be incomplete)' -ForegroundColor DarkYellow
    }
    Write-Host ''
    $high = if ($Report.ScoringConfig -and $Report.ScoringConfig.riskLevels) { [int]$Report.ScoringConfig.riskLevels.high } else { 85 }
    $medium = if ($Report.ScoringConfig -and $Report.ScoringConfig.riskLevels) { [int]$Report.ScoringConfig.riskLevels.medium } else { 65 }
    Write-Host "Privacy score" -ForegroundColor DarkGray
    $scoreCol = if ($Report.Score -ge $high) { 'Green' } elseif ($Report.Score -ge $medium) { 'Yellow' } else { 'Red' }
    $maxScore = if ($Report.ScoringConfig -and $Report.ScoringConfig.maxScore) { $Report.ScoringConfig.maxScore } else { 100 }
    Write-Host "$($Report.Score)/$maxScore" -ForegroundColor $scoreCol
    Write-Host $Report.RiskLevel -ForegroundColor DarkGray
    Write-Host ''

    foreach ($c in $Report.Checks) {
        $tag = switch ($c.Status) {
            'Pass' { 'PASS' }
            'Warn' { 'WARN' }
            'Fail' { 'FAIL' }
            default { 'INFO' }
        }
        $col = switch ($c.Status) {
            'Pass' { 'Green' }
            'Warn' { 'Yellow' }
            'Fail' { 'Red' }
            default { 'DarkGray' }
        }
        $line = "$tag $($c.Label)"
        if ($c.Detail) { $line += " — $($c.Detail)" }
        Write-Host $line -ForegroundColor $col
    }
    Write-Host ''
    return $Report
}

function Save-PrivacyAuditReport {
    param(
        [Parameter(Mandatory)][object]$Report,
        [string]$LogsRoot,
        [object]$Context
    )
    if (-not $LogsRoot) {
        if (Get-Command Get-WorkstationLogsRoot -ErrorAction SilentlyContinue) {
            $LogsRoot = Get-WorkstationLogsRoot
        } else {
            $LogsRoot = 'C:\Logs\Workstation'
        }
    }
    if (-not (Test-Path $LogsRoot)) { New-Item -ItemType Directory -Force -Path $LogsRoot | Out-Null }
    $path = Join-Path $LogsRoot ("privacy-{0}-{1}.json" -f $Report.Scope.ToLower(), (Get-Date -Format 'yyyyMMdd-HHmmss'))
    $doc = ConvertTo-PrivacyReportDocument -Report $Report -ProductVersion $Report.ProductVersion -Context $(if ($Context) { $Context } else { $Report.Context })
    $doc | ConvertTo-Json -Depth 8 | Set-Content $path -Encoding UTF8
    Write-Host "Report: $path" -ForegroundColor DarkGray
    return $path
}
