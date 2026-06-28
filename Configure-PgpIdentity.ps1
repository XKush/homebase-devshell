#Requires -Version 7.0
<#
.SYNOPSIS
    Guided OpenPGP key creation for KGreen workstation.
.PARAMETER Name
    Real name or pseudonym shown on the key (use pseudonym for privacy contexts).
.PARAMETER Email
    Optional email on key — can be omitted for darknet-only keys.
.PARAMETER ExpireDays
    Key validity in days (0 = no expiry). Default 730 (2 years).
#>
param(
    [string]$Name,
    [string]$Email,
    [int]$ExpireDays = 730,
    [switch]$Force
)

$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\lib\WorkstationCommon.ps1"
. "$PSScriptRoot\lib\PgpCommon.ps1"

if (-not (Get-Command gpg -ErrorAction SilentlyContinue)) {
    Write-WorkstationLog 'GnuPG not found — run Install-PgpToolkit.ps1 first' 'ERROR'
    exit 1
}

$secDir = 'C:\Security\pgp'
$bakDir = 'C:\Backups\Workstation\pgp'
foreach ($d in @($secDir, $bakDir)) {
    if (-not (Test-Path $d)) { New-Item -ItemType Directory -Force -Path $d | Out-Null }
}

Write-WorkstationStep 'OpenPGP identity setup (RU)'
Write-Host @'

  PGP = шифрование сообщений + проверка подлинности (подпись).
  Tor скрывает КУДА ты ходишь. PGP защищает ЧТО ты отправляешь.

  ВАЖНО:
  - Придумай длинную passphrase (12+ символов) — без неё ключ бесполезен
  - Никому не отправляй ПРИВАТНЫЙ ключ
  - Для анонимных контекстов используй ПСЕВДОНИМ, не реальное имя

'@ -ForegroundColor Cyan

if (-not $Name) {
    $Name = Read-Host '  Имя/псевдоним для ключа (например: KGreen-Op)'
}
if (-not $Email) {
    $Email = Read-Host '  Email (Enter = без email, только псевдоним)'
}

$uid = if ($Email) { "$Name <$Email>" } else { $Name }

$existing = gpg --list-secret-keys --keyid-format long 2>$null
if ($existing -and -not $Force) {
    Write-Host '  Уже есть ключ(и). Показать: gpg --list-secret-keys' -ForegroundColor Yellow
    $go = Read-Host '  Создать ещё один ключ? (y/N)'
    if ($go -ne 'y') { return }
}

Write-Host "`n  Создаю ключ Ed25519 (современный стандарт)..." -ForegroundColor Green
Write-Host '  GnuPG запросит passphrase — вводи вручную (не сохраняется в скрипт).' -ForegroundColor DarkGray

$expireArg = if ($ExpireDays -le 0) { '0' } else { "${ExpireDays}d" }
$batch = @"
Key-Type: eddsa
Key-Curve: Ed25519
Key-Usage: sign
Subkey-Type: ecdh
Subkey-Curve: Cv25519
Subkey-Usage: encrypt
Name-Real: $Name
$(if ($Email) { "Name-Email: $Email" })
Expire-Date: $expireArg
"@

$batchFile = Join-Path $env:TEMP "kgreen-pgp-batch-$(Get-Random).txt"
$batch | Set-Content $batchFile -Encoding ASCII

try {
    gpg --batch --generate-key $batchFile
} finally {
    Remove-Item $batchFile -Force -ErrorAction SilentlyContinue
}

$fpr = Get-GpgPrimaryFingerprint

if (-not $fpr) {
    Write-WorkstationLog 'Key creation failed or cancelled' 'ERROR'
    exit 1
}

Write-WorkstationStep 'Export public key + revocation certificate'
$result = Complete-PgpIdentityExport -Uid $uid -Fingerprint $fpr

Write-Host ''
Write-WorkstationLog "Fingerprint: $fpr" 'OK'
Write-WorkstationLog "Public key:  $($result.PublicKey)" 'OK'
Write-Host @'

  Готово. Дальше:
    pgp-export     — показать публичный ключ для контактов
    pgp-fingerprint — отпечаток для проверки
    docs/ru/PGP-TOR-BASICS.md — шпаргалка

'@ -ForegroundColor Green
