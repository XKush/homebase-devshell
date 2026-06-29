$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
Get-ChildItem (Join-Path $repoRoot 'scripts\maintainer') -Recurse -Filter '*.ps1' |
    Where-Object { $_.Name -notlike '_*' } |
    ForEach-Object {
        $text = Get-Content -LiteralPath $_.FullName -Raw
        if ($text -notmatch 'Resolve-WorkstationRepoRoot') { return }

        # Remove leading inject block (bad patch at file top)
        $text = $text -replace '(?ms)^\r?\n?\. \(Join-Path \$PSScriptRoot ''\.\.\\_Resolve-RepoRoot\.ps1''\)\r?\n\$repoRoot = Resolve-WorkstationRepoRoot -Start \$PSScriptRoot\r?\n', ''

        if ($text -match 'Resolve-WorkstationRepoRoot -Start \$PSScriptRoot' -and $text -match '#Requires') {
            $beforeRequires = ($text -split '#Requires', 2)[0]
            if ($beforeRequires -match 'Resolve-WorkstationRepoRoot') {
                $text = $text -replace '(?ms)^\r?\n?\. \(Join-Path \$PSScriptRoot ''\.\.\\_Resolve-RepoRoot\.ps1''\)\r?\n\$repoRoot = Resolve-WorkstationRepoRoot -Start \$PSScriptRoot\r?\n', ''
            }
        }

        $inject = @"

. (Join-Path `$PSScriptRoot '..\_Resolve-RepoRoot.ps1')
`$repoRoot = Resolve-WorkstationRepoRoot -Start `$PSScriptRoot
"@

        if ($text -notmatch 'Resolve-WorkstationRepoRoot -Start \$PSScriptRoot') {
            if ($text -match '(?ms)(param[\s\S]*?\r?\n\)\r?\n)') {
                $text = $text -replace '(?ms)(param[\s\S]*?\r?\n\)\r?\n)', "`$1$inject`n"
            }
            elseif ($text -match '(?ms)(#Requires[^\r\n]*\r?\n(?:<#[\s\S]*?#\>\r?\n)?)') {
                $text = $text -replace '(?ms)(#Requires[^\r\n]*\r?\n(?:<#[\s\S]*?#\>\r?\n)?)', "`$1$inject`n"
            }
        }

        Set-Content -LiteralPath $_.FullName -Value $text -Encoding utf8 -NoNewline
        Write-Host "Checked $($_.Name)"
    }

Write-Host 'Inject fix complete.'
