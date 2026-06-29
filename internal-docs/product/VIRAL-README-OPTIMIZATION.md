# Viral README — GitHub Growth Notes

**Product:** HomeBase DevShell · **Layer:** messaging only · **Runtime:** unchanged

---

## One-liner positioning (FINAL)

> **One command tells you if your Windows dev environment is actually ready.**

(12 words — shareable, pain + resolution, zero jargon)

**Alternates for social / release titles:**
- "Stop guessing. Run doctor. Know instantly."
- "Install once. Verify in seconds. Start working."

---

## GitHub description (≤140 chars)

```
One command to know if your Windows dev environment is ready. PowerShell 7 install + devshell doctor health check.
```

(108 characters)

**Apply:**
```powershell
gh repo edit XKush/homebase-devshell --description "One command to know if your Windows dev environment is ready. PowerShell 7 install + devshell doctor health check."
```

---

## Topics / tags (SEO)

**Core (keep):**
`powershell`, `pwsh`, `powershell-core`, `windows`, `dev-environment`, `developer-tools`, `developer-experience`, `cli`, `shell`, `dotfiles`, `dotfiles-manager`, `windows-terminal`, `windows-terminal-profile`, `pwsh-profile`, `open-source`, `productivity`

**Add for discovery:**
`environment-setup`, `devops-tools`, `health-check`, `setup-script`, `windows-dev`

---

## Pinned repo strategy

| Pin | Why |
|-----|-----|
| Release **v2.0.0** | Install URL + proof that it's shipped |
| Optional Discussion | "Install → doctor → Ready to work" FAQ thread |

**About box:** use description above — no architecture terms.

---

## Issue label strategy

| Label | Use |
|-------|-----|
| `good first issue` | README typos, docs clarity, troubleshooting gaps |
| `help wanted` | Install edge cases, doctor false positives |
| `bug` | install/doctor fails on supported Windows |
| `install` | First-run / remote install |
| `doctor` | Validation / health check |
| `question` | User support — redirect to Troubleshooting |

**Avoid in public issues:** platform-spec, wave-*, registry, internal architecture.

---

## Conversion optimization notes

### Drop-off points

| Step | Risk | Mitigation in README |
|------|------|----------------------|
| Before install | "What is this?" | Hero pain + install with zero preamble |
| After install | Commands not found | "Restart terminal" above fold |
| First doctor | Output looks scary | ✔ proof block before technical report |
| Failure | User leaves | Trust section + log path + idempotent install |
| Overwhelm | Too many commands | Only 3 in hero flow; alias in `<details>` |

### Install → first success ratio

1. Install line is **first code block** (no reading required)  
2. Single CTA after install: **doctor**  
3. Success signal: **Ready to work** (not "Passed: 71" alone)  
4. Quick start **repeats** install at bottom for scroll-up users  

### Doctor clarity

- Lead with ✔ lines (emotional pass state)  
- Numbers (`Passed: 71`) secondary on same block  
- Full JSON report removed from main README (was in details — now omitted to reduce fear)  

### First-run ambiguity removed

- Explicit: restart terminal after install  
- Explicit: 3 commands only  
- Explicit: no admin by default  
- Troubleshooting one link at bottom (not mid-hero)  

---

## Viral optimization rules (checklist)

- [x] No Wave A–D, registry, event core, orchestrator  
- [x] ≤15 second scan to grasp value  
- [x] Short lines, mobile-friendly sections  
- [x] Pain bullets ≤4  
- [x] Install duplicated (top + bottom) intentionally  
- [x] English-only hero (RU in README.ru.md)  

---

## 30-second comprehension test

Ask a stranger: *"What does this do?"*

**Pass answer:** "Installs a PowerShell setup and tells you if your machine is ready with one doctor command."

**Fail answer:** mentions framework, waves, or platform spec.
