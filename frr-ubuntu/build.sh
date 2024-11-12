#!/bin/bash
REGISTRY=registry.ayuda.la
IMAGE=frr-ubuntu
NOW=$(date +%Y%m%d%H%M%S)
docker build --no-cache \
    -t $REGISTRY/public/$IMAGE:latest \
    -t $REGISTRY/public/$IMAGE:$NOW .

if cat ~/.docker/config.json | jq '.auths | keys[]' | grep -q $REGISTRY; then
    docker push $REGISTRY/public/$IMAGE:latest
    docker push $REGISTRY/public/$IMAGE:$NOW
else
    echo "Not logged in to $REGISTRY."
    echo "Please log in first."
fi