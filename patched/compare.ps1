$t = 'e:\AWS\0cve\trivy'
$before = Import-Csv "$t\emr-on-eks-spark-8.2.0-cve.csv"
$after = & 'e:\AWS\0cve\patched\to-csv.ps1' -Json "$t\emr-on-eks-spark-8.2.0-patched.json" -Csv "$t\emr-on-eks-spark-8.2.0-patched-cve.csv"
function Summ($rows, $name) {
  $o = [ordered]@{ Image = $name; Rows = $rows.Count; UniqueCVE = ($rows.CVE | Sort-Object -Unique).Count }
  foreach ($s in 'CRITICAL', 'HIGH', 'MEDIUM', 'LOW') { $o[$s] = @($rows | Where-Object Severity -eq $s).Count }
  [pscustomobject]$o
}
@((Summ $before 'before'), (Summ $after 'after')) | Format-Table -AutoSize | Out-String -Width 200
"--- after, by Type x Severity"
$after | Group-Object Type, Severity | Sort-Object Name | ForEach-Object { "{0,-22} {1}" -f $_.Name, $_.Count }
"--- remaining CRITICAL"
$after | Where-Object Severity -eq CRITICAL | ForEach-Object { "$($_.CVE) | $($_.Package) $($_.InstalledVersion) -> $($_.FixedVersion) | $($_.VulnerableFile)" }
"--- remaining HIGH/CRITICAL grouped by file"
$after | Where-Object { $_.Severity -in 'CRITICAL', 'HIGH' } | Group-Object VulnerableFile | Sort-Object Count -Descending | ForEach-Object { "{0,4}  {1}  [{2}]" -f $_.Count, $_.Name, (($_.Group.Package | Sort-Object -Unique) -join ',') }
