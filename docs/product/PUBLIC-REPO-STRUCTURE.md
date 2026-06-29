# Public Repository Structure — HomeBase DevShell

What users see vs what is maintainer/internal reference.

---

## Public tree (v2.0.0)

```
homebase-devshell/
├── README.md                 ★ First thing users read
├── CHANGELOG.md              ★ Release history
├── LICENSE
├── install.ps1               ★ Bootstrap
├── devshell.ps1              ★ Product CLI
├── SECURITY.md               (recommended — vulnerability reporting)
│
├── profile/                  Runtime: deployed to $PROFILE
├── lib/                      Runtime: locked platform (Wave A–D)
├── modules/                  Runtime: KGreen.Workstation
├── terminal/                 Themes / WT templates
│
├── docs/
│   ├── quickstart.md         User onboarding (optional)
│   ├── platform-spec-summary.md   1-page spec overview
│   ├── charter/              Advanced / contributor reference
│   │   ├── PLATFORM-SPEC-SIGNOFF.md
│   │   ├── EXTENSION-GUIDELINES.md
│   │   └── ARCHITECTURE-LOCK.md
│   ├── product/              Release & packaging notes
│   └── ru/                   Localized docs (optional)
│
├── examples/
│   └── extension-hello/      Minimal Wave D sample (optional)
│
├── Install-*.ps1             Called by install / doctor
├── Validate-Workstation.ps1
├── Test-WorkstationPlatformHardening.ps1
│
└── .github/
    └── workflows/ci.yml      Hardening on PR + tag
```

★ = primary user entry points

---

## Visibility matrix

| Path | User-visible | Purpose |
|------|--------------|---------|
| `README.md` | Yes | Product story + install |
| `install.ps1` / `devshell.ps1` | Yes | Product CLI |
| `profile/` `lib/` `modules/` | Shipped, documented lightly | Runtime |
| `docs/charter/PLATFORM-SPEC-*` | Advanced | Transparency / contributors |
| `docs/charter/PATH-MIGRATION-*` | Internal tone | Phase 2 operators — not in README links |
| `docs/baselines/` | Maintainer | Regression snapshots |
| `Invoke-Phase2CommitGate.ps1` | Maintainer | Release engineering |
| `docs/product/` | Maintainer / release | Packaging plans |
| `tools/` `_test-*` | Dev only | Exclude from release notes |

---

## Recommended `.gitignore` (public)

```
*.log
validation-*.json
platform-hardening-*.json
.env
*.tmp
modules/Shell.ps1.tmp
```

---

## Dual-repo strategy (optional)

| Repo | Contents |
|------|----------|
| **homebase-devshell** (public) | Product + runtime as shipped today |
| **homebase-internal** (private) | Phase 2 migration, charter WIP, gate artifacts |

Single-repo is fine for v2.0.0 if internal docs stay out of README navigation.

---

## What users should **not** need to open

- `lib/WorkstationOrchestrator.ps1` — unless contributing to locked platform
- `Invoke-Phase2CommitGate.ps1`
- Full `docs/charter/*` pack (50+ policy files)

Point curious developers to `docs/platform-spec-summary.md` only.
