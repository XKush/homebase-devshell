# Максимальная защита Tor-сессии (HOME BASE)

## Быстрый старт

```powershell
pgp-repair          # если pgp-setup уже создал ключ
tor-setup           # Tor Browser
tor-harden          # user.js + правила
tor-check           # чеклист
tor-lock            # admin — блок clearnet-браузеров
# … работа только в Tor Browser …
tor-unlock          # admin — после сессии
```

## Уровни защиты

| Уровень | Что даёт |
|---------|----------|
| Tor Browser | Маршрут через Tor, .onion |
| PGP | Шифрование сообщений/файлов |
| tor-harden | WebRTC off, IPv6 DNS off, очистка сессии |
| tor-lock | Firewall блокирует Chrome/Edge/Firefox/brave outbound |
| Tails OS | Максимум (отдельная ОС с флешки) |

## Правила

1. **Не смешивай** личность и псевдоним (разные ключи PGP, разные ники).
2. **Fingerprint PGP** сверяй другим каналом — не в том же чате.
3. **Не открывай** вложения без проверки. Tor не защищает от вирусов.
4. **Kill switch** не блокирует PowerShell/winget — только основные браузеры. Закрой их перед `tor-lock`.
5. **Defender отключён** по твоей политике — следи за файлами вручную.

## Файлы

- `C:\Security\tor\tor-security.json` — состояние
- `C:\Security\tor\SESSION-RULES.txt` — краткие правила
- `C:\Security\pgp\` — PGP метаданные

## Связанные команды

- `pgp-help` — шифрование
- `trustcheck` — целостность HOME BASE
- `docs/ru/PGP-TOR-BASICS.md` — основы PGP
