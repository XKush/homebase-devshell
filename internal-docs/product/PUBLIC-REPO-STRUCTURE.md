# Public Repository Structure — HomeBase DevShell

**Superseded layout:** see [REPOSITORY-CLEANUP-PLAN.md](REPOSITORY-CLEANUP-PLAN.md) for the current final tree.

---

## Public tree (adoption stage)

```
homebase-devshell/
├── README.md              ★
├── install.ps1            ★
├── devshell.ps1           ★
├── CHANGELOG.md
├── LICENSE
├── SECURITY.md
├── CONTRIBUTING.md
│
├── docs/                  ★ user-facing
│   ├── GETTING-STARTED.md
│   ├── TROUBLESHOOTING.md
│   └── ru/
│
├── internal-docs/         maintainer (not in README hero)
├── profile/ lib/ modules/ terminal/ Config/
└── Install-*.ps1 Validate-Workstation.ps1  (install chain)
```

★ = first impression surface

---

## Visibility matrix

| Path | First-user visible | Notes |
|------|-------------------|-------|
| Root 5 + SECURITY + CONTRIBUTING | Yes | Minimal entry |
| `docs/` | Yes | Onboarding + troubleshooting only |
| `internal-docs/` | No | Charter, baselines, release plans |
| `profile/` `lib/` `modules/` | Shipped | Not explained in README |
| Root `Invoke-*` scripts | No | Phase 2 → `scripts/` |
