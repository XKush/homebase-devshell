#Requires -Version 7.0
#Requires -Modules @{ ModuleName = 'Pester'; ModuleVersion = '5.0.0' }

BeforeAll {
    $script:Root = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
    . (Join-Path $script:Root 'lib\DevShellHealth.ps1')
    $script:Sample = [PSCustomObject]@{
        timestamp     = (Get-Date).ToString('o')
        sections      = [ordered]@{
            developer            = @{ label = 'Developer'; status = 'PASS' }
            privacyConfiguration = @{ label = 'Privacy Configuration'; status = 'PASS'; score = 90 }
        }
        privacyReport = @{ checks = @(@{ id = 'doh'; status = 'Pass' }) }
    }
}

Describe 'Compare-DevShellHealthBaseline' {
    It 'returns noBaseline when file missing' {
        $path = Join-Path $env:TEMP "pester-nobase-$([guid]::NewGuid().ToString('N')).json"
        $r = Compare-DevShellHealthBaseline -Current $script:Sample -BaselinePath $path
        $r.noBaseline | Should -Be $true
        $r.driftDetected | Should -Be $false
    }

    It 'returns baselineInvalid on corrupt JSON' {
        $path = Join-Path $env:TEMP "pester-badbase-$([guid]::NewGuid().ToString('N')).json"
        try {
            Set-Content $path '{ not-json' -Encoding UTF8
            $r = Compare-DevShellHealthBaseline -Current $script:Sample -BaselinePath $path
            $r.baselineInvalid | Should -Be $true
            $r.driftDetected | Should -Be $true
        } finally {
            Remove-Item $path -Force -ErrorAction SilentlyContinue
        }
    }
}

Describe 'Resolve-DevShellHealthSectionKeys' {
    It 'defaults to all sections when empty' {
        $keys = Resolve-DevShellHealthSectionKeys -Sections @()
        $keys.Count | Should -Be 4
    }

    It 'resolves developer alias' {
        $keys = Resolve-DevShellHealthSectionKeys -Sections @('developer')
        $keys | Should -Be @('developer')
    }

    It 'resolves comma-separated names' {
        $keys = Resolve-DevShellHealthSectionKeys -Sections @('developer,privacy')
        $keys | Should -Contain 'developer'
        $keys | Should -Contain 'privacyConfiguration'
    }
}
