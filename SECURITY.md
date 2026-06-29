# Security Policy

## Supported versions

| Version | Supported |
|---------|-----------|
| **3.0.x** | ✅ Current |
| 2.x | Best effort (no new features) |
| < 2.0 | ❌ |

## Reporting a vulnerability

If you discover a security issue in **HomeBase DevShell** / DevReady:

1. **Do not** open a public issue for exploitable vulnerabilities.
2. Use **[GitHub Private vulnerability reporting](https://github.com/XKush/homebase-devshell/security/advisories/new)** (preferred).
3. Include:
   - description and impact;
   - steps to reproduce;
   - affected commands or scripts;
   - version from `devshell version` or `modules/KGreen.Workstation.psd1` `ModuleVersion`.

## Response expectations

| Step | Target |
|------|--------|
| Acknowledgment | 7 days |
| Initial assessment | 14 days |
| Fix or mitigation plan | 30 days (severity-dependent) |

## Scope

**In scope:**

- Product CLI: `install`, `health`, `doctor`, `privacy`, `repair` (`-Fix`)
- Destructive module commands (`restoreconfig`, `cleanup`, backup rotation)
- Profile / terminal deployment scripts
- PGP key handling (`pgp-*`)
- Privacy repair scripts (registry/DNS)
- Path / module load issues leading to privilege or data loss

**Out of scope:**

- Tor network anonymity guarantees
- Third-party tools installed via winget
- Misuse on systems you are not authorized to manage

## Safe use

- Intended for **systems you own or may manage**.
- Microsoft Defender AV is **never enabled** by this project.
- Run `backupconfig` before destructive module operations.
- Use `-WhatIf` on `cleanup` where supported.

## Static analysis

GitHub **CodeQL does not support PowerShell** ([tracking issue](https://github.com/github/codeql/issues/17927)). CI uses **PSScriptAnalyzer** (`script-analysis` job) plus smoke tests instead.

## Related documentation

- [MANIFESTO](docs/MANIFESTO.md) — trust boundaries
- [PROJECT-PRINCIPLES](docs/PROJECT-PRINCIPLES.md) — repair and privacy rules
- [RELEASE-CRITERIA](docs/RELEASE-CRITERIA.md) — release gates
