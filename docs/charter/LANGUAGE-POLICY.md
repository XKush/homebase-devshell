# HOME BASE — Language Policy

Политика локализации. **RU-first**, EN-secondary.

---

## 1. Принцип

| Layer | Language |
|-------|----------|
| User-facing UI | **Русский** |
| Log files (grep) | English levels: OK, WARN, ERROR |
| JSON keys | English |
| Code identifiers | English |
| Documentation charter | Russian (this pack) + EN mirror (future) |

---

## 2. Переводится

- Меню `go`, категории, hints
- Help catalog (`Help.ru.ps1`, `-help` output)
- Ошибки (`Errors.ru.ps1`, `Translate-WorkstationError`)
- Предупреждения, подсказки `>>`
- Banner sections: `[Следующий шаг]`, `[SEC]`, panel headers
- Doctor **UI labels** (target: «пройдено» вместо «PASS» в console)
- Trust panel user text
- Success toasts: «Профиль перезагружен», «Очистка завершена»
- Onboarding, recommendations

---

## 3. Не переводится

| Category | Examples |
|----------|----------|
| Command names | `home`, `go`, `revise`, `doctor`, `anon` |
| Function names | `Get-SystemTrustReport` |
| Parameters | `-Help`, `-WhatIf`, `-Verbose` |
| PowerShell / Windows API | `Import-Module`, `Get-Item` |
| Paths | `C:\Logs\Workstation` |
| JSON keys | `PassCount`, `FailCount`, `Metrics` |
| File names | `validation-*.json` |
| Status tokens (display) | `VERIFIED`, `READY`, `STALE` |
| Git / tool output | `git version`, winget |

---

## 4. Структура locale

**Current:**

```
modules/locale/ru/
  Dashboard.ru.ps1
  Genesis.ru.ps1
  Hacker.ru.ps1
  Hints.ru.ps1
  Trust.ru.ps1
modules/Private/
  Help.ru.ps1
  Errors.ru.ps1
```

**Target (v2.3):**

```
Modules/HomeBase/Locale/ru-RU/
  Commands.ru.ps1
  Errors.ru.ps1
  Panels.ru.ps1
  Validation.ru.ps1
  Messages.ru.ps1
```

**API target:**

```powershell
Get-HomeBaseString -Key 'Trust.Verified' -Fallback 'VERIFIED'
```

---

## 5. Правила новых строк

1. **Запрещено** добавлять RU inline в Private/*.ps1 (except locale files)
2. Key naming: `{Domain}.{Context}.{Name}` — e.g. `Menu.Go.Footer`
3. Pluralization: separate keys, not string concat magic
4. Parameters in strings: `{0}` format — `-f` substitution
5. New command = new Help.ru.ps1 entry + locale keys

---

## 6. Fallback

```
1. ru-RU key
2. ru key (legacy)
3. en-US key (future)
4. Fallback parameter
5. Key name (dev warning)
```

`$env:WORKSTATION_LANG` = `ru` | `en` (future)

---

## 7. Mixed-language cleanup backlog

| Location | Issue | Priority |
|----------|-------|----------|
| Validate-Workstation | `PASS:`/`FAILED:` headers | HIGH |
| Root README.md | English | HIGH |
| Trust Show-TrustReport | `Live-probe`, `OK` | MEDIUM |
| WOC | HEALTHY/DEGRADED labels | MEDIUM |
| Singularity/Genesis | metaphor glossary | LOW |

---

## 8. Sync workflow

```
Get-WorkstationHelpCatalog
    → Sync-WorkstationDocs.ps1
    → docs/ru/COMMANDS.md, QUICKREF.md
```

Charter docs **не** auto-sync — manual review.

---

## 9. Related

- [UI-STYLE-GUIDE.md](./UI-STYLE-GUIDE.md)
- [adr/ADR-0006-localization.md](./adr/ADR-0006-localization.md)
