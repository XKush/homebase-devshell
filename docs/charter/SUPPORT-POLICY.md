# HOME BASE — Support Policy

Политика поддержки **релизов** и **компонентов**. Дополняет [LIFECYCLE.md](./LIFECYCLE.md) (жизненный цикл команд).

---

## 1. Release support tiers

| Tier | Meaning | Security fixes | Bug fixes | New features |
|------|---------|----------------|-----------|--------------|
| **Supported** | Active line | ✅ | ✅ | ✅ (MINOR) |
| **Maintenance** | Previous MINOR | ✅ critical | ✅ critical | ❌ |
| **Deprecated** | Announced EOL | ✅ critical only | ❌ | ❌ |
| **End of Life (EOL)** | No support | ❌ | ❌ | ❌ |

### Current lines (2026-06-29)

| Version | Tier | Notes |
|---------|------|-------|
| **2.0.x** | **Supported** | OSS baseline, tag `v2.0.0` |
| < 2.0 | EOL | Pre-charter history |

**Rule:** only **latest MINOR** of current MAJOR is Supported. Previous MINOR → Maintenance for 6 months after next MINOR ship.

---

## 2. Component support classes

Параллельно с release tiers — классы **команд и подсистем**:

| Class | User expectation | Breaking changes |
|-------|------------------|------------------|
| **Supported** | Production daily use | ❌ |
| **Experimental** | Opt-in, may change | ⚠️ with warning |
| **Deprecated** | Works + warning | alias only |
| **Removed** | Error + migration hint | MAJOR only |

### Mapping (v2.0)

| Class | Examples |
|-------|----------|
| **Supported** | `home`, `go`, `revise`, `doctor`, `trustcheck`, `anon`, `backupconfig`, `cleanup`, `sec` |
| **Experimental** | `singularity`, `genesis`, `dna`, `trustchain` |
| **Deprecated** | `poriadok`, `jarvis`, `menu`, `palette`, `healthcheck`, `cleanlogs`, `privacy` |
| **Removed** | *(none until v3.0)* |

Полный реестр: [LIFECYCLE.md](./LIFECYCLE.md) §3.

---

## 3. Deprecation rules

```
Release N:     announce Deprecated + CHANGELOG + warning in command
Release N+1:   Deprecated + alias to replacement
Release N+2:   Removed (MAJOR bump only)
```

Minimum **2 minor releases** between deprecation announcement and removal.

---

## 4. Experimental promotion

Experimental → Stable requires:

- [ ] Documented in CHANGELOG
- [ ] SelfCheck + doctor coverage
- [ ] No known trust-breaking bugs
- [ ] LIFECYCLE.md updated

---

## 5. Security support

See [SECURITY.md](../../SECURITY.md).

| Severity | Supported line response |
|----------|-------------------------|
| Critical | patch within 30 days |
| High | patch or mitigation within 60 days |
| Medium/Low | next scheduled MINOR/PATCH |

EOL lines: no commits except documented fork.

---

## 6. Phase 2 rollback guarantee

Before Path Abstraction (Phase 2):

1. Read [MIGRATION.md](./MIGRATION.md) §7
2. `backupconfig` + note backup folder in CHANGELOG (product release only)
3. On failure: `git checkout v2.0.0` + `restoreconfig`

**v2.0.0** remains permanent product rollback anchor. **Docs/process commits do not receive tags.**

See [ARCHITECTURE-FREEZE.md](./ARCHITECTURE-FREEZE.md).

---

## 7. Related

- [LIFECYCLE.md](./LIFECYCLE.md)
- [VERSIONING.md](./VERSIONING.md)
- [RELEASE-CHECKLIST.md](./RELEASE-CHECKLIST.md)
- [ENVIRONMENT-MATRIX.md](./ENVIRONMENT-MATRIX.md)
