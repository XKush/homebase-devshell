# Contributing

Thanks for helping improve HomeBase DevShell.

## Community

| Channel | Use for |
|---------|---------|
| **[Discussions](https://github.com/XKush/homebase-devshell/discussions/5)** | [Start here](https://github.com/XKush/homebase-devshell/discussions/5) — setup, usage, ideas |
| **Issues** | Bugs, install failures, reproducible problems |
| **Pull requests** | Docs, tests, fixes — see [Good first contribution](docs/GOOD-FIRST-CONTRIBUTION.md) (~15 min) |

Questions like “should I use `health` or `doctor`?” belong in **Discussions**, not the bug tracker.

## Before you open a PR

1. Run **`devshell health`** or **`devshell doctor`** on your machine  
2. Keep changes focused — one problem per PR  
3. Do **not** change the locked platform execution stack without maintainer sign-off (see `internal-docs/charter/PLATFORM-SPEC-SIGNOFF.md`)
4. JSON / CLI changes: read [API-STABILITY.md](docs/API-STABILITY.md) and [JSON-SCHEMA.md](docs/JSON-SCHEMA.md)

Script layout: [`scripts/README.md`](scripts/README.md) · [Repository surface](docs/product/REPOSITORY-SURFACE.md)

## Good first contributions

See **[docs/GOOD-FIRST-CONTRIBUTION.md](docs/GOOD-FIRST-CONTRIBUTION.md)** for a 15–20 minute path (README fix, troubleshooting line, smoke test assertion).

- README / docs clarity  
- Install or doctor error messages  
- Tests that catch real user regressions  
- Issue templates and troubleshooting gaps  

## Report bugs

Include: Windows version, PowerShell version (`$PSVersionTable`), `devshell health -Json` or doctor JSON path, steps to reproduce.

**Security:** see [SECURITY.md](SECURITY.md).

## v3 stabilization (current phase)

We are **not** adding new public CLI commands in v3.0.x. Focus: bugfix, docs, tests, feedback. Feature ideas → Discussions first.

Contract: [ROADMAP.md](docs/ROADMAP.md) · Principles: [PROJECT-PRINCIPLES.md](docs/PROJECT-PRINCIPLES.md) · [MANIFESTO.md](docs/MANIFESTO.md)
