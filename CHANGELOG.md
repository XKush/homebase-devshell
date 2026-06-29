# Changelog

All notable changes to **HomeBase DevShell** are documented here.

Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) · Versioning: [SemVer](https://semver.org/)

**Product version** (this file, git tags) is separate from **platform spec** (`1.0.0` LOCKED).

---

## [Unreleased]

### Changed

- Studio cleanup: growth copy moved to `internal-docs/marketing/`; no upload automation in repo
- `.gitignore` blocks maintainer scratch (`.tmp-*.json`)

---

## [2.1.0] - 2026-06-29

**DevReady — public brand & polished OSS surface** — platform spec `1.0.0` LOCKED.

### Added

- **DevReady** — shareable product name; `devready` PATH shim → `devshell doctor`
- README hero rewrite (badges, repo map, tiers table)
- `docs/product/BRAND.md`, `docs/README.md` hub, `CODE_OF_CONDUCT.md`
- Updated `REPOSITORY-SURFACE.md` and `scripts/README.md` (accurate paths)

### Changed

- Install banner: **DevReady** × HomeBase DevShell
- GitHub-oriented taglines and discovery copy

---

## [2.0.6] - 2026-06-29

**CI install-smoke hotfix** — platform spec `1.0.0` LOCKED.

### Fixed

- `Install-Workstation -SkipValidation` — product install no longer runs Full doctor mid-bootstrap (was hanging CI 1h+)
- `install.ps1` / `devshell install` pass `-SkipValidation`; doctor runs after `command-health`
- Folder bootstrap creates all paths from `homebase.defaults.json` (Networking, Configs, …)
- CI `install-smoke` job: 15-minute timeout, `CI=1`

---

## [2.0.5] - 2026-06-29

**CI + portable paths hotfix** — platform spec `1.0.0` LOCKED.

### Fixed

- GitHub Actions: `install-smoke` copies checkout into correct subdirectory; all jobs set `WORKSTATION_ROOT`
- `platform-hardening` on clean runner: resolve config via repo root, not hardcoded `C:\Scripts\Workstation`
- `HomeBasePaths` / `_Resolve-RepoRoot` / profile: OSS-first root resolution (`WORKSTATION_ROOT`, `~/.homebase/devshell`)
- `Config/homebase.defaults.json`: neutral `RepositoryRoot` (patched by `install.ps1`)
- `Test-MenuDeepAudit.ps1` committed for Full doctor tier
- CHANGELOG compare links; GitHub Releases for v2.0.4+

### Changed

- CI runs `Test-ReleaseVersion -RequireTagAtHead` on tag pushes

---

## [2.0.4] - 2026-06-29

**OSS honest entry — Core install passes doctor from zero** — platform spec `1.0.0` LOCKED.

### Added

- `doctor` / `Validate-Workstation -Tier Core|Full` — Core: pwsh, git, profile, module, command-health; Full: all checks
- `install.ps1 -WithTools` default (use `-SkipTools` to opt out); calls `Install-Software.ps1` for oh-my-posh, fzf, eza, …
- `devshell` shim in `%LOCALAPPDATA%\Microsoft\WindowsApps` + PATH on install
- Path diagram in `docs/GETTING-STARTED.md`
- GitHub Actions CI: release version, command-health, platform hardening, install smoke
- `Test-MenuAudit.ps1` and `Test-AnonymityKitAudit.ps1` committed (removed from `.gitignore`)
- `docs/en/COMMAND-CENTER.md`, `examples/minimal/`, `.github/FUNDING.yml`

### Changed

- Install banner: **HomeBase DevShell** (was ReviOS Professional Workstation)
- Profile startup budget default **650 ms**; over-budget is warning, not fail
- OSS default `WORKSTATION_LANG=en` (set `WORKSTATION_LANG=ru` for Russian cockpit)
- `devshell doctor` defaults to **Core** tier; interactive `doctor` defaults to **Full**
- Fixed stale paths in `Invoke-WorkstationRevision.ps1`, `Invoke-CommandCenterCI.ps1`
- Module manifest `ProjectUri` + GitHub topics

---

## [2.0.3] - 2026-06-29

**Hotfix — `irm | iex` bootstrap** — platform spec `1.0.0` LOCKED.

### Fixed

- `install.ps1` no longer calls `Join-Path` with empty `$PSScriptRoot` when run via `irm … | iex`
- One-line install clones the pinned release tag (`v2.0.3`) instead of default branch
- Bootstrap sets `WORKSTATION_ROOT` and patches `Config/homebase.defaults.json` for `~/.homebase/devshell`

---

## [2.0.2] - 2026-06-29

**Post-OSS path regression patch** — platform spec `1.0.0` LOCKED.

### Fixed

- Maintainer scripts resolve `lib/` via `Resolve-WorkstationRepoRoot` (fresh `install.ps1` no longer fails on `Backup-Configuration.ps1`)
- WOC/home cockpit resolves maintainer scripts after `scripts/maintainer/` layout move
- Removed WOC `home`/`jarvis`/`dashboard` shims that overwrote module commands and broke trust (UNTRUSTED / missing `-Help`)
- Home recommendations no longer break `go` menu audit (`validation` false positive)
- Menu audit tests use `-DisableNameChecking` (clean validate output)
- `install.ps1` runs `Test-WorkstationCommands -Quick` so `command-health.json` exists after bootstrap
- Home cockpit CHANGELOG panel reads product `CHANGELOG.md` plus session delta
- Home recommendation resolver maps `deploy: devstart` / `intel: sec` labels to real commands (menu audit on healthy system)

---

## [2.0.1] - 2026-06-29

**OSS packaging & cleanup patch** — same platform spec `1.0.0` LOCKED, no architecture changes.

### Fixed

- Track runtime dependencies (`MenuSystem`, `AnonymityKit`, `Invoke-MenuPreview`) — fresh clone works
- Restore missing Shell navigation commands (`downloads`, `desktop`, `backups`, `configs`, `networking`)
- Command registry parity (`go`, `anon`, `tor-browser`) — 72/72 command health

### Changed

- Repository root collapsed to product surface: `install.ps1`, `devshell.ps1` only
- All maintainer/install scripts under `scripts/maintainer/` with path resolution helper
- Removed 37 root shims — zero confusion for OSS visitors

---

## [2.0.0] - 2026-06-29

**HomeBase DevShell — first public stable release**

### Added

- **Product CLI** — `devshell.ps1` with `install`, `doctor`, `status`, `reload`, `trace`
- **Bootstrap installer** — `install.ps1` (one-line / local, idempotent re-run)
- **Public README** — install flow, core commands, examples, scope boundaries
- **KGreen.Workstation** command center — `doctor` (75 checks), `home`, `go`, trust system
- **Fast profile** — canonical PowerShell 7 profile, sub-600ms load target
- **Operational hardening** — `Test-WorkstationPlatformHardening.ps1` (11 scenarios)

### Stability

- Fail-closed install: bootstrap + `devshell doctor` required for SUCCESS

### Known limitations

- **Windows only** — no Linux/macOS profile path
- **`devshell trace`** — current process session only (not persisted logs)
- **Remote install** — requires Git + network; pin install URL to a release tag for reproducibility
- **Admin/privacy scripts** — not run by default product install (`-SkipAdmin`); optional via full `Install-Workstation`
- **Module menu WIP** — some navigation commands may fail doctor on minimal installs until module config is complete

### Documentation

- Maintainer docs moved to `internal-docs/` (not linked from README)

---

## [1.x] - Historical

Pre–HomeBase DevShell iterations. See git history before public OSS rename.

---

[Unreleased]: https://github.com/XKush/homebase-devshell/compare/v2.1.0...HEAD
[2.1.0]: https://github.com/XKush/homebase-devshell/releases/tag/v2.1.0
[2.0.6]: https://github.com/XKush/homebase-devshell/releases/tag/v2.0.6
[2.0.5]: https://github.com/XKush/homebase-devshell/releases/tag/v2.0.5
[2.0.4]: https://github.com/XKush/homebase-devshell/releases/tag/v2.0.4
[2.0.3]: https://github.com/XKush/homebase-devshell/releases/tag/v2.0.3
[2.0.2]: https://github.com/XKush/homebase-devshell/releases/tag/v2.0.2
[2.0.1]: https://github.com/XKush/homebase-devshell/releases/tag/v2.0.1
[2.0.0]: https://github.com/XKush/homebase-devshell/releases/tag/v2.0.0
