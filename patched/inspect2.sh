#!/bin/bash
echo "== failureaccess / commons-text / vertx"
ls /usr/lib/spark/jars /usr/lib/hadoop/lib | grep -E 'failureaccess|commons-text|vertx|log4j|slf4j' | sort | uniq
echo "== rpm owners"
rpm -qf /usr/share/java/mariadb-java-client-3.5.7.jar /usr/lib/python3.11/site-packages/setuptools /usr/lib/python3.13/site-packages/setuptools 2>&1
for f in urllib3 idna virtualenv filelock pygments pip setuptools; do echo -n "py39 $f: "; rpm -qf /usr/lib/python3.9/site-packages/$f 2>&1 | head -1; done
echo "== whatrequires"
for p in python3-urllib3 python3-idna python3-virtualenv python3-filelock python3-pygments python3-pip python3-setuptools ruby3.2 ruby4.0 ruby3.2-libs ruby4.0-libs python3.11-pip python3.13-pip python3.11-setuptools; do
  echo "-- $p: $(rpm -q --whatrequires $p 2>&1 | tr '\n' ' ')"
done
rpm -qa | grep -Ei '^(ruby|rubygem)' | tr '\n' ' '; echo
echo "== dnf check-update (latest releasever)"
dnf -q check-update --releasever=latest 2>&1 | head -80
