# 👋 Start here — HomeBase DevShell v3

Welcome!

If this is your first time using HomeBase DevShell, this discussion will help you get started and explain where to ask different kinds of questions.

## What is HomeBase DevShell?

HomeBase DevShell prepares, verifies and maintains professional Windows workstations.

The project is built around one main command:

```powershell
devshell health
```

It provides a high-level overview of your workstation and summarizes developer readiness, privacy configuration and other health checks.

## Which command should I use?

### I just installed DevShell

Start here:

```powershell
devshell health
```

### Something looks wrong

Run:

```powershell
devshell doctor
```

If needed:

```powershell
devshell doctor -Fix
```

### I want to review my privacy settings

Run:

```powershell
devshell privacy
```

> Privacy Configuration evaluates operating system settings only. It does **not** measure or guarantee network anonymity.

### I need machine-readable output

Use:

```powershell
devshell health -Json
```

The JSON output is considered part of the public API. Compatibility rules are documented in [docs/JSON-SCHEMA.md](https://github.com/XKush/homebase-devshell/blob/main/docs/JSON-SCHEMA.md).

## Where should I ask questions?

Use **Discussions** for:

* installation help;
* configuration questions;
* best practices;
* ideas and feature proposals;
* sharing screenshots or reports.

Use **Issues** only when you can reproduce a bug or have a concrete defect report.

## How can I help?

If you'd like to contribute, start with:

* [docs/GOOD-FIRST-CONTRIBUTION.md](https://github.com/XKush/homebase-devshell/blob/main/docs/GOOD-FIRST-CONTRIBUTION.md)
* [CONTRIBUTING.md](https://github.com/XKush/homebase-devshell/blob/main/CONTRIBUTING.md)

Even documentation improvements and additional tests are valuable contributions.

## Current project focus

Version 3.0 is a stabilization release.

The current priorities are:

* bug fixes;
* documentation improvements;
* test coverage;
* community feedback.

We are intentionally avoiding rapid feature expansion until we understand how people use the project in real-world environments.

Thank you for trying HomeBase DevShell and for helping improve it.
