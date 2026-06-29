# Project principles

Engineering guardrails for contributors and future maintainers. When in doubt, prefer these over convenience.

---

1. **HomeBase DevShell prepares workstations** — readiness, verification, maintenance. Not a general automation framework.

2. **It is not an operating system** — no distro replacement, no full desktop takeover, no Ninite/Chocolatey clone.

3. **Privacy means configuration auditing** — OS and browser settings we can observe offline. **Not anonymity.** Say so in UI and docs.

4. **Automation must be reversible** — idempotent repairs, baselines, backups where registry is touched. `-Fix` never hides what it changed.

5. **JSON is public API** — `-Json` output is a contract. See [JSON-SCHEMA.md](JSON-SCHEMA.md) and [API-STABILITY.md](API-STABILITY.md).

6. **`devshell health` is the primary entry point** — daily use aggregates doctor + privacy + browser + network. Subcommands stay for specialists and CI.

7. **Backward compatibility is preferred** — frozen CLI in v3+; additive JSON fields in minors; breaking changes need major + ADR.

8. **Reliability over feature count** — one thing done well beats twenty half-done commands.

9. **Offline support whenever possible** — audits and doctor should degrade gracefully without calling external leak-test sites.

10. **Repair must never reduce system security** — no enabling untrusted software, no weakening firewall for “convenience,” **never enable Microsoft Defender AV** as part of this suite.

11. **Documentation is part of the product** — README, ADRs, roadmap, and discussions are release artifacts, not afterthoughts.

12. **User intent is explicit** — no silent system changes; install, `-Fix`, and repairs require a clear user command.

---

Related: [MANIFESTO.md](MANIFESTO.md) (why we exist) · [ROADMAP.md](ROADMAP.md) (what we ship when) · [adr/](adr/)
