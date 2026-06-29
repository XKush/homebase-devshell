# Title (copy to Reddit)

**[Tool] DevReady — one command to check if your Windows + pwsh dev box is actually ready**

---

## Body

I ship a small MIT utility for **Windows + PowerShell 7** called **DevReady** (repo: `homebase-devshell`).

**Problem:** After a reinstall or profile tweak you don't know if git, PATH, `$PROFILE`, and your command registry are *actually* working until something fails at 2am.

**Answer:** Install once, run `devready`, get pass/fail locally. Nothing uploaded.

```powershell
irm https://raw.githubusercontent.com/XKush/homebase-devshell/v2.2.0/install.ps1 | iex
# new terminal
devready
```

**Don't trust `irm | iex`?** Fair.

1. **Dry-run:** clone the repo and run `pwsh -File devshell.ps1 init` — prints the full install plan, no winget, no changes.
2. **Verified zip:** download `devready-v2.2.0.zip` + `.sha256.txt` from [Releases](https://github.com/XKush/homebase-devshell/releases/tag/v2.2.0), expand, `pwsh -File install.ps1 -SkipClone -SkipTools`.
3. **Read first:** [install.ps1 on GitHub](https://github.com/XKush/homebase-devshell/blob/v2.2.0/install.ps1) (pinned tag).

Demo GIF in README:

https://github.com/XKush/homebase-devshell/blob/v2.2.0/docs/assets/devready-demo.gif

**What it is NOT:** a cross-platform dotfiles framework, a Kali clone, or a cloud dashboard. Three product commands: `install`, `doctor`, `status` (+ `init` for planning).

**Tiers:**
- **Core** (default OSS): pwsh, git, profile, command-health — passes from a clean user-scope install
- **Full**: optional tools + security audits if you installed the winget stack

If you try it, a screenshot in [this thread](https://github.com/XKush/homebase-devshell/issues/2) helps the next person (social proof gallery).

Feedback welcome — especially install friction on clean VMs.

---

## Flair

Suggest: `Tools & Scripts` or `Discussion`

## Cross-post

r/windows — shorten to install + zip path only
