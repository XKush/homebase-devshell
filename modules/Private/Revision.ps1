# HOME BASE revision — навести порядок одной командой

function revise {
    param(
        [switch]$Help,
        [switch]$Quick,
        [switch]$Backup
    )
    if (Test-ShowCommandHelp -Name 'revise' -Help:$Help) { return }
    Invoke-WorkstationCmd 'revise' {
        $args = @{}
        if ($Quick) { $args.Quick = $true }
        if ($Backup) { $args.Backup = $true }
        & (Join-Path $script:WSRoot 'Invoke-WorkstationRevision.ps1') @args
    }
}

function poriadok {
    param(
        [switch]$Help,
        [switch]$Quick,
        [switch]$Backup
    )
    revise @PSBoundParameters
}
