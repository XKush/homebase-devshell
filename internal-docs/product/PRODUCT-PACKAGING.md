# Workstation Platform — Product Packaging Layer

**Scope:** Productization only (outside Architecture Lock v1.0.0 runtime)  
**Does not modify:** A–D stack, event contract, registries, extensions, trace, or execution behavior

---

## Product Name

**HomeBase DevShell** (repo: `homebase-devshell`)

Alternates rejected: *Workstation OS* (overpromises), *PowerShell Platform Framework* (framework smell).

---

## One-Line Positioning

**A locked, extension-ready PowerShell 7 dev environment that boots in under 600ms, self-checks on day one, and stays observable without becoming a framework.**

---

## CLI Surface (5 commands — user-facing only)

Thin wrappers over existing runtime. No new dispatch layers.

| Command | Maps to (internal) | Audience | Purpose |
|---------|-------------------|----------|---------|
| `devshell install` | `Install-Workstation.ps1` + `Install-ShellProfile.ps1` | New user | One-shot bootstrap |
| `devshell doctor` | `doctor` (module) | Everyone | Trust + health gate |
| `devshell status` | `Get-WorkstationPlatformContract` + `Get-WorkstationExecutionContext` | Daily use | “Is my platform OK?” |
| `devshell reload` | `Invoke-WorkstationCommand profile.reload` | Power users | Refresh profile stack |
| `devshell trace` | `Get-WorkstationExecutionTrace` (last N rows) | Debug / support | Read-only timeline |

**Not exposed publicly:** registry APIs, extension runtime, event emitters, orchestrator — remain developer/docs territory.

**Installer alias:** ship `devshell.ps1` at repo root that subcommands to existing scripts (product layer only).

---

## Installation Flow

### One-liner (Windows, PowerShell 7+)

```powershell
irm https://raw.githubusercontent.com/<org>/homebase-devshell/main/install.ps1 | iex
```

### What `install.ps1` does (product script — not runtime)

1. Require `pwsh` 7+
2. Clone or pull to `%USERPROFILE%\.homebase\devshell` (or `C:\Scripts\Workstation` for enterprise)
3. Run `Install-Workstation.ps1` (folders, deps check)
4. Run `Install-ShellProfile.ps1 -Force`
5. Run `devshell doctor` — exit non-zero if FAIL
6. Print: “Restart terminal · run `devshell status`”

### Bootstrap variants

| Channel | Flag | Target |
|---------|------|--------|
| Stable | default | `main` + latest tag |
| Pin | `-Version 2.1.0` | Specific git tag |
| Offline | `-Path \\share\homebase-devshell` | Air-gapped copy |

---

## GitHub Repository Structure (public release)

```
homebase-devshell/
├── README.md                 # Marketing + quickstart (hybrid)
├── LICENSE
├── CHANGELOG.md              # Product semver only
├── install.ps1               # One-liner entry
├── devshell.ps1              # 5-command CLI wrapper
├── SECURITY.md
├── .github/
│   ├── workflows/ci.yml      # doctor + platform hardening (no secret sauce)
│   └── ISSUE_TEMPLATE/
├── packages/                 # Optional bundles (NOT runtime code)
│   ├── extensions/           # Curated Register-WorkstationExtension examples
│   └── themes/               # OMP / WT assets
├── examples/
│   ├── extension-hello/      # Minimal Wave D extension sample
│   └── ci-doctor.yml         # GitHub Actions snippet for teams
├── docs/
│   ├── quickstart.md
│   ├── platform-spec.md      # Link/summary of LOCK v1.0.0 (read-only reference)
│   ├── extension-guide.md    # Derived from EXTENSION-GUIDELINES
│   └── troubleshooting.md
├── profile/                  # Canonical profile (existing)
├── lib/                      # Wave A–D (frozen — semver tagged with product)
├── modules/                  # KGreen.Workstation (product version in psd1)
└── scripts/                  # Renamed from repo root clutter (Install-*, Test-*)
    ├── install/
    ├── test/
    └── maintenance/
```

**Keep private / separate repo (optional):** full `docs/charter/*`, Phase 2 migration WIP, internal baselines beyond `platform-spec-wave-abcd-lock.json`.

---

## README Outline (sections only)

1. **Hero** — name, one-liner, badge (doctor / platform spec lock)
2. **Why HomeBase DevShell** — 3 bullets (fast profile, self-healing checks, extension-ready)
3. **60-second install** — one-liner + screenshot/GIF
4. **5 commands** — table with copy-paste examples
5. **What you get** — folders, module, profile (not architecture diagram)
6. **Platform spec (locked)** — 2 sentences + link to `docs/platform-spec.md`
7. **Extensions (optional)** — “add capability without forking core” + link to examples
8. **Requirements** — Windows 10+, PowerShell 7+, optional tools
9. **Verification** — `devshell doctor` expected output
10. **Pricing** — link to `#plans` (conceptual tiers)
11. **Contributing / Support** — issues, discussions, commercial contact
12. **License**

---

## Versioning Strategy (product vs platform)

Two numbers — **do not conflate**:

| Label | Example | Changes when |
|-------|---------|--------------|
| **Product version** | `2.1.0` | User-visible: doctor, profile, module commands, install UX |
| **Platform spec** | `1.0.0` (LOCKED) | Only on explicit architecture unlock + sign-off |

**Rules:**

- Git tags = **product** semver (`v2.1.0`)
- `KGreen.Workstation.psd1` `ModuleVersion` = product semver
- `Get-WorkstationPlatformContract.ContractVersion` = platform spec (unchanged until unlock)
- CHANGELOG = product only; platform unlock gets addendum in `PLATFORM-SPEC-SIGNOFF.md`
- Public CLI `devshell --version` shows: `Product 2.1.0 · Platform Spec 1.0.0`

---

## Monetization Model (conceptual tiers)

| Tier | Price | Includes |
|------|-------|----------|
| **Community** | Free | Core DevShell, doctor, public extensions examples, community support |
| **Pro** | $9–19/mo or $99/yr | Curated extension pack, premium themes, priority troubleshooting playbook, private Discord |
| **Team** | $29–49/seat/mo | SSOT config sync template, CI hardening bundle, org install script, SLA email support |

**Not sold separately:** runtime source rewrites, custom orchestrator forks, “enterprise second router” — violates lock.

**Revenue without touching runtime:** themes, extension packs, docs/courses, install automation for teams, support contracts.

---

## What NOT to Include (anti–over-engineering)

| Do not ship | Why |
|-------------|-----|
| Second CLI framework / plugin CLI parser inside product | Duplicates Wave B router |
| Public “extension marketplace” runtime | Becomes second registry |
| Cloud telemetry / event persistence SaaS | Violates Event Core lock |
| Configurable orchestration order in UI | Breaks deterministic A–D stack |
| “Visual architecture designer” | Framework overkill |
| Bundled Docker/K8s orchestration | Wrong product category |
| Auto-updater that patches `lib/Workstation*.ps1` silently | Trust + reproducibility risk |
| Free tier with stripped doctor | Undermines product promise |
| Platform spec editor | Spec is locked, not user-configurable |

**Product layer rule:** wrap, document, distribute, support — **never reinterpret execution.**

---

## Implementation Checklist (product team — post-design)

- [ ] Add `install.ps1` + `devshell.ps1` (wrappers only)
- [ ] Public repo trim + `scripts/` reorganization (no lib changes)
- [ ] README rewrite from outline
- [ ] CI: `Test-WorkstationPlatformHardening.ps1` on PR
- [ ] First public tag `v2.1.0` with product packaging, platform spec still `1.0.0`

---

**Related (locked runtime):** [PLATFORM-SPEC-SIGNOFF.md](../charter/PLATFORM-SPEC-SIGNOFF.md)
