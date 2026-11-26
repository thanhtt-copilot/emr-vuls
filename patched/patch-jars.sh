#!/bin/bash
# Replace standalone (non-shaded) jars with patched versions from Maven Central.
# Only same-line upgrades (patch/minor within the same compatible line).
# Every downloaded jar is verified against the SHA-1 published on Maven Central.
set -euo pipefail
MVN=https://repo1.maven.org/maven2
LOG=/usr/share/doc/cve-patch/jar-replacements.txt
mkdir -p "$(dirname "$LOG")"

# upgrade <dir> <groupId> <artifact-name-regex> <old-version> <new-version>
# Replaces every <artifact>-<old>[-<classifier>].jar in <dir> whose artifact matches the regex.
upgrade() {
  local dir=$1 group=$2 regex=$3 old=$4 new=$5 gpath f base artifact rest classifier tgt url tmp
  gpath=${group//./\/}
  [ -d "$dir" ] || return 0
  shopt -s nullglob
  for f in "$dir"/*-"$old".jar "$dir"/*-"$old"-*.jar; do
    base=$(basename "$f" .jar)
    artifact=${base%%-"$old"*}
    [[ "$artifact" =~ ^($regex)$ ]] || continue
    rest=${base#"$artifact-$old"}
    classifier=${rest#-}
    tgt="$artifact-$new${classifier:+-$classifier}.jar"
    if [ -L "$f" ]; then
      # keep symlinks pointing at the upgraded file (handled when the real file is replaced)
      local link; link=$(readlink "$f")
      ln -sfn "$(dirname "$link")/$tgt" "$dir/$tgt"; rm -f "$f"
      echo "SYMLINK $f -> $(dirname "$link")/$tgt" | tee -a "$LOG"; continue
    fi
    url="$MVN/$gpath/$artifact/$new/$tgt"
    tmp=$(mktemp)
    curl -fsSL --retry 5 --retry-all-errors -o "$tmp" "$url"
    echo "$(curl -fsSL --retry 5 --retry-all-errors "$url.sha1" | awk '{print $1}')  $tmp" | sha1sum -c --quiet -
    install -m 0644 "$tmp" "$dir/$tgt"; rm -f "$tmp" "$f"
    echo "REPLACED $f -> $dir/$tgt" | tee -a "$LOG"
  done
}

for d in /usr/lib/spark/jars /usr/lib/livy/rsc-jars; do
  upgrade $d io.netty 'netty-[a-z0-9_-]+' 4.2.7.Final 4.2.21.Final
done
for d in /usr/lib/hadoop/lib /usr/lib/hadoop/client; do
  upgrade $d io.netty 'netty-[a-z0-9_-]+' 4.1.135.Final 4.1.141.Final
done

upgrade /usr/lib/hadoop/lib     org.bouncycastle bcprov-jdk18on 1.78.1 1.85.2
upgrade /usr/lib/livy/rsc-jars  org.bouncycastle bcprov-jdk18on 1.80   1.85.2

for a in jackson-core jackson-databind; do
  upgrade /usr/lib/spark/jars com.fasterxml.jackson.core $a 2.21.2 2.21.9
done
upgrade /usr/lib/spark/jars com.fasterxml.jackson.dataformat jackson-dataformat-yaml 2.21.2 2.21.9
upgrade /usr/lib/spark/jars com.fasterxml.jackson.datatype  jackson-datatype-jsr310  2.21.2 2.21.9
upgrade /usr/lib/spark/jars com.fasterxml.jackson.module    'jackson-module-scala_2.13' 2.21.2 2.21.9

upgrade /usr/lib/spark/jars com.google.guava guava 33.4.8-jre 33.8.0-jre
upgrade /usr/lib/spark/jars at.yawk.lz4 lz4-java 1.11.0 1.11.4
upgrade /usr/lib/spark/jars org.xerial.snappy snappy-java 1.1.10.8 1.1.10.12
for d in /usr/lib/hadoop/lib /usr/lib/hadoop/client; do
  upgrade $d org.xerial.snappy snappy-java 1.1.10.4 1.1.10.12
done

for d in /usr/lib/spark/jars /usr/lib/hadoop/lib; do
  upgrade $d org.apache.zookeeper 'zookeeper|zookeeper-jute' 3.9.3-amzn-8-amzn.20261030202207 3.9.7
done

# log4j 2.24.3 -> 2.25.x NOT applied: 2.25 rejects EMR's log4j2.properties ("No type attribute provided for component spark")
upgrade /usr/lib/hadoop/lib org.apache.commons commons-lang3 3.17.0 3.19.0
upgrade /usr/lib/spark/jars io.vertx 'vertx-(core|auth-common|web-client|web-common)' 4.5.25 4.5.36

# Re-point every symlink (e.g. /usr/lib/hadoop/client/netty-handler.jar -> ../lib/netty-handler-4.1.135.Final.jar)
# whose target was replaced above.
declare -A MAP
while read -r _ old _ new; do MAP[$(basename "$old")]=$(basename "$new"); done < <(grep '^REPLACED' "$LOG")
while read -r l; do
  t=$(readlink "$l"); b=$(basename "$t")
  if [ -n "${MAP[$b]:-}" ]; then
    nl=$l
    # versioned link name (same as old target) -> rename to the new version
    if [ "$(basename "$l")" = "$b" ]; then nl="$(dirname "$l")/${MAP[$b]}"; rm -f "$l"; fi
    ln -sfn "$(dirname "$t")/${MAP[$b]}" "$nl"
    echo "RELINK $nl -> $(dirname "$t")/${MAP[$b]}" | tee -a "$LOG"
  fi
done < <(find /usr /opt /etc -xdev -xtype l 2>/dev/null)

echo "Jar replacements done: $(grep -c . "$LOG") entries"
