# JSON report schemas

Machine-readable output is part of the **public API** (see [API-STABILITY.md](API-STABILITY.md)). Treat reports like an API contract.

## Active schemas

| Schema field | Version | Commands | Output |
|--------------|---------|----------|--------|
| `reportSchemaVersion` | `1.0.0` | `privacy`, `browser`, `tor`, `vpn`, `opsec` | stdout (`-Json`) + `privacy-*.json` in logs |
| `healthSchemaVersion` | `1.0.0` | `health` | stdout (`-Json`), baseline, history |
| *(implicit)* | — | `doctor -Json` | stdout + `validation-*.json` |

## Compatibility rules

### Minor product release (e.g. 3.0 → 3.1)

- **Allowed:** add new JSON fields; add new checks with new `id`s; add optional sections
- **Not allowed:** rename or remove fields; change field types; change meaning of `status` values without schema bump

### Schema version bump (e.g. `1.0.0` → `1.1.0`)

Required when:

- renaming or removing a field
- changing enum values consumers rely on
- restructuring nested objects (e.g. moving `score` out of `sections`)

Process:

1. ADR in `docs/adr/` explaining why
2. Bump `reportSchemaVersion` or `healthSchemaVersion` in code
3. Document migration in this file and CHANGELOG
4. Keep previous schema output available for **one major product version** if feasible (e.g. `-Json -Schema 1.0.0`) — optional, not required for v3.1

### Major product release (e.g. 3.x → 4.0)

- May remove CLI commands or change default behavior
- Schema majors may coincide with product major

## Consumer guidance

Integrations (GitHub Actions, Azure, Intune, Power BI) should:

1. Read `healthSchemaVersion` / `reportSchemaVersion` first
2. Ignore unknown fields (forward compatibility)
3. Pin to a schema version in CI if you need strict validation
4. Prefer **`devshell health -Json`** as the single daily integration point

## Example: health report (excerpt)

```json
{
  "healthSchemaVersion": "1.0.0",
  "productVersion": "3.0.0",
  "sections": {
    "developer": { "status": "PASS" },
    "privacyConfiguration": { "score": 89, "disclaimer": "OS configuration only..." }
  },
  "summary": { "ready": true, "message": "Ready to work." }
}
```

## Example: privacy report (excerpt)

```json
{
  "reportSchemaVersion": "1.0.0",
  "scope": "System",
  "score": { "value": 85, "max": 100, "riskLevel": "Strong configuration" },
  "checks": [{ "id": "doh", "status": "Pass" }]
}
```
