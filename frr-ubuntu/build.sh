#!/bin/bash
REGISTRY=registry.apps.arreg.la
IMAGE=frr-ubuntu
NOW=$(date +%Y%m%d%H%M%S)
docker build --no-cache \
    -t $REGISTRY/public/$IMAGE:latest \
    -t $REGISTRY/public/$IMAGE:$NOW .
docker push $REGISTRY/public/$IMAGE:latest
docker push $REGISTRY/public/$IMAGE:$NOW