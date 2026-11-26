$rows = Import-Csv 'e:\AWS\0cve\trivy\emr-on-eks-spark-8.2.0-patched-cve.csv'
$cat = $rows | ForEach-Object {
  $f = $_.VulnerableFile; $fn = Split-Path $f -Leaf; $art = ($_.Package -split ':')[-1]
  $c = if ($_.Type -eq 'gemspec') { 'ruby3.2 default gems' }
  elseif ($f -match 'python3\.9') { 'python3.9 rpm packages' }
  elseif ($f -eq 'Python') { 'pip vendored pkg_resources' }
  elseif ($f -match 'derby') { 'derby' }
  elseif ($f -match 'log4j') { 'log4j 2.24.3' }
  elseif ($_.Type -eq 'jar' -and $fn -like "$art-$($_.InstalledVersion)*.jar") { 'standalone jar, no compatible fix' }
  else { 'shaded jar (AWS must fix)' }
  [pscustomobject]@{ Cat = $c; Sev = $_.Severity }
}
$cat | Group-Object Cat | ForEach-Object {
  $g = $_.Group
  "{0,-36} total={1,-4} C={2} H={3} M={4} L={5}" -f $_.Name, $g.Count, @($g | ? Sev -eq CRITICAL).Count, @($g | ? Sev -eq HIGH).Count, @($g | ? Sev -eq MEDIUM).Count, @($g | ? Sev -eq LOW).Count
}
"--- standalone jars left:"
$rows | Where-Object { $_.Type -eq 'jar' -and (Split-Path $_.VulnerableFile -Leaf) -like "$(($_.Package -split ':')[-1])-$($_.InstalledVersion)*.jar" -and $_.VulnerableFile -notmatch 'derby|log4j' } | Group-Object VulnerableFile | ForEach-Object { "{0,3} {1}" -f $_.Count, $_.Name }
