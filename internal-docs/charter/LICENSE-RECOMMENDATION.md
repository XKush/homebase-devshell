# HOME BASE — License Recommendation

Анализ лицензий для Open Source публикации HOME BASE.

---

## 1. Context

HOME BASE includes:

- PowerShell module (MIT-friendly stack)
- Security tooling scripts (Tor, PGP, firewall hardening)
- Documentation (charter)
- **Explicit policy:** Defender AV disabled by design
- Potential dual-use security scripts (nmap, wireshark refs)

---

## 2. Candidates

### MIT License ⭐ **Recommended**

| Pros | Cons |
|------|------|
| Maximum adoption | No patent grant (vs Apache) |
| Simple, familiar | Permits proprietary forks |
| Compatible with PowerShell ecosystem | No copyleft — forks can close source |
| GitHub default expectation | |

**Fit:** Personal dev tooling, maximum community contribution ease.

### Apache License 2.0

| Pros | Cons |
|------|------|
| Explicit patent grant | Longer text |
| Contribution clarity | Slightly higher friction |

**Fit:** If corporate contributors expected.

### GPL-3.0

| Pros | Cons |
|------|------|
| Copyleft — forks stay open | Poor fit for Windows proprietary stack |
| Strong user freedom | Discourages commercial integration |
| | Conflict anxiety with PowerShell Gallery norms |

**Fit:** **Not recommended** — over-restrictive for workstation automation mix.

### BSD 2-Clause / 3-Clause

Similar to MIT; MIT preferred for name recognition.

---

## 3. Recommendation

**Primary: MIT License**

Add `LICENSE` file root:

```
Copyright (c) 2026 KGreen

Permission is hereby granted, free of charge, to any person obtaining a copy…
```

**Secondary files:**

- `SECURITY.md` — responsible disclosure
- `NOTICE` — third-party tools (winget packages not bundled)

---

## 4. Disclaimer (README)

Recommended notice:

> HOME BASE includes security-related automation intended for **authorized lab use**.
> Users are responsible for compliance with local laws.
> Microsoft Defender AV is intentionally not enabled by this project.

---

## 5. Third-party

| Component | License |
|-----------|---------|
| PowerShell | MIT |
| oh-my-posh | MIT |
| External tools (winget) | per package — not shipped in repo |

---

## 6. Action (Phase 1)

1. Add `LICENSE` (MIT) to repo root
2. Add copyright header to `KGreen.Workstation.psm1` (optional)
3. Reference LICENSE in CONTRIBUTING.md

---

## Related

- [CONTRIBUTING.md](./CONTRIBUTING.md)
- [PHILOSOPHY.md](./PHILOSOPHY.md) §4 Non-Goals
