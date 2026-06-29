# Security Policy

## Supported versions

| Version | Supported |
|---------|-----------|
| 2.0.x   | ✅        |
| < 2.0   | ❌        |

## Reporting a vulnerability

If you discover a security issue in HOME BASE:

1. **Do not** open a public issue for exploitable vulnerabilities.
2. Report privately with:
   - description and impact;
   - steps to reproduce;
   - affected commands or scripts;
   - HOME BASE version (`ModuleVersion` from `modules/KGreen.Workstation.psd1`).
3. Allow reasonable time for a fix before public disclosure.

When the repository is published, prefer **GitHub Security Advisories** (Private vulnerability reporting).

Until then, contact the maintainer directly through your established private channel.

## Response expectations

| Step | Target |
|------|--------|
| Acknowledgment | 7 days |
| Initial assessment | 14 days |
| Fix or mitigation plan | 30 days (severity-dependent) |

## Scope

**In scope:**

- Destructive operations (`Remove-Item`, backup rotation, restore)
- Profile / terminal deployment scripts
- PGP key handling (`pgp-*`)
- Firewall and privacy hardening scripts
- Trust system integrity (`trustcheck`, SelfCheck)
- Path / module load issues leading to privilege or data loss

**Out of scope:**

- Tor network anonymity guarantees (operational security is user responsibility)
- Third-party tools installed via winget (not bundled in this repo)
- Misuse of security scripts without authorization

## Safe use

HOME BASE includes security-related automation intended for **authorized lab use** on systems you own or are permitted to manage.

- Users are responsible for compliance with local laws.
- Microsoft Defender AV is **intentionally not enabled** by this project design.
- Always run `backupconfig` before mutating operations.
- Use `-WhatIf` on `cleanup` and similar commands before execution.

## Related documentation

- [internal-docs/charter/SECURITY-POLICY.md](internal-docs/charter/SECURITY-POLICY.md) — operational security chain
- [internal-docs/charter/BACKUP-POLICY.md](internal-docs/charter/BACKUP-POLICY.md) — backup and rollback
