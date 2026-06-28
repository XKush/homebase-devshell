# Shared OpenPGP helpers (scripts + module)

function Initialize-GpgPath {
    if (Get-Command gpg -ErrorAction SilentlyContinue) { return $true }
    foreach ($bin in @('C:\Program Files\GnuPG\bin\gpg.exe', 'C:\Program Files (x86)\GnuPG\bin\gpg.exe')) {
        if (Test-Path $bin) {
            $dir = Split-Path $bin -Parent
            if ($env:Path -notlike "*$dir*") { $env:Path = "$env:Path;$dir" }
            return $true
        }
    }
    return $false
}

function Get-GpgPrimaryFingerprint {
    if (-not (Initialize-GpgPath)) { return $null }
    $line = gpg --list-secret-keys --with-colons 2>$null | Where-Object { $_ -match '^fpr:' } | Select-Object -First 1
    if (-not $line) { return $null }
    return ($line -split ':')[9]
}

function Complete-PgpIdentityExport {
    param([string]$Uid, [string]$Fingerprint)

    if (-not (Initialize-GpgPath)) { throw 'GnuPG not found' }
    $secDir = 'C:\Security\pgp'
    $bakDir = 'C:\Backups\Workstation\pgp'
    foreach ($d in @($secDir, $bakDir)) {
        if (-not (Test-Path $d)) { New-Item -ItemType Directory -Force -Path $d | Out-Null }
    }

    $stamp = Get-Date -Format 'yyyyMMdd'
    $pubPath = Join-Path $secDir "public-key-$stamp.asc"
    gpg --armor --export $Fingerprint | Set-Content $pubPath -Encoding ASCII

    $autoRev = Join-Path $env:APPDATA "gnupg\openpgp-revocs.d\$Fingerprint.rev"
    $revPath = Join-Path $bakDir "revocation-cert-$stamp.asc"
    if (Test-Path $autoRev) {
        Copy-Item $autoRev $revPath -Force
        Write-WorkstationLog "Revocation:  $revPath (backup copy)" 'OK'
    } else {
        Write-WorkstationLog 'Revocation: auto cert in openpgp-revocs.d (GnuPG 2.5+)' 'OK'
        $revPath = $autoRev
    }

    @{
        Timestamp   = (Get-Date).ToString('o')
        Uid         = $Uid
        Fingerprint = $Fingerprint
        PublicKey   = $pubPath
        Revocation  = if (Test-Path $revPath) { $revPath } else { $null }
    } | ConvertTo-Json | Set-Content (Join-Path $secDir 'pgp-identity.json') -Encoding UTF8

    return [PSCustomObject]@{ Fingerprint = $Fingerprint; PublicKey = $pubPath; Revocation = $revPath }
}
