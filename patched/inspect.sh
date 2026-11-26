#!/bin/bash
id
for d in /usr/lib/spark/jars /usr/lib/hadoop/lib /usr/lib/livy/rsc-jars /usr/share/java; do
  echo "== $d"
  ls "$d" | grep -Ei '^(netty|bc|jackson|log4j|guava|lz4|snappy|derby|zookeeper|jetty|commons-lang3|commons-configuration2|mariadb|vertx|kotlin)' | tr '\n' ' '
  echo
done
echo "== other copies of same families elsewhere"
find / -xdev -name '*.jar' 2>/dev/null | grep -E '/(netty-handler|bcprov|jackson-databind|log4j-core|snappy-java|lz4-java|derby|guava)-[0-9]' | grep -vE '^/usr/lib/(spark/jars|hadoop/lib|livy/rsc-jars)/'
echo "== symlinks"
find /usr/lib/spark/jars /usr/lib/hadoop/lib /usr/lib/livy/rsc-jars -type l | head -20
which dnf curl python3.11 python3.13
python3.11 -m pip --version; python3.13 -m pip --version
rpm -qf /usr/lib/python3.11/site-packages/pip /usr/lib/python3.13/site-packages/pip /usr/lib/livy/rsc-jars/netty-handler-4.2.7.Final.jar /usr/lib/spark/jars/derby-10.16.1.1.jar /usr/lib/hadoop/lib/bcprov-jdk18on-1.78.1.jar
cat /etc/os-release | head -3
