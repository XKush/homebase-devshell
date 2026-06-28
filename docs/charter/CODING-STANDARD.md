# HOME BASE — Coding Standard

Обязательный стандарт для всех изменений в репозитории HOME BASE.

---

## 1. Общие правила

- PowerShell **7.0+** (`#Requires -Version 7.0` для root scripts)
- `$ErrorActionPreference = 'Continue'` в orchestration; `'Stop'` только где явно нужно
- **Не** использовать `Write-Host` в новых командах — только Presentation Layer
- **Не** вызывать `Import-Module -Force` без `-Scope Global` или `Ensure-WorkstationModuleLoaded`
- **Не** hardcode paths — использовать `$script:WSRoot` / future `Get-HomeBasePath`

---

## 2. Именование

### 2.1. User commands (exported)

| Стиль | Пример |
|-------|--------|
| lowercase single word | `home`, `go`, `doctor` |
| kebab-case multi | `pgp-status`, `tor-check` |
| **Запрещено** | `Get-Home`, `Invoke-Go` для user-facing |

### 2.2. Internal functions

Approved PowerShell verbs: `Get-`, `Set-`, `Invoke-`, `Show-`, `Test-`, `Save-`, `Register-`, …

### 2.3. Files

| Тип | Pattern | Пример |
|-----|---------|--------|
| Module component | `PascalCase.ps1` | `TrustSystem.ps1` |
| Root orchestration | `Verb-Noun.ps1` | `Validate-Workstation.ps1` |
| Test | `Test-<Area>.ps1` | `Test-MenuAudit.ps1` |
| Locale | `Domain.ru.ps1` | `Trust.ru.ps1` |
| Config | `kebab-case.json` | `homebase.defaults.json` |

### 2.4. Variables

| Scope | Convention |
|-------|------------|
| Module script | `$script:VariableName` |
| Function local | `$camelCase` |
| Constants | `$script:ConstantName` в PascalCase |

---

## 3. Структура каталогов (current → target)

**Current (v2.0):**

```
Workstation/
├── *.ps1 (50 root — debt)
├── modules/KGreen.Workstation.psm1
├── lib/
├── profile/
├── terminal/
└── docs/
```

**Target (v2.2):** см. [ARCHITECTURE.md](./ARCHITECTURE.md) §8

---

## 4. Структура user command

```powershell
function example {
    param(
        [switch]$Help,
        [switch]$WhatIf,      # if mutates
        [switch]$Verbose
    )
    if (Test-ShowCommandHelp -Name 'example' -Help:$Help) { return }

    Invoke-WorkstationCmd 'example' {
        # implementation
        # return [PSCustomObject] if applicable
    }
}
```

**Обязательно:** entry in `Get-WorkstationCommandRegistry` + `Get-WorkstationHelpCatalog`.

---

## 5. Comment-based help

Каждая **exported** function:

```powershell
<#
.SYNOPSIS
    Краткое назначение (RU).
.DESCRIPTION
    Когда использовать, side effects.
.PARAMETER Help
    Показать справку.
.OUTPUTS
    [PSCustomObject] или None.
.EXAMPLE
    example -WhatIf
    Описание примера.
.NOTES
    Зависимости, admin requirement.
#>
```

Priority tier-1: `home`, `go`, `revise`, `doctor`, `trustcheck`, `anon`, `backupconfig`, `cleanup`, `restoreconfig`.

---

## 6. Обработка ошибок

- User commands: через `Invoke-WorkstationCmd` → `Translate-WorkstationError`
- Scripts: `Write-WorkstationLog` + non-zero exit / `$global:LASTEXITCODE`
- **Не** глотать ошибки без log
- SelfCheck / trust: try/catch per command, не fail entire probe

---

## 7. Логирование

| Layer | Function | File |
|-------|----------|------|
| Commands | `Write-CommandLog` | `commands.log` |
| Scripts | `Write-WorkstationLog` | `workstation.log` |
| Steps | `Write-WorkstationStep` | workstation.log + console |

См. [LOGGING-STANDARD.md](./LOGGING-STANDARD.md)

---

## 8. Export

- Только через `$public` array в `KGreen.Workstation.psm1`
- Private helpers — **не** export
- Новый export = update Sync-WorkstationDocs drift check

---

## 9. Aliases

| Rule | Detail |
|------|--------|
| User aliases | через registry `Backend`, не `Set-Alias` scattered |
| Profile aliases | **запрещены** для commands in registry (DRY → Shell.ps1) |
| Deprecated | alias + `Write-Warning` once per session |

---

## 10. Code review checklist

- [ ] Follows COMMAND-STANDARD
- [ ] RU strings in locale, not inline (target)
- [ ] No destructive op without SECURITY-POLICY compliance
- [ ] doctor + trust pass
- [ ] CHANGELOG entry
- [ ] Lifecycle status updated if deprecating

---

## 11. Связанные документы

- [COMMAND-STANDARD.md](./COMMAND-STANDARD.md)
- [LANGUAGE-POLICY.md](./LANGUAGE-POLICY.md)
- [CONTRIBUTING.md](./CONTRIBUTING.md)
