# Changelog

All notable changes to HOME BASE will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

### Added
- Phase 2 Step 1: `Config/homebase.defaults.json`, `Get-HomeBasePath`, wired lib/module high-traffic paths
- Phase 2 gate scripts: `Test-HomeBasePaths`, `Test-RestoreRehearsal`, `Save-Phase2Baseline`
- MIGRATION.md — migration contract before Phase 2
- ARCHITECTURE-FREEZE.md — v2.0.0 freeze until Phase 2 complete
- Full Charter Pack (`docs/charter/*`) — architecture constitution
- `Save-CommandHealthCache` before trust probe in revise
- `Ensure-WorkstationModuleLoaded` with `-Scope Global`
- Auto `cd C:\Projects` when started from System32

### Fixed
- `cleanup` / `cleanlogs` — archive backups to `_Archive` instead of delete
- `revise` / `trustcheck` — module scope after Sync-WorkstationDocs
- `SelfCheck.ps1` — null-safe `$cmd.Parameters` and `$script:SelfCheckDeps`
- `Get-WorkstationCommandHealth` — null-safe Parameters check
- Validate-Workstation — `return` instead of `exit` when invoked from revise

### Changed
- `Show-HackerQuickNav` — unified nav text with anon hotkey
- `Get-WocBackupBlock` — exclude `_Archive`, sort by LastWriteTime
- Hotkey module import — `-Scope Global` in MenuSystem

### Deprecated
- (see [LIFECYCLE.md](./LIFECYCLE.md) — no new deprecations this release)

---

## [2.0.0] - 2026-06-29

### Added
- HOME BASE neural cockpit (`Show-HomeBase`)
- Trust system with live-probe (`Get-SystemTrustReport`)
- Anonymity kit (`anon`, Ctrl+Alt+S)
- Go menu v2: [anon] + [следующий] + categories
- `revise` full pipeline (PATH, doctor, trust, SEC)
- Menu deep audit + anon kit audit in Validate (75 checks)
- Russian locale layer (`modules/locale/ru/`)

### Fixed
- Multiple post-reboot stability issues (module unload, SelfCheck)

### Security
- Backup rotation policy aligned with housekeeping
- Tor + PGP SHADOW OPS readiness in doctor

---

## [1.x] - Historical

Prior releases documented in:
- `docs/FINAL-SUMMARY.md`
- `docs/ELITE-FINAL-REPORT.md`

*(Pre-charter history — to be consolidated in Phase 1)*

---

[Unreleased]: https://github.com/example/homebase/compare/v2.0.0...HEAD
[2.0.0]: https://github.com/example/homebase/releases/tag/v2.0.0
