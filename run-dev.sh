#!/bin/bash

docker run --rm -it --name k8sdev -v "/var/run/docker.sock:/var/run/docker.sock" \
    -v ${PWD}:/code \
    -p 8091:8091 \
    -p 9898:9898 \
    -e SP_ID=$SP_ID \
    -e SP_PW=$SP_PW \
    -e NS=$NS \
    -e REG=$REG \
    -e K8S=$K8S \
    -e RG=$RG \
    -e TENANT=$TENANT \
    -e SUBSCRIPTION=$SUBSCRIPTION \
    k8sdev:latest
