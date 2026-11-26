#!/bin/bash
set -e
echo "== whoami: $(id -un)"
find /usr/lib/spark/jars /usr/lib/hadoop/lib /usr/lib/hadoop/client /usr/lib/livy/rsc-jars -xtype l 2>/dev/null | sort > /tmp/broken.txt
echo "== broken symlinks: $(wc -l < /tmp/broken.txt) (saved to /w/broken-$(cat /etc/hostname | cut -c1-4).txt)"
cp /tmp/broken.txt "/w/broken-${TAG:-x}.txt"
echo "== netty / jackson / snappy / lz4 / guava versions in spark/jars:"
ls /usr/lib/spark/jars | grep -E '^(netty|jackson|guava|snappy|lz4|zookeeper|vertx|log4j)' | sed -E 's/^([a-z0-9_.-]+)-([0-9][0-9A-Za-z.]*(Final|jre)?).*$/\2/' | sort | uniq -c
[ "${SMOKE_RUN:-1}" = 1 ] || exit 0
java -version 2>&1 | head -1
cat > /tmp/t.py <<'EOF'
from pyspark.sql import SparkSession, functions as F
s = (SparkSession.builder.appName("smoke")
     .config("spark.sql.parquet.compression.codec", "snappy")
     .config("spark.io.compression.codec", "lz4").getOrCreate())
df = s.range(0, 200000).withColumn("k", F.col("id") % 13).withColumn("j", F.to_json(F.struct("id", "k")))
agg = df.groupBy("k").agg(F.count("*").alias("c"), F.sum("id").alias("s")).orderBy("k")
agg.write.mode("overwrite").parquet("/tmp/out_snappy")
back = s.read.parquet("/tmp/out_snappy")
assert back.count() == 13 and back.agg(F.sum("c")).first()[0] == 200000
df.select(F.from_json("j", "id long, k long").alias("p")).select("p.*").write.mode("overwrite").option("compression", "lz4").orc("/tmp/out_lz4")
assert s.read.orc("/tmp/out_lz4").count() == 200000
s.sql("select 1 as a").write.mode("overwrite").json("/tmp/out_json")
print("PYSPARK_SMOKE_OK", s.version)
s.stop()
EOF
cd /tmp
C="--master local[2] --deploy-mode client"
/usr/lib/spark/bin/spark-submit $C /tmp/t.py 2>/tmp/py.err | grep PYSPARK_SMOKE_OK || { tail -40 /tmp/py.err; exit 1; }
echo "-- errors in pyspark log:"; grep -E 'NoSuchMethod|NoClassDef|ClassNotFound|ERROR' /tmp/py.err | head -10 || true
/usr/lib/spark/bin/run-example $C SparkPi 20 2>/tmp/pi.err | grep -E 'Pi is roughly' || { tail -40 /tmp/pi.err; exit 1; }
echo "-- errors in SparkPi log:"; grep -E 'NoSuchMethod|NoClassDef|ClassNotFound|ERROR' /tmp/pi.err | head -10 || true
echo 'println("SCALA_OK " + spark.range(1000).selectExpr("sum(id)").first().getLong(0)); System.exit(0)' | /usr/lib/spark/bin/spark-shell $C 2>/tmp/sh.err | grep SCALA_OK || { tail -30 /tmp/sh.err; exit 1; }
echo "SMOKE_DONE"
