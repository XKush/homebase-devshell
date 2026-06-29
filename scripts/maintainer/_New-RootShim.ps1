param(
    [string]$RepoRoot,
    [string]$RelativeTarget
)

$shimName = Split-Path $RelativeTarget -Leaf
$shimPath = Join-Path $RepoRoot $shimName
$rel = ($RelativeTarget -replace '/', '\')

$content = @"
#Requires -Version 7.0
<#
.SYNOPSIS
    Root shim — forwards to scripts/maintainer (backwards compatibility).
#>
`$env:HOMEBASE_DEVSHELL_ROOT = `$PSScriptRoot
& (Join-Path `$PSScriptRoot '$rel') @args
if (`$null -ne `$LASTEXITCODE) { exit `$LASTEXITCODE }
"@

Set-Content -Path $shimPath -Value $content -Encoding UTF8
Write-Host "Shim: $shimName"
