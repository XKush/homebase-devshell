# RFC-0000: Template

**Status:** Template (do not accept)  
**Author:** &lt;name&gt;  
**Created:** YYYY-MM-DD  
**Discussion:** &lt;link to GitHub Discussion&gt;

---

## Summary

One paragraph: what problem this solves and for whom.

## Motivation

- Why now?
- Who asked for it (users, CI, enterprise)?
- How does it align with [MANIFESTO](../MANIFESTO.md)?

## User experience

What does the user run or see? Prefer extending `devshell health` over new top-level commands.

## Design

### Scope

What is in / out?

### Integration

- Core vs `plugins/`
- JSON report impact (`healthSchemaVersion` / `reportSchemaVersion`)
- Offline behavior

### Security & trust

- Reversible?
- Defender / Firewall / anonymity boundaries per [PROJECT-PRINCIPLES](../PROJECT-PRINCIPLES.md)

## Alternatives considered

| Option | Why not |
|--------|---------|
| … | … |

## Drawbacks

What we give up; maintenance cost.

## Unresolved questions

- [ ] …

## Implementation plan (after acceptance only)

1. ADR if needed  
2. Tests first  
3. Minimal PR scope  

**No code in the RFC PR.**
