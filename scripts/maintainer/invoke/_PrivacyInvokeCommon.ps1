#Requires -Version 7.0
. (Join-Path $PSScriptRoot '..\..\..\lib\DevShellProduct.ps1')

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
