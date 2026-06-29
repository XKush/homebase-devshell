# DevReady packaging

Install paths beyond `irm | iex` and git clone.

## Release zip (recommended for security-conscious users)

Each [GitHub Release](https://github.com/XKush/homebase-devshell/releases) ships:

| Asset | Purpose |
|-------|---------|
| `devready-vX.Y.Z.zip` | Product tree (no `internal-docs/`) |
| `devready-vX.Y.Z.sha256.txt` | Lowercase SHA256 of the zip |

```powershell
$tag = 'v3.0.1'
$zip = "$env:TEMP\devready-$tag.zip"
Invoke-WebRequest "https://github.com/XKush/homebase-devshell/releases/download/$tag/devready-$tag.zip" -OutFile $zip
$expected = (Invoke-WebRequest "https://github.com/XKush/homebase-devshell/releases/download/$tag/devready-$tag.sha256.txt" -UseBasicParsing).Content.Trim()
$actual = (Get-FileHash $zip -Algorithm SHA256).Hash.ToLower()
if ($actual -ne $expected) { throw "SHA256 mismatch" }
Expand-Archive $zip -DestinationPath "$env:USERPROFILE\.homebase\devshell" -Force
pwsh -File "$env:USERPROFILE\.homebase\devshell\install.ps1" -SkipClone -SkipTools
```

## Scoop (community bucket)

Manifest: [`scoop/devready.json`](scoop/devready.json)

```powershell
scoop bucket add devready https://github.com/XKush/homebase-devshell
scoop install devready
```

Or add manifest to your own bucket and update `hash` after each release (`Build-DevReadyRelease.ps1 -UpdateManifests`).

## WinGet

Manifest template: [`winget/XKush.DevReady.yaml`](winget/XKush.DevReady.yaml)

Submit to [microsoft/winget-pkgs](https://github.com/microsoft/winget-pkgs) after updating `InstallerSha256` from the release sidecar.

Local test:

```powershell
winget install --manifest .\packaging\winget\XKush.DevReady.yaml
```

## Maintainer build

```powershell
pwsh -File scripts/maintainer/invoke/Build-DevReadyRelease.ps1 -UpdateManifests
```

CI attaches zip + SHA256 on every `v*` tag push.
