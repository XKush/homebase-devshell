$p = 'C:\Logs\Workstation\trust-report.json'
if (Test-Path $p) {
    $t = Get-Content $p -Raw | ConvertFrom-Json
    $lvl = switch ($t.Level) { 'VERIFIED' { 'OK' } 'UNTRUSTED' { '!' } default { '~' } }
    Write-Output ("T:{0}{1}" -f $t.Score, $lvl)
} else {
    Write-Output 'T:??'
}
