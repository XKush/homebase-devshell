# Patch install/*.ps1 to resolve repo root after move from repository root
$ErrorActionPreference = 'Stop'
$installDir = Join-Path $PSScriptRoot 'install'
$inject = @'
. (Join-Path $PSScriptRoot '..\_Resolve-RepoRoot.ps1')
$repoRoot = Resolve-WorkstationRepoRoot -Start $PSScriptRoot
$script:WSRoot = $repoRoot

'@

Get-ChildItem $installDir -Filter '*.ps1' | ForEach-Object {
    $text = Get-Content -LiteralPath $_.FullName -Raw
    if ($text -match 'Resolve-WorkstationRepoRoot') { return }
    $text = $text -replace '\$script:WSRoot\s*=\s*\$PSScriptRoot\r?\n', ''
    $text = $text -replace '\. "\$PSScriptRoot\\lib\\', ". (Join-Path `$repoRoot 'lib\"
    $text = $text -replace '\. \(Join-Path \$PSScriptRoot ''lib\\', ". (Join-Path `$repoRoot 'lib\"
    $text = $text -replace 'Join-Path \$PSScriptRoot ''profile\\', "Join-Path `$repoRoot 'profile\"
    $text = $text -replace 'Join-Path \$PSScriptRoot ''terminal\\', "Join-Path `$repoRoot 'terminal\"
    $text = $text -replace '\& \(Join-Path \$PSScriptRoot ''Fix-WorkstationPath\.ps1''\)', '& (Resolve-WorkstationScript -Name ''Fix-WorkstationPath.ps1'' -Start $PSScriptRoot)'
    if ($text -notmatch 'Resolve-WorkstationRepoRoot') {
        if ($text -match '(?ms)^(#Requires[^\r\n]*\r?\n)(<#[\s\S]*?#\>\r?\n)?(param[\s\S]*?\r?\n\)\r?\n)') {
            $text = $text -replace '(?ms)^(#Requires[^\r\n]*\r?\n)(<#[\s\S]*?#\>\r?\n)?(param[\s\S]*?\r?\n\)\r?\n)', "`$1`$2`$3$inject"
        } elseif ($text -match '(?ms)^(#Requires[^\r\n]*\r?\n)') {
            $text = $text -replace '(?ms)^(#Requires[^\r\n]*\r?\n)', "`$1$inject"
        } else {
            $text = $inject + $text
        }
    }
    Set-Content -LiteralPath $_.FullName -Value $text -Encoding UTF8 -NoNewline
    Write-Host "Patched install/$($_.Name)"
}
