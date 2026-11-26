$ProgressPreference = 'SilentlyContinue'
$arts = [ordered]@{
  'org/eclipse/jetty/jetty-server'            = '^9\.4\.'
  'org/apache/zookeeper/zookeeper'            = '^3\.9\.'
  'org/apache/logging/log4j/log4j-core'       = '^2\.2[5-9]'
  'org/apache/commons/commons-lang3'          = '^3\.'
  'org/apache/commons/commons-configuration2' = '^2\.'
  'org/mariadb/jdbc/mariadb-java-client'      = '^3\.5\.'
  'io/vertx/vertx-core'                       = '^4\.5\.'
  'io/netty/netty-tcnative-classes'           = '^2\.0\.'
  'io/netty/netty-handler'                    = '^4\.1\.1[3-9]'
}
foreach ($a in $arts.Keys) {
  try {
    $c = [string](Invoke-WebRequest -UseBasicParsing "https://repo1.maven.org/maven2/$a/maven-metadata.xml").Content
    $v = [regex]::Matches($c, '<version>([^<]+)</version>') | ForEach-Object { $_.Groups[1].Value } |
      Where-Object { $_ -match $arts[$a] -and $_ -notmatch 'alpha|beta|rc|-M\d|SNAPSHOT' }
    Write-Output ("{0} : {1}" -f $a.Split('/')[-1], (($v | Select-Object -Last 10) -join ' '))
  } catch { Write-Output "$a : ERR $($_.Exception.Message)" }
}
