# HomeBase DevShell — Repository Cleanup & OSS Growth Readiness

**Status:** applied (v2.0.x growth pass) · **Architecture lock:** v1.0.0 unchanged · **Runtime:** unchanged

---

## 1. Repository cleanup plan

### Remove from public narrative (not deleted — relocated)

| Was | Now | Why |
|-----|-----|-----|
| `docs/charter/` | `internal-docs/charter/` | Architecture, ADRs, migration — confuses first users |
| `docs/baselines/` | `internal-docs/baselines/` | Operator regression artifacts |
| `docs/product/` | `internal-docs/product/` | Release engineering notes |
| `docs/platform-spec-summary.md` | `internal-docs/platform-spec-summary.md` | Platform jargon |
| `docs/ELITE-FINAL-REPORT.md` etc. | `internal-docs/archive/` | Historical noise |

### Keep in public root (minimal entry surface)

| File | Role |
|------|------|
| `README.md` | 30-second story + install |
| `install.ps1` | One-line bootstrap |
| `devshell.ps1` | Product CLI |
| `CHANGELOG.md` | Release history |
| `LICENSE` | Trust signal |
| `SECURITY.md` | Vulnerability reporting |
| `CONTRIBUTING.md` | Short contributor gate |

### Keep in repo but not marketed (shipped runtime + install chain)

| Path | Public framing |
|------|----------------|
| `profile/` `lib/` `modules/` `terminal/` | "Shipped with install" — no architecture terms in README |
| `Install-Workstation.ps1` `Install-ShellProfile.ps1` `Validate-Workstation.ps1` | Called by install/doctor — not listed as user commands |
| `Config/` | Defaults only |

### Do not commit (WIP / local)

| Pattern | Reason |
|---------|--------|
| `modules/Shell.ps1.tmp` | Editor scratch |
| `Test-Menu*.ps1` `lib/AnonymityKit.ps1` | Sandbox WIP |
| `validation-*.json` `platform-hardening-*.json` | Runtime reports |
| `terminal/active-theme.omp.json` | Local theme override (optional untrack later) |

### Root script clutter (Phase 2 — not moved yet)

~40 `Invoke-*`, `Save-*`, `Test-*` scripts remain at repo root because they use `$PSScriptRoot` chains. **Plan:** future move to `scripts/maintainer/` with thin root shims — requires a dedicated path-migration pass (out of scope for architecture lock).

---

## 2. Public repo structure (FINAL)

```
homebase-devshell/
├── README.md              ★ Start here
├── install.ps1            ★ One-line install
├── devshell.ps1           ★ install | doctor | status
├── CHANGELOG.md
├── LICENSE
├── SECURITY.md
├── CONTRIBUTING.md
│
├── docs/                  ★ User-facing only
│   ├── GETTING-STARTED.md
│   ├── TROUBLESHOOTING.md
│   └── ru/                (optional locale)
│
├── internal-docs/         Maintainer / platform (not in README hero)
│   ├── charter/
│   ├── baselines/
│   ├── product/
│   └── archive/
│
├── profile/               Shipped runtime
├── lib/
├── modules/
├── terminal/
├── Config/
│
├── Install-Workstation.ps1    Install chain (not user CLI)
├── Install-ShellProfile.ps1
├── Validate-Workstation.ps1
├── Test-WorkstationPlatformHardening.ps1   CI gate
│
└── [maintainer scripts at root]   Phase 2 → scripts/
```

★ = what GitHub visitors should see first

---

## 3. Git hygiene checklist

### `.gitignore` (applied)

- [x] `*.log`, `Thumbs.db`, `.env`, secrets  
- [x] `*.tmp`, `*.swp`, `.vscode/`  
- [x] `validation-*.json`, `platform-hardening-*.json`  
- [x] WIP: `Test-Menu*.ps1`, `lib/AnonymityKit.ps1`, `lib/Invoke-MenuPreview.ps1`, `modules/Private/MenuSystem.ps1`  

### Pre-push verify

```powershell
git status                    # no validation JSON, no *.tmp staged
git ls-files | Select-String 'validation-|\.tmp$|Shell\.ps1\.tmp'
pwsh -NoProfile -File Test-WorkstationPlatformHardening.ps1
pwsh -NoProfile -File devshell.ps1 doctor
```

### Commit message strategy (no rewrite)

| Prefix | Use |
|--------|-----|
| `docs:` | README, user docs, internal-docs moves |
| `chore:` | .gitignore, GitHub metadata |
| `fix:` | install/doctor UX copy (no runtime stack) |
| `release:` | version tags only |

**Do not** rewrite history on `main` — linear cleanup commits are fine.

---

## 4. GitHub first impression

### Repo description

```
Fast, self-checking PowerShell 7 dev shell for Windows — one-line install, devshell doctor health gate.
```

### Topics

`powershell`, `powershell-core`, `pwsh`, `windows`, `dev-environment`, `developer-tools`, `shell`, `dotfiles`, `windows-terminal`, `cli`, `open-source`, `productivity`

### Pin suggestion

1. **Latest release** `v2.0.0` (install URL + notes)  
2. Optional Discussion: "Install → doctor → status"  

**Do not pin:** internal-docs, baselines, charter ADRs.

### 30-second understanding test

| Question | Pass if |
|----------|---------|
| What is this? | "PowerShell dev shell + health check for Windows" |
| What do I run? | Copy install line → doctor |
| Is it safe to try? | MIT, doctor pass/fail, local-only |
| Is it a framework? | No — README says not |

**Current README:** PASS after OSS growth rewrite.

---

## 5. First users readiness checklist

### Must be true before promoting

- [ ] Fresh Windows + PW7 + Git: `irm …/install.ps1 \| iex` completes  
- [ ] `devshell doctor` → `Failed: 0`, profile ≤ 600ms  
- [ ] `devshell status` → Bootstrap/Environment OK  
- [ ] README install URL matches tagged release  
- [ ] No architecture terms in README hero  
- [ ] `internal-docs/` not linked from README main flow  

### Trust signals

| Signal | Where |
|--------|-------|
| One-line install | README top |
| Pass/fail doctor | install.ps1 runs doctor automatically |
| MIT license | LICENSE badge |
| SECURITY.md | Responsible disclosure |
| Pinned release | GitHub Releases |

### Adoption blockers (watch list)

| Risk | Mitigation |
|------|------------|
| Root script sprawl (~40 files) | Phase 2 `scripts/` move; not in README |
| `Install-Workstation` "ReviOS" banner | Future copy pass (packaging only) |
| Russian Tor/PGP docs prominent | Keep under `docs/ru/`, not README |
| Charter links in CHANGELOG | Point to internal-docs paths |
| WIP menu/Tor modules in working tree | .gitignore + do not commit |

### First-user validation (run on clean VM or new user profile)

```powershell
# 1 Remote install
irm https://raw.githubusercontent.com/XKush/homebase-devshell/v2.0.0/install.ps1 | iex

# 2 New terminal
devshell doctor    # Failed: 0
devshell status    # OK lines

# 3 Cognitive test — ask someone unfamiliar:
#    "What does this project do?" in < 30 seconds from README alone
```

---

## 6. Messaging simplification rules

### Public surface MAY say

- install, doctor, status  
- fast profile, health check, Windows, PowerShell 7  
- pass/fail, log path, recovery steps  

### Public surface MUST NOT say

- Wave A–D, orchestrator, registry, router, event core  
- platform spec lock (except one optional maintainer footnote)  
- baseline JSON, commit gates, integration rehearsal  
- ReviOS / Tor / PGP as primary product story  

### README structure (locked for adoption stage)

1. Install block (top)  
2. Why this exists (pain, not architecture)  
3. Quick start → doctor → status  
4. Three commands table  
5. Use cases + troubleshooting pointer  
6. What this is NOT  
7. One-line Advanced footer → CONTRIBUTING / docs only  

### Internal vs public boundary

**Public answers:** What do I run? Did it work? How do I fix it?  
**Internal answers:** How is it wired? Who unlocks the spec?

---

## Change log (this cleanup pass)

- Created `internal-docs/` and moved charter, baselines, product, archive  
- Created user `docs/GETTING-STARTED.md`, `docs/TROUBLESHOOTING.md`  
- Added root `CONTRIBUTING.md` (short)  
- Enhanced `.gitignore` for WIP and report artifacts  
- README remains OSS-first (no architecture leaks)

**Not changed:** lib/, profile/, modules/, devshell.ps1 behavior, Event Core, Registry, Router, Orchestrator, Extensions.
