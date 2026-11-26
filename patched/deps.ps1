$ProgressPreference = 'SilentlyContinue'
function Get-Text($u) { [string](Invoke-WebRequest -UseBasicParsing $u).Content }
foreach ($v in '4.2.7.Final', '4.2.21.Final', '4.1.135.Final', '4.1.141.Final') {
  $c = Get-Text "https://repo1.maven.org/maven2/io/netty/netty-parent/$v/netty-parent-$v.pom"
  Write-Output ("netty {0} tcnative={1}" -f $v, [regex]::Match($c, '<tcnative.version>([^<]+)').Groups[1].Value)
}
foreach ($v in '33.7.2-jre', '33.8.0-jre') {
  $c = Get-Text "https://repo1.maven.org/maven2/com/google/guava/guava-parent/$v/guava-parent-$v.pom"
  Write-Output ("guava {0} failureaccess={1}" -f $v, [regex]::Match($c, 'failureaccess</artifactId>\s*<version>([^<]+)').Groups[1].Value)
}
$c = Get-Text 'https://repo1.maven.org/maven2/org/apache/commons/commons-configuration2/2.15.1/commons-configuration2-2.15.1.pom'
[regex]::Matches($c, '<(commons\.[a-z0-9.]+version)>([^<]+)<') | ForEach-Object { Write-Output ("cfg2 {0}={1}" -f $_.Groups[1].Value, $_.Groups[2].Value) }
$c = Get-Text 'https://repo1.maven.org/maven2/org/apache/zookeeper/zookeeper/3.9.7/zookeeper-3.9.7.pom'
Write-Output ("zk 3.9.7 parent pom refs netty: " + ([regex]::Match($c, 'netty[\s\S]{0,200}').Value -replace '\s+', ' '))
$c = Get-Text 'https://repo1.maven.org/maven2/org/apache/zookeeper/parent/3.9.7/parent-3.9.7.pom'
Write-Output ("zk 3.9.7 netty.version=" + [regex]::Match($c, '<netty.version>([^<]+)').Groups[1].Value)
$c = Get-Text 'https://repo1.maven.org/maven2/io/vertx/vertx-dependencies/4.5.36/vertx-dependencies-4.5.36.pom'
Write-Output ("vertx 4.5.36 netty=" + [regex]::Match($c, '<netty.version>([^<]+)').Groups[1].Value)
