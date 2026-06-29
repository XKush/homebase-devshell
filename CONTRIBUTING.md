# Contributing

Thanks for helping improve HomeBase DevShell.

## Before you open a PR

1. Run **`devready`** or **`devshell doctor`** — should pass on a clean install path  
2. Keep changes focused — one problem per PR  
3. Do **not** change the locked platform execution stack without maintainer sign-off (see `internal-docs/charter/PLATFORM-SPEC-SIGNOFF.md`)

Script layout: see [`scripts/README.md`](scripts/README.md) · [Repository surface](docs/product/REPOSITORY-SURFACE.md)

## Good first contributions

- README / docs clarity  
- Install or doctor error messages  
- Tests that catch real user regressions  
- Issue templates and troubleshooting gaps  

## Report bugs

Include: Windows version, PowerShell version (`$PSVersionTable`), doctor JSON path or summary, steps to reproduce.

**Security:** see [SECURITY.md](SECURITY.md).
