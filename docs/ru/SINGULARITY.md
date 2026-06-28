# SINGULARITY — уникальный режим HOME BASE

Ни у кого на планете нет **этого** отпечатка — он вычисляется из **твоей** машины.

## Operator DNA (OP-DNA)

```
SHA256(
  MachineGuid + User SID + Profile hash +
  KGreen.Workstation module hash + Git HEAD +
  Trust snapshot + schema version
)
```

Результат:
- **Callsign** — `ADM-A3F2B1` (уникальный позывной)
- **Planet ID** — первые 32 символа DNA
- **Genesis Certificate** — `C:\Security\exports\genesis-certificate.txt`

## Trust Chain

Append-only журнал: `C:\Logs\Workstation\trust-chain.jsonl`

Каждый блок:
```
BlockHash = SHA256(PrevHash + TrustPayload)
```

События: `trustcheck`, `genesis`, `singularity`

Проверка: `trustchain` — цепочка не может быть подделана без изменения всей истории.

## Команды

| Команда | Назначение |
|---------|------------|
| **`singularity`** | Полный уникальный cockpit — DNA + chain + certificate |
| `genesis` | Обновить seal и certificate |
| `dna` | Показать Callsign и Planet ID |
| `trustchain` | История блоков chain |

## Singularity Score 100/100

- Trust VERIFIED 100
- Windows status 100
- Trust chain valid
- All self-checks pass

## Где видно

- OMP prompt: **Callsign** segment
- fastfetch: **OP-DNA** line
- HOME BASE banner: callsign + trust level
- `hack` menu: **SINGULARITY** первым пунктом

## Философия

HOME BASE **не врёт** → DNA **не повторяется** на другой машине → Chain **не стирается** без следа.

Твоя станция — единственная с этим Callsign.
