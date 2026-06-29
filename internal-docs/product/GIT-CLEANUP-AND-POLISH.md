# Git Cleanup & Repository Polish — HomeBase DevShell

**Architecture lock:** v1.0.0 · **Scope:** cleanup & presentation only · **History rewrite:** NOT recommended

---

## 1. Repository cleanup plan

### Root clutter (58 tracked files at repo root)

| Category | Count | Action |
|----------|-------|--------|
| **Product entry (keep visible)** | 8 | README, README.ru, install, devshell, CHANGELOG, LICENSE, SECURITY, CONTRIBUTING |
| **Install chain (keep at root)** | 6 | Install-Workstation, Install-ShellProfile, Validate-Workstation, Backup-Configuration, Fix-WorkstationPath, Configure-GitIdentity |
| **Admin/full install (keep at root)** | 8 | Install-Software, Optimize-Performance, Configure-Privacy, Harden-Security, Configure-Network, Configure-TorSecurity, etc. |
| **Maintainer / CI (move Phase 2)** | ~30 | Invoke-*, Save-*, Test-* (except hardening), Sync-*, Generate-* |
| **Repair / optional toolkits** | 6 | Repair-*, Rollback-*, Install-*Toolkit |

**Why not move now:** all scripts use `$PSScriptRoot\*.ps1`. Moving without root shims **breaks install** → violates no-behavior-change rule.

**Phase 2 (future):** `scripts/maintainer/`, `scripts/admin/`, `scripts/install/` + one-line root stubs.

### Files to move (docs only — DONE)

| From | To | Status |
|------|-----|--------|
| `docs/charter/` | `internal-docs/charter/` | ✅ |
| `docs/baselines/` | `internal-docs/baselines/` | ✅ |
| `docs/product/` | `internal-docs/product/` | ✅ |
| Archive reports | `internal-docs/archive/` | ✅ |

### Duplicated / outdated documentation

| Doc | Issue | Action |
|-----|-------|--------|
| `REPOSITORY-CLEANUP-PLAN.md` | Overlaps this file | Keep both; this file is authoritative for git polish |
| `PUBLIC-REPO-STRUCTURE.md` | Superseded tree | Keep as short pointer |
| `OSS-ADOPTION-GUIDE.md` | Growth messaging | Maintainer-only |
| `VIRAL-README-OPTIMIZATION.md` | README SEO | Maintainer-only |
| `docs/ru/README.md` | Command reference, not product | Linked from README.ru footer only |

### Remove from user-facing surface (not delete)

- All `Invoke-Phase2*` naming on GitHub landing → index in `scripts/README.md`
- Baseline JSON → `internal-docs/baselines/` only
- Charter ADRs → never link from README

---

## 2. Git history hygiene (SAFE ONLY)

### Do NOT rewrite `main`

Force-push / rebase public history risks broken clones and lost stars context.

### Commit message strategy (forward-only)

| Prefix | Use |
|--------|-----|
| `docs:` | README, user docs, internal-docs |
| `chore:` | .gitignore, .github templates, untrack artifacts |
| `release:` | tags only |
| `feat/fix/refactor` | runtime (frozen — avoid on lock) |

### Logical groups in current history (readability)

| Range | Theme | Public narrative |
|-------|-------|------------------|
| `84f35e2`…`8972054` | Phase 2 / path migration | Pre-DevShell engineering — ignore on landing |
| `28ed544`…`4615d98` | Wave orchestration | Platform lock — internal only |
| `c520d40` | v2.0.0 release | First public product |
| `f9cdc67`…`dbf7535` | OSS growth + UX | Current user-facing story |

**Noisy commits for contributors:** orchestration `feat` commits on `main` are fine historically; optional **Release Notes** section in CHANGELOG groups user-visible changes only.

### Optional (only if explicitly requested later)

- Squash OSS doc commits (`b9b2b46`…`dbf7535`) into one `docs: public OSS packaging` — **not recommended** after push.

---

## 3. Repository structure polish (FINAL)

```
homebase-devshell/
│
├── ★ README.md · README.ru.md
├── ★ install.ps1 · devshell.ps1
├── ★ CHANGELOG.md · LICENSE · SECURITY.md · CONTRIBUTING.md
│
├── docs/                         ★ user-facing only
│   ├── README.md
│   ├── GETTING-STARTED.md
│   ├── TROUBLESHOOTING.md
│   └── ru/                       command reference (advanced)
│
├── internal-docs/                maintainer / platform
│   ├── README.md
│   ├── charter/ · baselines/ · product/ · archive/
│
├── scripts/
│   └── README.md                 ★ index of root scripts (no moves yet)
│
├── .github/                      issue + PR templates
│
├── profile/ · lib/ · modules/ · terminal/ · Config/
│
└── [install + maintainer *.ps1 at root]   Phase 2 → scripts/
```

**★ = what first-time visitors should see**

---

## 4. Documentation organization

| Layer | Path | Linked from README? |
|-------|------|---------------------|
| Product | `README.md`, `README.ru.md` | Yes (hero) |
| User support | `docs/GETTING-STARTED`, `docs/TROUBLESHOOTING` | Footer only |
| Contributor | `CONTRIBUTING.md` | Footer |
| Security | `SECURITY.md` | Standard GitHub |
| Russian commands | `docs/ru/*` | README.ru footer |
| Platform / release | `internal-docs/**` | **Never** in README hero |
| Script index | `scripts/README.md` | CONTRIBUTING only |

---

## 5. GitHub appearance optimization

### Applied / recommended

| Item | Status |
|------|--------|
| English-first README | ✅ |
| Minimal root narrative (8 files) | ✅ (scripts still visible in tree — indexed) |
| `internal-docs/` off landing path | ✅ |
| Issue templates | ✅ `.github/ISSUE_TEMPLATE/` |
| PR template | ✅ `.github/pull_request_template.md` |
| Untrack `terminal/active-theme.omp.json` | ✅ local override |
| Repo description + 20 topics | ✅ |

### File naming clarity

| Keep | Avoid renaming (breaks paths) |
|------|----------------------------------|
| `install.ps1`, `devshell.ps1` lowercase | Install-Workstation.ps1 PascalCase (install chain) |
| `README.ru.md` convention | Do not rename to `docs/ru/README-product.md` |

### Reduce visual noise on GitHub

1. Do **not** add more root markdown files  
2. Put new maintainer notes under `internal-docs/product/`  
3. Link script catalog from `CONTRIBUTING.md`, not README  
4. Pin **Release v2.0.0**, not internal docs  

---

## 6. `.gitignore` review

### Covered

- `*.log`, validation/hardening JSON, `*.tmp`, WIP menu tests  
- `.env`, secrets, `.vscode/`  
- `terminal/active-theme.omp.json` (local theme)  

### Added in this pass

- `audit-*.json`, `*.bak`, `.cursor/`  
- `**/reports/*.json` (generated audit copies if synced into repo)

### Pre-commit check

```powershell
git status
git ls-files | Select-String 'validation-|\.tmp$|active-theme'
```

---

## Files to move / remove / keep (summary)

| Action | Items |
|--------|--------|
| **Keep at root** | Product 8 + install chain + all `.ps1` until Phase 2 shims |
| **Moved (done)** | Internal markdown → `internal-docs/` |
| **Untrack (done)** | `terminal/active-theme.omp.json` |
| **Ignore (local WIP)** | Menu WIP, Tor module edits, `Shell.ps1.tmp` |
| **Do not delete** | Maintainer scripts — still used by operators |
| **Phase 2 move** | `Invoke-*`, `Save-*`, most `Test-*` → `scripts/` |

---

## Optional commit grouping (SAFE — forward only)

If polishing continues, batch as:

1. `chore: gitignore and untrack local theme override`  
2. `chore: add GitHub issue/PR templates`  
3. `docs: repository polish plan and scripts index`  

Do **not** squash already-pushed OSS commits without maintainer sign-off.

---

**Runtime / CLI / architecture:** unchanged by this polish pass.
