# Changelog

All notable changes to **HomeBase DevShell** are documented here.

Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) · Versioning: [SemVer](https://semver.org/)

**Product version** (this file, git tags) is separate from **platform spec** (`1.0.0` LOCKED).

---

## [Unreleased]

---

## [2.0.0] - 2026-06-29

**HomeBase DevShell — first public stable release**

### Added

- **Product CLI** — `devshell.ps1` with `install`, `doctor`, `status`, `reload`, `trace`
- **Bootstrap installer** — `install.ps1` (one-line / local, idempotent re-run)
- **Public README** — install flow, core commands, examples, scope boundaries
- **KGreen.Workstation** command center — `doctor` (75 checks), `home`, `go`, trust system
- **Fast profile** — canonical PowerShell 7 profile, sub-600ms load target
- **Platform stack (shipped, spec LOCKED v1.0.0)** — orchestration, registry, router, events, trace, extensions boundary
- **Operational hardening** — `Test-WorkstationPlatformHardening.ps1` (11 scenarios)
- **Platform spec sign-off** — [PLATFORM-SPEC-SIGNOFF.md](docs/charter/PLATFORM-SPEC-SIGNOFF.md)

### Stability

- Platform execution architecture **frozen at spec v1.0.0** — product updates do not silently change dispatch model
- Unified event lifecycle contract (`command.execute.*`, `profile.init.*`, `extension.execute.*`)
- Registry separation: core commands vs extensions vs module catalog
- Fail-closed install: bootstrap + `devshell doctor` required for SUCCESS

### Known limitations

- **Windows only** — no Linux/macOS profile path
- **`devshell trace`** — current process session only (not persisted logs)
- **Remote install** — requires Git + network; pin install URL to a release tag for reproducibility
- **Admin/privacy scripts** — not run by default product install (`-SkipAdmin`); optional via full `Install-Workstation`
- **Module menu WIP** — some navigation commands may fail doctor on minimal installs until module config is complete

### Documentation

- [GitHub Release Plan](docs/product/GITHUB-RELEASE-PLAN.md)
- [Public repo structure](docs/product/PUBLIC-REPO-STRUCTURE.md)
- [Install UX review](docs/product/INSTALL-UX-REVIEW.md)
- [Extension guidelines](docs/charter/EXTENSION-GUIDELINES.md)

---

## [1.x] - Historical

Pre–HomeBase DevShell iterations. See `docs/` archive and git history before public OSS rename.

---

[Unreleased]: https://github.com/KGreen/homebase-devshell/compare/v2.0.0...HEAD
[2.0.0]: https://github.com/KGreen/homebase-devshell/releases/tag/v2.0.0
