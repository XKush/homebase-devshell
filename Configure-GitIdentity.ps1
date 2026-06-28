#Requires -Version 7.0
<#
.SYNOPSIS
    Set git identity for KGreen workstation.
.PARAMETER Email
    Override email. Also reads $env:WORKSTATION_GIT_EMAIL, then gh api if logged in.
#>
param(
    [string]$Email,
    [string]$Name = 'KGreen'
)

$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\lib\WorkstationCommon.ps1"

$placeholderPattern = 'local\.workstation|example\.com|placeholder|Admin@local'

function Get-GitIdentityEmail {
    param([string]$Override)
    if ($Override) { return $Override.Trim() }
    if ($env:WORKSTATION_GIT_EMAIL) { return $env:WORKSTATION_GIT_EMAIL.Trim() }

    if (Get-Command gh -ErrorAction SilentlyContinue) {
        try {
            $ghUser = gh api user -q .login 2>$null
            if ($ghUser) {
                $ghId = gh api user -q .id 2>$null
                if ($ghId) { return "{0}+{1}@users.noreply.github.com" -f $ghId, $ghUser }
            }
        } catch { }
    }

    $current = git config --global user.email 2>$null
    if ($current -and $current -notmatch $placeholderPattern) { return $current.Trim() }

    return $null
}

git config --global user.name $Name

$resolved = Get-GitIdentityEmail -Override $Email
if ($resolved) {
    git config --global user.email $resolved
    Write-WorkstationLog "Git: $Name <$resolved>" 'OK'
} else {
    git config --global user.email 'kgreen@local.workstation'
    Write-WorkstationLog "Git: $Name <kgreen@local.workstation> (placeholder)" 'WARN'
    Write-Host '  Set real email: Configure-GitIdentity.ps1 -Email you@domain.com' -ForegroundColor Yellow
    Write-Host '  Or: gh auth login  then re-run this script' -ForegroundColor DarkGray
}

git config --global init.defaultBranch main
git config --global core.autocrlf true
git config --global pull.rebase false
