# OpenPGP — команды HOME BASE (для Tor + приватной переписки)
. (Join-Path $script:WSRoot 'lib\PgpCommon.ps1')

function Get-PgpIdentityMeta {
    $metaPath = 'C:\Security\pgp\pgp-identity.json'
    if (Test-Path $metaPath) {
        try { return Get-Content $metaPath -Raw | ConvertFrom-Json } catch { }
    }
    return $null
}

function Test-GpgAvailable {
    if (-not (Initialize-GpgPath)) {
        Write-HackerLine 'GnuPG не установлен → Install-PgpToolkit.ps1' -Color Yellow
        return $false
    }
    return $true
}

function Show-PgpHelpRu {
    Write-Host @'

  ═══ PGP / OpenPGP — шпаргалка для начинающих ═══

  ЗАЧЕМ (простыми словами)
    Tor          = скрывает IP и маршрут (куда зашёл)
    PGP          = шифрует текст/файлы (что отправил)
    Вместе       = транспорт анонимный + содержимое зашифровано

  ТРИ ГЛАВНЫХ ПРАВИЛА
    1. Публичный ключ — отдаёшь контактам (можно публиковать)
    2. Приватный ключ + passphrase — ТОЛЬКО у тебя, никогда не в чат/сайт
    3. Fingerprint — проверяешь лично/другим каналом (не доверяй одному сообщению)

  КОМАНДЫ HOME BASE
    pgp-setup        создать ключ (Configure-PgpIdentity.ps1)
    pgp-repair       завершить экспорт если ключ уже есть
    pgp-status       список ключей
    pgp-export       публичный ключ (.asc) — дать контакту
    pgp-fingerprint  отпечаток для проверки
    pgp-encrypt      зашифровать файл для получателя
    pgp-decrypt      расшифровать файл

  TOR
    Сайты .onion — только Tor Browser (отдельный профиль, не смешивай с обычным Chrome)
    PGP в чатах — копируешь ciphertext блоками; расшифровка локально через gpg/Kleopatra

  ФАЙЛЫ
    C:\Security\pgp\          ключи метаданные, public export
    C:\Backups\Workstation\pgp\  revocation certificate (backup!)

  Документация: docs/ru/PGP-TOR-BASICS.md

'@ -ForegroundColor Green
}

function pgp-repair {
    param([switch]$Help)
    if (Test-ShowCommandHelp -Name 'pgp-repair' -Help:$Help) { return }
    Invoke-WorkstationCmd 'pgp-repair' {
        if (-not (Test-GpgAvailable)) { return }
        & (Join-Path $script:WSRoot 'Repair-PgpIdentity.ps1')
    }
}

function pgp-setup {
    param([switch]$Help)
    if (Test-ShowCommandHelp -Name 'pgp-setup' -Help:$Help) { return }
    Invoke-WorkstationCmd 'pgp-setup' {
        & (Join-Path $script:WSRoot 'Configure-PgpIdentity.ps1')
    }
}

function pgp-status {
    param([switch]$Help)
    if (Test-ShowCommandHelp -Name 'pgp-status' -Help:$Help) { return }
    Invoke-WorkstationCmd 'pgp-status' {
        if (-not (Test-GpgAvailable)) { return }
        Write-HackerSection -Tag 'PGP' -Title 'OPENPGP KEYS' -Color Cyan
        $out = gpg --list-secret-keys --keyid-format long 2>&1
        if ($LASTEXITCODE -ne 0 -or -not $out) {
            Write-HackerLine 'ключей нет — pgp-setup' -Color Yellow
        } else {
            $out | ForEach-Object { Write-HackerLine $_ -Color DarkGray }
        }
        $meta = Get-PgpIdentityMeta
        if ($meta) {
            Write-HackerStat 'FINGERPRINT' $meta.Fingerprint -Color Green
        }
        Write-Host ''
    }
}

function pgp-export {
    param([switch]$Help, [string]$OutputPath)
    if (Test-ShowCommandHelp -Name 'pgp-export' -Help:$Help) { return }
    Invoke-WorkstationCmd 'pgp-export' {
        if (-not (Test-GpgAvailable)) { return }
        $meta = Get-PgpIdentityMeta
        $fpr = $meta.Fingerprint
        if (-not $fpr) { $fpr = Get-GpgPrimaryFingerprint }
        if (-not $fpr) { Write-HackerLine 'нет ключа — pgp-setup' -Color Red; return }
        $out = if ($OutputPath) { $OutputPath } else { Join-Path 'C:\Security\pgp' "public-key-$(Get-Date -Format yyyyMMdd).asc" }
        gpg --armor --export $fpr | Set-Content $out -Encoding ASCII
        Write-HackerLine "публичный ключ → $out" -Color Green
        Write-HackerLine 'отдай контакту; приватный ключ не трогай' -Color DarkGray
        Write-Host ''
    }
}

function pgp-fingerprint {
    param([switch]$Help)
    if (Test-ShowCommandHelp -Name 'pgp-fingerprint' -Help:$Help) { return }
    Invoke-WorkstationCmd 'pgp-fingerprint' {
        if (-not (Test-GpgAvailable)) { return }
        $meta = Get-PgpIdentityMeta
        if ($meta) {
            Write-HackerSection -Tag 'PGP' -Title 'FINGERPRINT — проверка личности' -Color Green
            Write-HackerLine $meta.Fingerprint -Color White
            Write-HackerLine 'сверь с контактом ДРУГИМ каналом (не тем же чатом)' -Color Yellow
            Write-Host ''
            return
        }
        gpg --fingerprint 2>$null
        Write-Host ''
    }
}

function pgp-encrypt {
    param(
        [switch]$Help,
        [Parameter(Mandatory)][string]$To,
        [Parameter(Mandatory)][string]$File
    )
    if (Test-ShowCommandHelp -Name 'pgp-encrypt' -Help:$Help) { return }
    Invoke-WorkstationCmd 'pgp-encrypt' {
        if (-not (Test-GpgAvailable)) { return }
        if (-not (Test-Path $File)) { Write-HackerLine "файл не найден: $File" -Color Red; return }
        $out = "$File.gpg"
        gpg --encrypt --armor --recipient $To --output $out $File
        Write-HackerLine "зашифровано → $out" -Color Green
    }
}

function pgp-decrypt {
    param(
        [switch]$Help,
        [Parameter(Mandatory)][string]$File
    )
    if (Test-ShowCommandHelp -Name 'pgp-decrypt' -Help:$Help) { return }
    Invoke-WorkstationCmd 'pgp-decrypt' {
        if (-not (Test-GpgAvailable)) { return }
        gpg --decrypt $File
    }
}

function pgp-help {
    param([switch]$Help)
    if (Test-ShowCommandHelp -Name 'pgp-help' -Help:$Help) { return }
    Invoke-WorkstationCmd 'pgp-help' {
        Write-HackerLine 'полная шпаргалка → sec-help  ·  меню → sec' -Color DarkGray
        if (Get-Command Show-SecurityHelpRu -ErrorAction SilentlyContinue) { Show-SecurityHelpRu }
        else { Show-PgpHelpRu }
    }
}
