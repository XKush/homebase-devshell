#Requires -Version 7.0
function Get-DevShellProductVersionFromRoot {
    param([string]$RepoRoot)
    $psd1 = Join-Path $RepoRoot 'modules\KGreen.Workstation.psd1'
    if (Test-Path $psd1) { return [string](Import-PowerShellDataFile $psd1).ModuleVersion }
    return '0.0.0'
}

function Write-PrivacyInvokeResult {
    param(
        [object]$Report,
        [string]$RepoRoot,
        [switch]$Json
    )
    $product = Get-DevShellProductVersionFromRoot -RepoRoot $RepoRoot
    if ($Json) {
        $doc = ConvertTo-PrivacyReportDocument -Report $Report -ProductVersion $product -Context $Report.Context
        $doc | ConvertTo-Json -Depth 8
    } else {
        $null = Write-PrivacyAuditReport -Report $Report
    }
    Save-PrivacyAuditReport -Report $Report | Out-Null
}
