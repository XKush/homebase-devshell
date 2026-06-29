# HomeBase DevShell — Manifesto

One page on **why** this project exists and **what it refuses to become**.

---

## Why we exist

Professional Windows workstations fail quietly: broken PATH, dead profiles, drifted privacy settings — discovered at 2am before a deadline.

HomeBase DevShell **prepares, verifies, and maintains** those machines for developers and security professionals who need a **local, honest answer**: *ready to work or not yet?*

The primary question we answer:

```powershell
devshell health
```

---

## For whom

- Windows developers on **PowerShell 7**
- Security-minded users who want **configuration visibility**, not marketing claims
- Teams who need **machine-readable reports** (JSON) for CI or compliance notes
- People who want **one install line** and a clear dashboard — not a week-long framework study

---

## What we will never do

| We do **not** | Because |
|---------------|---------|
| Enable or reinstall **Microsoft Defender AV** | Policy: this suite does not toggle Defender for you |
| Promise **anonymity** or “untraceable” browsing | We audit **configuration**, not network identity |
| Install **unverified** or silent third-party software | User-chosen `winget` stack only; inspect `install.ps1` first |
| Change the system **without an explicit command** | No background “magic”; `install`, `-Fix`, repair are intentional |
| Break **public API** without a major version and ADR | JSON and CLI are trust |
| Become an **IDE**, **Linux distro**, **PowerToys**, or **privacy beast** | Scope creep kills reliability |

---

## What we believe

- **Trust beats features** — disclaimers, frozen API, and reversible repair matter more than command count.
- **Health over sprawl** — grow through plugins and JSON consumers, not endless top-level commands.
- **Community before roadmap** — v3.x listens first; [ROADMAP.md](ROADMAP.md) is a contract, not a wishlist.

---

## Join us

- **Use:** [README](../README.md) → `devshell health`
- **Ask:** [Discussions — Start here](https://github.com/XKush/homebase-devshell/discussions/5)
- **Build:** [GOOD-FIRST-CONTRIBUTION.md](GOOD-FIRST-CONTRIBUTION.md)
- **Deep rules:** [PROJECT-PRINCIPLES.md](PROJECT-PRINCIPLES.md)
