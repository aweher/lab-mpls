#!/bin/bash
REGISTRY=registry.dc.ayuda.la
IMAGE=influxdb
NOW=$(date +%Y%m%d%H%M%S)
docker build --no-cache \
    -t $REGISTRY/lab/$IMAGE:latest \
    -t $REGISTRY/lab/$IMAGE:$NOW .

if cat ~/.docker/config.json | jq '.auths | keys[]' | grep -q $REGISTRY; then
    docker push $REGISTRY/lab/$IMAGE:latest
    docker push $REGISTRY/lab/$IMAGE:$NOW
else
    echo "Not logged in to $REGISTRY."
    echo "Please log in first."
fi