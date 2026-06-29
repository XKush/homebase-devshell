# HOME BASE — Command Standard

Каждая user-facing команда HOME BASE обязана соответствовать этому стандарту.

---

## 1. Mandatory checklist

| # | Requirement | Implementation |
|---|-------------|----------------|
| 1 | **Help** | `[switch]$Help` + `Test-ShowCommandHelp` + catalog entry |
| 2 | **Verbose** | `[switch]$Verbose` + `Write-Verbose` (target) |
| 3 | **WhatIf** | Required if mutates FS/registry/config |
| 4 | **Output object** | Return `[PSCustomObject]` or pipeline-friendly |
| 5 | **Logging** | `Invoke-WorkstationCmd` → `Write-CommandLog` |
| 6 | **Localization** | RU via locale / Help.ru.ps1 |
| 7 | **Audit** | Registry + SelfCheck deps + safe exec matrix |
| 8 | **Error handling** | `Translate-WorkstationError` |
| 9 | **Examples** | comment-based help `.EXAMPLE` |

---

## 2. Registry entry

```powershell
@{
    Name   = 'example'
    Backend = 'example'           # or function name if different
    Module  = 'Maintenance'       # logical group
    Safe    = 'example -WhatIf'   # for Test-WorkstationCommands; $null if interactive-only
}
```

---

## 3. SelfCheck dependencies

```powershell
$script:SelfCheckDeps = @{
    example = @('Some-Dependency.ps1', 'Some-Function')
}
```

File deps: path relative to `$script:WSRoot`.

---

## 4. Invoke-WorkstationCmd wrapper

```powershell
function example {
    param([switch]$Help, [switch]$WhatIf)
    if (Test-ShowCommandHelp -Name 'example' -Help:$Help) { return }
    Invoke-WorkstationCmd 'example' {
        # body
    }
}
```

Skip selfcheck only when documented: `-SkipSelfCheck` (internal).

---

## 5. WhatIf contract

Mutating commands **must**:

1. Support `-WhatIf`
2. Print `Будет …` / `Будет архивирован …` — never silent
3. Perform zero mutations when `$WhatIf`

Examples: `cleanup`, `organize`, `Invoke-Housekeeping.ps1`.

---

## 6. Output object schema (recommended)

```powershell
[PSCustomObject]@{
    Command   = 'example'
    Success   = $true
    Timestamp = (Get-Date).ToString('o')
    Details   = @{ ... }
}
```

---

## 7. Interactive-only commands

If no safe exec (`Safe = $null`):

- Registry must note: admin/interactive only
- SelfCheck: existence + help param only
- Examples: `restoreconfig`, `pgp-setup`, `repairterminal`

---

## 8. Menu integration

| Visibility | Rule |
|------------|------|
| Recommended | appears in `[следующий]` or category |
| Hidden | registry only, removed from menu dedupe skip list |
| Deprecated | menu hidden, command works + warning |

---

## 9. Compliance matrix (top commands)

| Command | Help | WhatIf | Log | Locale | Audit |
|---------|------|--------|-----|--------|-------|
| home | ✅ | n/a | ✅ | ✅ | ✅ |
| go | ✅ | n/a | ✅ | ✅ | ✅ |
| doctor | ✅ | n/a | ✅ | ⚠️ EN | ✅ |
| revise | ✅ | n/a | ✅ | ✅ | ✅ |
| trustcheck | ✅ | n/a | ✅ | ✅ | ✅ |
| anon | ✅ | n/a | ✅ | ✅ | ✅ |
| backupconfig | ✅ | n/a | ✅ | ✅ | ✅ |
| cleanup | ✅ | ✅ | ✅ | ✅ | ✅ |
| organize | ✅ | ✅ | ✅ | ✅ | ✅ |
| restoreconfig | ✅ | n/a | ✅ | ✅ | ✅ |

---

## 10. Related

- [CODING-STANDARD.md](./CODING-STANDARD.md)
- [LIFECYCLE.md](./LIFECYCLE.md)
- [TESTING-STANDARD.md](./TESTING-STANDARD.md)
