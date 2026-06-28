# HOME BASE — Component Lifecycle

Жизненный цикл команд и компонентов.

---

## 1. States

```
Draft → Experimental → Stable → Recommended → Deprecated → Removed
```

| State | User visibility | Breaking allowed? |
|-------|-----------------|-------------------|
| Draft | hidden | yes (internal) |
| Experimental | opt-in, docs marked | yes with warning |
| Stable | menu + help | no |
| Recommended | `[следующий]` home | no |
| Deprecated | works + warning | alias only next |
| Removed | alias/error message | MAJOR version |

---

## 2. Registry fields (target)

```powershell
@{
    Name         = 'example'
    Backend      = 'example'
    Module       = 'Maintenance'
    Safe         = 'example -WhatIf'
    Lifecycle    = 'Stable'              # new
    Replacement  = $null                 # if Deprecated
    DeprecatedIn = '2.1.0'              # optional
    RemovedIn    = '3.0.0'              # optional
}
```

---

## 3. Current classification

### Recommended (core loop)

`home`, `go`, `devstart`, `revise`, `doctor`, `trustcheck`, `anon`, `backupconfig`, `cleanup`, `repairterminal`, `sec`

### Stable

`organize`, `updateall`, `nettools`, `toolcheck`, `workspace`, `logs`, `komandy`, `pgp-*`, `tor-*`

### Experimental

`singularity`, `genesis`, `dna`, `trustchain`

### Deprecated (keep alias)

| Command | Replacement | Remove |
|---------|-------------|--------|
| `poriadok` | `revise` | v3.0 |
| `healthcheck` | `doctor` | v3.0 |
| `jarvis`, `dashboard`, `hack` | `home` | v3.0 |
| `menu`, `palette`, `nav` | `go` | v3.0 |
| `privacy` | `sec` | v3.0 |
| `cleanlogs` | `cleanup` | v3.0 |
| `explain` | `имя -help` | v3.0 |

### Hidden (registry, not menu)

`healthcheck`, `home`, `logs-dir`, `cleanlogs`, `explain`, `quickstart`, `cheatsheet`

---

## 4. Deprecation UX

```powershell
Write-Warning "Команда 'poriadok' устарела. Используйте: revise"
```

Once per session per command (target).

---

## 5. Removal process

1. LIFECYCLE.md update
2. CHANGELOG **Deprecated** section (minor)
3. Warning in command (minor)
4. CHANGELOG **Removed** + MAJOR bump
5. Stub function:

```powershell
function removed-cmd {
    throw "Команда удалена в v3.0. Используйте: revise"
}
```

---

## 6. Related

- [VERSIONING.md](./VERSIONING.md)
- [ROADMAP.md](./ROADMAP.md)
