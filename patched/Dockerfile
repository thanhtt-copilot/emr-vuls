# Patched EMR on EKS image for emr-spark-8.2.0
# Scope: only fixes that do not remove features and stay on compatible version lines.
#  1. OS packages: dnf upgrade to the latest Amazon Linux 2023 release (security fixes from ALAS)
#  2. Standalone jars (not shaded): same-line upgrades from Maven Central, SHA-1 verified
#  3. pip / setuptools for Python 3.11 and 3.13 (the Pythons used by PySpark)
ARG BASE_IMAGE=public.ecr.aws/emr-on-eks/spark/emr-spark-8.2.0@sha256:931a64f282e2e1455bbcce77a24ab9ae6bb37d033690cfff4f430c201db0d3b8
FROM ${BASE_IMAGE}

USER root

# 1. OS packages. AL2023 locks the repo to the image's release, so --releasever=latest is needed.
RUN dnf -y upgrade --releasever=latest \
 && dnf clean all && rm -rf /var/cache/dnf

# 2. Standalone jars
COPY patch-jars.sh /tmp/patch-jars.sh
RUN bash /tmp/patch-jars.sh && rm -f /tmp/patch-jars.sh

# 3. pip / setuptools for Python 3.11 and 3.13.
#    New versions go to /usr/local; the old rpm copies (no other package depends on them) are then removed.
RUN python3.11 -m pip install --no-cache-dir --upgrade --ignore-installed "pip==26.3" "setuptools==84.2.1" \
 && python3.13 -m pip install --no-cache-dir --upgrade --ignore-installed "pip==26.3" \
 && rpm -e python3.11-pip python3.11-setuptools python3.13-pip \
 && python3.11 -m pip --version && python3.13 -m pip --version \
 && python3.11 -c "import setuptools; print('setuptools', setuptools.__version__)"

USER hadoop:hadoop
