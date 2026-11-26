param([string]$Json, [string]$Csv)
$j = Get-Content $Json -Raw | ConvertFrom-Json
$rank = @{ CRITICAL = 0; HIGH = 1; MEDIUM = 2; LOW = 3; UNKNOWN = 4 }
$rows = foreach ($r in $j.Results) {
  foreach ($v in $r.Vulnerabilities) {
    $path = if ($v.PkgPath) { "/" + $v.PkgPath.TrimStart('/') } elseif ($r.Class -eq 'os-pkgs') { "(OS package - rpm)" } else { $r.Target }
    [pscustomobject]@{ CVE = $v.VulnerabilityID; Severity = $v.Severity; Package = $v.PkgName; InstalledVersion = $v.InstalledVersion
      FixedVersion = $v.FixedVersion; Status = $v.Status; Type = $r.Type; VulnerableFile = $path; Title = $v.Title; URL = $v.PrimaryURL }
  }
}
$rows = @($rows | Sort-Object @{ e = { $rank[$_.Severity] } }, CVE, Package, VulnerableFile)
$rows | Export-Csv $Csv -NoTypeInformation -Encoding UTF8
$rows
