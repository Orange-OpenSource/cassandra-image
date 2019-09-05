# Copyright 2019 Orange
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# OpenJDK base image:
# see https://github.com/docker-library/repo-info/blob/master/repos/openjdk/local/8u222-jre-slim.md
# the Dockerfile for this image is here : https://github.com/docker-library/openjdk/blob/master/8/jre/Dockerfile

FROM amd64/openjdk:8u212-jre-slim


ARG BUILD_DATE
ARG VCS_REF
ARG CASSANDRA_VERSION
ARG CQLSH_CONTAINER
ARG http_proxy
ARG https_proxy

LABEL \
    org.label-schema.build-date=$BUILD_DATE \
    org.label-schema.docker.dockerfile="/Dockerfile" \
    org.label-schema.license="Apache License 2.0" \
    org.label-schema.name="Cassandra container optimized for Kubernetes" \
    org.label-schema.url="https://github.com/Orange-OpenSource/" \
    org.label-schema.vcs-ref=$VCS_REF \
    org.label-schema.vcs-type="Git" \
    org.label-schema.vcs-url="https://github.com/Orange-OpenSource/cassandra-image" \
    org.label-schema.description="Cassandra Docker Image to be used with the Orange Cassandra Operator." \
    org.label-schema.summary="Cassandra is a NoSQL database providing scalability and hight availability without compromising performance." \
    org.label-schema.version="${CASSANDRA_VERSION}" \
    org.label-schema.changelog-url="/Changelog.md" \
    org.label-schema.maintainer="TODO" \
    org.label-schema.vendor="Orange" \
    org.label-schema.schema_version="RC1" \
    org.label-schema.usage='/README.md'

ENV \
    CASSANDRA_CONF=/etc/cassandra \
    CASSANDRA_DATA=/var/lib/cassandra \
    CASSANDRA_LOGS=/var/log/cassandra \
    CASSANDRA_RELEASE=${CASSANDRA_VERSION} \
    DI_VERSION=1.2.2 \
    JOLOKIA_VERSION=1.6.1 \
    EXPORTER_VERSION=0.9.7 \
    PATH=$PATH:/usr/local/apache-cassandra/bin:/usr/local/apache-cassandra/tools/bin/

COPY files /

RUN set -ex; \
    echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections; \
    export CASSANDRA_VERSION=${CASSANDRA_VERSION:-$CASSANDRA_RELEASE}; \
    export CASSANDRA_HOME=/usr/local/apache-cassandra-${CASSANDRA_VERSION}; \
    apt-get update && apt-get -qq -y install --no-install-recommends \
        libjemalloc2 \
        localepurge \
        wget \
        netcat \
        jq; \
    wget -q -O /usr/local/share/cassandra-exporter-agent.jar https://github.com/instaclustr/cassandra-exporter/releases/download/v${EXPORTER_VERSION}/cassandra-exporter-agent-${EXPORTER_VERSION}.jar; \
    wget -q -O /usr/local/share/jolokia-agent.jar http://search.maven.org/remotecontent?filepath=org/jolokia/jolokia-jvm/${JOLOKIA_VERSION}/jolokia-jvm-${JOLOKIA_VERSION}-agent.jar; \
    mirror_url=$( wget -q -O - 'https://www.apache.org/dyn/closer.cgi?as_json=1' | jq --raw-output '.preferred' ); \
    wget -q -O - "${mirror_url}cassandra/${CASSANDRA_VERSION}/apache-cassandra-${CASSANDRA_VERSION}-bin.tar.gz" > /usr/local/apache-cassandra-bin.tar.gz; \
    tar -xzf /usr/local/apache-cassandra-bin.tar.gz -C /usr/local; \
    rm /usr/local/apache-cassandra-bin.tar.gz; \
    ln -s $CASSANDRA_HOME /usr/local/apache-cassandra; \
    wget -q -O - https://github.com/Yelp/dumb-init/releases/download/v${DI_VERSION}/dumb-init_${DI_VERSION}_amd64 > /sbin/dumb-init; \
    adduser --disabled-password --no-create-home --gecos '' --disabled-login cassandra; \
    mkdir -p /var/lib/cassandra/ /var/log/cassandra/ /etc/cassandra/triggers; \
    chmod +x /sbin/dumb-init /ready-probe.sh; \
    chown cassandra: /ready-probe.sh; \
    mv \
      /logback.xml \
      /cassandra.yaml \
      /jvm.options \
      /exporter.conf \
      /pre_stop.sh \
      $CASSANDRA_CONF; \
    mv /usr/local/apache-cassandra/conf/cassandra-env.sh /etc/cassandra/; \
    mkdir -p $CASSANDRA_DATA/data $CASSANDRA_LOGS; \
    ls -la $CASSANDRA_DATA $CASSANDRA_LOGS; \
    mkdir -p /files; \
    touch /files/file.log; \
    chown -R cassandra: /files $CASSANDRA_CONF $CASSANDRA_DATA $CASSANDRA_LOGS; \
    chmod 700 $CASSANDRA_DATA; \
    ls -la $CASSANDRA_DATA $CASSANDRA_LOGS; \
    chown cassandra: /run.sh; \
    mkdir -p /tmp chown cassandra /tmp; \
    if [ -n "$CQLSH_CONTAINER" ]; then apt-get -y --no-install-recommends install python; else rm -rf  $CASSANDRA_HOME/pylib; fi; \
    apt-get update && apt-get -qq -y install \
       libcap2-bin \
       procps \
       dnsutils; \
    apt-get -y purge wget jq localepurge; \
    apt-get -y autoremove; \
    apt-get -y clean; \
    rm -rf \
        $CASSANDRA_HOME/*.txt \
        $CASSANDRA_HOME/doc \
        $CASSANDRA_HOME/javadoc \
        $CASSANDRA_HOME/tools/*.yaml \
        $CASSANDRA_HOME/tools/bin/*.bat \
        $CASSANDRA_HOME/bin/*.bat \
        doc \
        man \
        info \
        locale \
        common-licenses \
        ~/.bashrc \
        /var/lib/apt/lists/* \
        /var/log/**/* \
        /var/cache/debconf/* \
        /etc/systemd \
        /lib/lsb \
        /lib/udev \
        /usr/share/doc/ \
        /usr/share/doc-base/ \
        /usr/share/man/ \
        /tmp/*; \
    \
    setcap cap_ipc_lock=ep $(readlink -f $(which java))

VOLUME ["/var/lib/cassandra"]

# 9500: prometheus jmx_exporter
# 7000: intra-node communication
# 7001: TLS intra-node communication
# 7199: JMX
# 9042: CQL
# 9160: thrift service
# 8778: jolokia port
EXPOSE 9500 7000 7001 7199 9042 9160 8778

USER cassandra

CMD ["/sbin/dumb-init", "/bin/bash", "/run.sh"]
