# Plugins (post-v3)

HomeBase DevShell core stays small. Optional capabilities live in **plugins** without modifying frozen CLI commands.

## Planned layout

```
plugins/
  Docker/
    manifest.json    # name, version, requires
    doctor.ps1       # optional checks
    repair.ps1       # optional fixes
    install.ps1      # optional setup
  WSL/
  VSCode/
```

## Manifest sketch

```json
{
  "name": "Docker",
  "version": "1.0.0",
  "requires": { "product": ">=3.0.0" },
  "checks": ["docker-cli", "docker-desktop"]
}
```

## Integration (not implemented in v3.0.0)

`devshell health` may merge plugin sections when `plugins/*/manifest.json` is present. Core health works **without** plugins.

## Rules

- Plugins must not enable Defender, disable Firewall, or promise anonymity
- Plugins ship separately from core releases when possible
