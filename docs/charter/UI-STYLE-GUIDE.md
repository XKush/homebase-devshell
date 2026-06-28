# HOME BASE — UI Style Guide

Официальный стандарт визуального вывода. **Target state** — Phase 4; current state documented for migration.

---

## 1. Canonical panel format

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 HOME BASE · {command}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Статус
  {key}    {value}

Итог
  {one sentence}

Следующие действия
  01  {action}
  02  {action}

Подсказки
  >> {hint}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Rules

| Rule | Value |
|------|-------|
| Border char | `U+2501` `━` × 40 |
| Title | `HOME BASE · {command}` — command name **не переводится** |
| Section headers | `Статус`, `Итог`, `Следующие действия`, `Подсказки` |
| Hint prefix | `>> ` (DarkGray) |
| Action numbering | `01`, `02`, … (two digits) |

---

## 2. Current stacks (migration map)

| Stack | Used by | Migrate to |
|-------|---------|------------|
| `==> Step` | doctor, revise, root scripts | Panel sections |
| `[HOME BASE]` HackerUI | home, go, anon | Panel (keep palette) |
| `════ VALIDATION ════` | Validate-Workstation | Panel + RU labels |
| Plain Write-Host | cleanup, misc | Panel |

**Implementation target:** `Show-HomeBasePanel -Kind <Dashboard|Revision|Trust|…>`

---

## 3. Colors

| Semantic | Foreground | When |
|----------|------------|------|
| OK / VERIFIED / PASS | `Green` | success |
| WARN / STALE / DEGRADED | `Yellow` | attention |
| ERROR / UNTRUSTED / FAIL | `Red` | failure |
| Section title | `Cyan` | headers |
| Body | `White` | normal text |
| Hint / muted | `DarkGray` | hints, paths |
| Matrix accent | palette from `Get-HackerPalette` | hacker mode only |

**Не использовать:** random colors per command.

---

## 4. Status tokens

| Token | Meaning | Translate? |
|-------|---------|------------|
| `VERIFIED` | Trust 100%, no blockers | No |
| `STALE` | Cache aged, non-critical | No |
| `UNTRUSTED` | Broken selfcheck/module | No |
| `READY` | SHADOW OPS | No |
| `PASS` | Doctor check | No (log); RU in UI: «пройдено» |
| `NOMINAL` | Health ≥90% | No |

---

## 5. Errors

Format via `Translate-WorkstationError`:

```
Ошибка: {RU message}
Причина: {detail}
Решение: {hint commands}
```

Footer hint (standard):

```
>> doctor · trustcheck · repairterminal
```

---

## 6. Warnings

```
!! {title} · {detail}
```

Yellow. Never hide warnings when `CanTrustDashboard = false`.

---

## 7. Banners

### home (compact)

```
[HOME BASE] {user}@{host} · health {n}% · trust {n}% {LEVEL}
disk C: {pct}% · {gb} GB free · {ip}
```

### SEC block

```
[SEC] READY {n}%  Tor: OK  PGP: {uid}
```

---

## 8. Tables

Prefer aligned key-value (`Write-HackerStat`) over `Format-Table` in user UI.

Logs / audit reports: `Format-Table` allowed.

---

## 9. Progress / steps

Long operations (doctor, revise):

```
==> {Step title}          ← transitional; migrate to panel sub-section
[2026-06-29 00:52:48] [OK] {message}
```

Timestamp logs: **DarkGray/Green/Yellow/Red** per LOGGING-STANDARD.

---

## 10. fzf / menu

- Nav bar: `go (Ctrl+Alt+G) — [anon] + [следующий] + категории | anon (Ctrl+Alt+S) | home`
- Footer after action: `>> {command} -help · go · Ctrl+Alt+G`
- pwd line: `pwd: {path} | trust: {n}% {LEVEL} | sec: {status}`

---

## 11. Do / Don't

| Do | Don't |
|----|-------|
| Use panel sections | Mix `═══` and `━━━` in same flow |
| RU section headers | English «Status:» in user UI |
| Consistent hint prefix | Random emoji overload |
| `honestScore` in home | Show 100% trust when health 88% without note |

---

## 12. Related

- [LANGUAGE-POLICY.md](./LANGUAGE-POLICY.md)
- [adr/ADR-0003-presentation-layer.md](./adr/ADR-0003-presentation-layer.md)
