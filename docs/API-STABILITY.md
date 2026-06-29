# API Stability (v3.0+)

Frozen **product CLI** commands — semver **major** bump required to break behavior or remove:

| Command | Purpose |
|---------|---------|
| `devshell install` | Bootstrap workstation |
| `devshell doctor` / `devready` | Developer readiness |
| `devshell health` | Unified dashboard (aggregates doctor + privacy + browser + network) |
| `devshell history` | Score trend from past health runs |
| `devshell baseline` | Save health snapshot for drift detection |
| `devshell verify` | Compare current state to baseline |
| `devshell privacy` | OS privacy configuration audit |
| `devshell browser` | Browser configuration audit |
| `devshell repair` | *(via `doctor -Fix` and `privacy -Fix`)* |

**Advanced audits** (frozen flags, same semver rules): `tor`, `vpn`, `opsec`, `metadata`, `clean-meta` — prefer `devshell health` for daily use.

## Stable flags

- `-Json` / `-JsonOnly` on `doctor`, `privacy`, `health`, `verify`
- `-Fix` on `doctor`, `privacy`
- `-Tier Core|Full` on `doctor`, `health`
- `-Sections developer,privacy,browser,network` on `health` (optional subset; comma-separated)
- `-Export html` on `health`

## JSON schemas (versioned)

| Schema | Version | File pattern |
|--------|---------|--------------|
| Privacy report | `1.0.0` | `privacy-*.json` |
| Health report | `1.0.0` | `health-history.jsonl`, baseline |
| Doctor validation | *(implicit)* | `validation-*.json` |

New fields may be **added** in minor releases. Renaming or removing fields requires schema version bump.

Full policy: [JSON-SCHEMA.md](JSON-SCHEMA.md)

## Not frozen (profile / maintainer)

Commands inside `KGreen.Workstation` module (`sec`, `go`, `jarvis`, …) may change without major product bump. They are **not** the public DevReady API.

## Plugins (post-v3)

Optional extensions under `plugins/` — separate manifests; do not modify frozen commands.
