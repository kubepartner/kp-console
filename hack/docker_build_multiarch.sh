#!/usr/bin/env bash

set -ex
set -o pipefail

TAG=${TAG:-latest}
REPO=${REPO:-kubepartner}
PUSH=${PUSH:-}

# support other container tools. e.g. podman
CONTAINER_CLI=${CONTAINER_CLI:-docker}
CONTAINER_BUILDER=${CONTAINER_BUILDER:-"buildx build"}

# If set, just building, no pushing
if [[ -z "${DRY_RUN:-}" ]]; then
  PUSH="--push"
fi

# supported platforms
PLATFORMS=linux/amd64,linux/arm64

# build the preimage
docker buildx build -f build/Dockerfile --target builder --load -t kp-console-pre:"${TAG}" .

# create preimage container
${CONTAINER_CLI} create \
  --name predbuild kp-console-pre:"${TAG}"

# copy file from preimage container:./out/ ./out/
${CONTAINER_CLI} cp \
  predbuild:/out/ ./out/

# shellcheck disable=SC2086 # inteneded splitting of CONTAINER_BUILDER
${CONTAINER_CLI} ${CONTAINER_BUILDER} \
  --platform ${PLATFORMS} \
  ${PUSH} \
  -f build/Dockerfile.dapper \
  -t "${REPO}"/kp-console:"${TAG}" .

# delete preimage
docker rmi kp-console-pre:"${TAG}" -f

# delete prebuild container
docker rm predbuild

# delete the folder in ./out
rm -rf ./out
