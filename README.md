


# Cassandra Docker image to run on Kubernetes cluster with CassKop Cassandra operator

The goal of this project is to provide a container optimized for running Apache Cassandra on Kubernetes using the [CassKop](https://github.com/Orange-OpenSource/cassandra-k8s-operator)
Cassandra operator developed by Orange.

The Images integrates :

- [Cassandra](http://www.apache.org/dyn/closer.cgi/cassandra) version 3.11.4
- [Jolokia](http://repo1.maven.org/maven2/org/jolokia/jolokia-jvm/1.6.1/) a **JMX-HTTP** bridge providing JMX with JSON
  over HTTP version 1.6.1
- [jmx_prometheus_javaagent](https://repo1.maven.org/maven2/io/prometheus/jmx/jmx_prometheus_javaagent/) exporter version 0.11.0
- [Dumb-init](https://github.com/Yelp/dumb-init/releases/) a minimal init system for Linux containers version 1.2.2
- The base Image is  amd64/openjdk:8u212-jre-slim

## Automated build

The Cassandra image for CassKop is automatically build and stored on [Docker Hub](https://hub.docker.com/r/orangeopensource/cassandra-image)

[![CircleCI](https://circleci.com/gh/Orange-OpenSource/cassandra-image.svg?style=svg&circle-token=3eaeb597c16a3d74b5e2dec11179449513dc7fa5)](https://circleci.com/gh/Orange-OpenSource/cassandra-image)

For master branch we push latest image on docker hub and the tag with the following
`<CASSANDRA_VERSION>-<JAVA_VERSION>-<IMAGE_VERSION>` ex:
- 3.11.4-8u212-0.3.1

For branches, we tag the image with the branche_name

For tags, we create an image with tag=tag_name

## Building via Makefile

The projects Makefile contains various targets for building and pushing both the production container
and the development container, and to simulate the Gitlab Pipeline

```console
make build
```

### CQLSH Container

If you need to have a container with CQLSH you can build with:

```console
make build-cqlsh
```

# Credits

This project is based on work done at [Google](https://github.com/GoogleCloudPlatform/gke-stateful-applications-demo/tree/master/container) and has been updated to fit
with Orange Cassandra Operator needs.

.
