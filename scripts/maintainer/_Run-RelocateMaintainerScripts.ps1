# One-time maintainer script relocation — run from repo root
$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
Set-Location $repoRoot

$invoke = @(
    'Invoke-AcceptanceTest.ps1','Invoke-CommandCenterAudit.ps1','Invoke-CommandCenterCI.ps1',
    'Invoke-EnhancementPass.ps1','Invoke-EnhancementReports.ps1','Invoke-FinalAudit.ps1',
    'Invoke-HomeBaseUpgrade.ps1','Invoke-Housekeeping.ps1','Invoke-Maintenance.ps1',
    'Invoke-MaxLevelPass.ps1','Invoke-OrganizationAudit.ps1','Invoke-PostProductionAudit.ps1',
    'Invoke-PostProductionValidation.ps1','Invoke-ScheduledTrustProbe.ps1','Invoke-SystemDiscovery.ps1',
    'Invoke-TerminalAudit.ps1','Invoke-TerminalRecovery.ps1','Invoke-WindowsTunePass.ps1',
    'Invoke-WorkstationOrganization.ps1','Invoke-WorkstationRevision.ps1'
)
$phase2 = @(
    'Invoke-Phase2CommitGate.ps1','Invoke-Phase2IntegrationRehearsal.ps1','Invoke-Phase2Step1Baseline.ps1',
    'Save-Phase2Baseline.ps1','Save-PhaseBaseline.ps1','Get-Phase2LegacyPathReport.ps1'
)
$configure = @(
    'Configure-GitIdentity.ps1','Configure-Network.ps1','Configure-PgpIdentity.ps1',
    'Configure-Privacy.ps1','Configure-TorSecurity.ps1'
)
$test = @(
    'Test-HomeBasePaths.ps1','Test-LegacyEquivalence.ps1','Test-ReleaseVersion.ps1',
    'Test-RestoreRehearsal.ps1','Test-WorkstationCommands.ps1','Test-WorkstationPlatformHardening.ps1'
)

New-Item -ItemType Directory -Force -Path scripts/maintainer/invoke, scripts/maintainer/configure, scripts/maintainer/test, scripts/maintainer/phase2 | Out-Null

function Move-MaintainerScript {
    param([string]$Name, [string]$DestFolder)
    if (-not (Test-Path $Name)) { Write-Warning "Skip missing $Name"; return }
    $dest = "scripts/maintainer/$DestFolder/$Name"
    if (Test-Path $dest) { Write-Host "Already moved: $Name"; return }
    git mv $Name $dest
    Write-Host "Moved $Name -> $dest"
}

foreach ($n in $invoke) { Move-MaintainerScript $n 'invoke' }
foreach ($n in $phase2) { Move-MaintainerScript $n 'phase2' }
foreach ($n in $configure) { Move-MaintainerScript $n 'configure' }
foreach ($n in $test) { Move-MaintainerScript $n 'test' }

$inject = @"

. (Join-Path `$PSScriptRoot '..\_Resolve-RepoRoot.ps1')
`$repoRoot = Resolve-WorkstationRepoRoot -Start `$PSScriptRoot
"@

function Patch-MovedScript {
    param([string]$Path)
    if (-not (Test-Path $Path)) { return }
    $text = Get-Content -Path $Path -Raw
    if ($text -match 'Resolve-WorkstationRepoRoot') { return }

    if ($text -match '(?ms)^(\#Requires[^\r\n]*\r?\n)(<#[\s\S]*?#\>\r?\n)?(param[\s\S]*?\r?\n\)\r?\n)') {
        $text = $text -replace '(?ms)^(\#Requires[^\r\n]*\r?\n)(<#[\s\S]*?#\>\r?\n)?(param[\s\S]*?\r?\n\)\r?\n)', "`$1`$2`$3$inject`n"
    }
    else {
        $text = $inject + "`n" + $text
    }

    $text = $text -replace '\$root\s*=\s*\$PSScriptRoot', '$root = $repoRoot'
    $text = $text -replace '\$wsRoot\s*=\s*\$PSScriptRoot', '$wsRoot = $repoRoot'
    $text = $text -replace '\$PSScriptRoot\\lib\\', '$repoRoot\lib\'
    $text = $text -replace "\`$PSScriptRoot\\lib\\", '$repoRoot\lib\'
    $text = $text -replace "Join-Path `$PSScriptRoot 'lib\\", "Join-Path `$repoRoot 'lib\"
    $text = $text -replace "Join-Path `$PSScriptRoot `"lib\\", "Join-Path `$repoRoot `"lib\"
    $text = $text -replace '\& "\$PSScriptRoot\\', '& "$repoRoot\'
    $text = $text -replace '& \(Join-Path \$PSScriptRoot ', '& (Join-Path $repoRoot '
    $text = $text -replace "Join-Path `$PSScriptRoot 'modules\\", "Join-Path `$repoRoot 'modules\"
    $text = $text -replace '\[string\]\$Root = \$PSScriptRoot', '[string]$Root = $(Resolve-WorkstationRepoRoot -Start $PSScriptRoot)'

    Set-Content -Path $Path -Value $text -Encoding UTF8 -NoNewline
    Write-Host "Patched $Path"
}

Get-ChildItem scripts/maintainer -Recurse -Filter '*.ps1' |
    Where-Object { $_.Name -notlike '_*' } |
    ForEach-Object { Patch-MovedScript $_.FullName }

$shimHelper = Join-Path $repoRoot 'scripts\maintainer\_New-RootShim.ps1'
foreach ($n in ($invoke + $phase2 + $configure + $test)) {
    $folder = switch -Regex ($n) {
        '^Invoke-Phase2|^Save-Phase|^Get-Phase2' { 'phase2'; break }
        '^Invoke-' { 'invoke'; break }
        '^Configure-' { 'configure'; break }
        '^Test-' { 'test'; break }
    }
    & $shimHelper -RepoRoot $repoRoot -RelativeTarget "scripts/maintainer/$folder/$n"
}

Write-Host 'Done. Review git status and run Test-ReleaseVersion + hardening.'
