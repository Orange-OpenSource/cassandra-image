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

PROJECT_ID?=orangeopensource
ifeq ($(CI_REGISTRY_IMAGE),)
	PROJECT?=${PROJECT_ID}/cassandra-image
else
	PROJECT:=$(CI_REGISTRY_IMAGE)
endif

VERSION:=0.3.2
CASSANDRA_VERSION:=3.11.4

JAVA_VERSION=$(shell cat Dockerfile | grep FROM | cut -d':' -f2- | cut -d'-' -f1)

TAG?=${CASSANDRA_VERSION}-${JAVA_VERSION}-${VERSION}
ifeq ($(CIRCLE_BRANCH),master)
	BRANCH:=latest
else ifeq ($(CIRCLE_TAG),)
  BRANCH=$(CIRCLE_BRANCH)
else
  BRANCH=$(CIRCLE_TAG)
endif

.PHONY: all build build-cqlsh build-openjre build-openjre-cqlsh push push-cqlsh

all: build

params:
	echo ${PROJECT} ${BRANCH}
	echo $(VERSION) $(JAVA_VERSION) $(CASSANDRA_VERSION)
	echo $(TAG)

build: params
	docker build --pull --build-arg "CASSANDRA_VERSION=${CASSANDRA_VERSION}" \
							 --build-arg https_proxy=$(https_proxy) --build-arg http_proxy=$(http_proxy) \
							 -t ${PROJECT}:${TAG} .

build-cqlsh: params
	docker build --pull --build-arg "CASSANDRA_VERSION=${CASSANDRA_VERSION}" \
							--build-arg="CQLSH_CONTAINER=1" \
							 --build-arg https_proxy=$(https_proxy) --build-arg http_proxy=$(http_proxy) \
							-t ${PROJECT}:${TAG}-cqlsh .


push:
ifeq ($(CIRCLE_BRANCH),master)
	docker push ${PROJECT}:${TAG}
endif
	docker tag ${PROJECT}:${TAG} ${PROJECT}:${BRANCH}
	docker push ${PROJECT}:${BRANCH}

push-cqlsh:
ifeq ($(CIRCLE_BRANCH),master)
	docker push ${PROJECT}:${TAG}-cqlsh
endif
	docker tag ${PROJECT}:${TAG}-cqlsh ${PROJECT}:${BRANCH}-cqlsh
	docker push ${PROJECT}:${BRANCH}-cqlsh

