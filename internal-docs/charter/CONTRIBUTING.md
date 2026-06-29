# Contributing to HOME BASE

Спасибо за интерес к проекту. HOME BASE — персональная платформа; contributions должны сохранять **trust**, **backup discipline** и **backward compatibility**.

---

## 1. Before you start

1. Read [PHILOSOPHY.md](./PHILOSOPHY.md)
2. Read [CODING-STANDARD.md](./CODING-STANDARD.md)
3. Read [SECURITY-POLICY.md](./SECURITY-POLICY.md)
4. Run `doctor` + `trustcheck` on your machine

---

## 2. Issues

| Type | Template |
|------|----------|
| Bug | steps, expected, actual, `validation-*.json` |
| Feature | use case, non-breaking proposal |
| Security | **private** disclosure first — see SECURITY-POLICY |

Label: `bug`, `enhancement`, `docs`, `security`.

---

## 3. Pull Request process

```
1. Fork / branch from main
2. Change scope minimal (one concern per PR)
3. doctor PASS
4. trustcheck VERIFIED (or explain STALE)
5. Update CHANGELOG [Unreleased]
6. Update charter doc if policy touched
7. PR description: What / Why / Test plan
```

---

## 4. Code review criteria

- [ ] COMMAND-STANDARD compliance
- [ ] No destructive op without SECURITY-POLICY chain
- [ ] RU strings in locale (or documented exception)
- [ ] No new hardcoded paths
- [ ] Import-Module uses Ensure / Global scope
- [ ] No removed commands without LIFECYCLE

---

## 5. Style

Follow [CODING-STANDARD.md](./CODING-STANDARD.md) and [UI-STYLE-GUIDE.md](./UI-STYLE-GUIDE.md).

---

## 6. Tests

Minimum for code PR:

```powershell
doctor
Test-MenuAudit.ps1          # if menu touched
Test-WorkstationCommands.ps1 -Quick   # if commands touched
revise -Quick               # if orchestration touched
```

See [TESTING-STANDARD.md](./TESTING-STANDARD.md).

---

## 7. Documentation

- User-facing RU → `docs/ru/` or locale
- Policy → `docs/charter/`
- Auto-synced commands → update Help catalog (Sync-WorkstationDocs)

---

## 8. Commit convention

```
type(scope): subject

body (optional)

footer: BREAKING CHANGE: … (only with migration doc)
```

| type | usage |
|------|-------|
| feat | new command |
| fix | bugfix |
| docs | documentation |
| refactor | no behavior change |
| test | tests only |
| chore | maintenance |

Examples:

```
feat(anon): add tor-check to kit audit deps
fix(cleanup): archive backups instead of delete
docs(charter): add BACKUP-POLICY
```

---

## 9. License

By contributing, you agree your contributions will be licensed under the project LICENSE (see LICENSE-RECOMMENDATION.md — target MIT).

---

## 10. Code of conduct

Be respectful. No harassment. Security issues reported responsibly.

---

## Related

- [EXECUTION-PLAN.md](./EXECUTION-PLAN.md)
- [LIFECYCLE.md](./LIFECYCLE.md)
