#!/usr/bin/env bash

set -euo pipefail

[ $# -eq 1 ] || { echo "Usage: $0 STACK"; exit 1; }

STACK="${1}"

RUNTIME_IMAGE="heroku/${STACK/-/:}"
BUILD_IMAGE="${RUNTIME_IMAGE}-build"
OUTPUT_IMAGE="redis-stunnel-test-${STACK}"

echo "Building buildpack on stack ${STACK}..."

docker build \
    --build-arg "BUILD_IMAGE=${BUILD_IMAGE}" \
    --build-arg "RUNTIME_IMAGE=${RUNTIME_IMAGE}" \
    --build-arg "STACK=${STACK}" \
    -t "${OUTPUT_IMAGE}" \
    .

echo "Checking the start-stunnel wrapper works and stunnel can start..."

# Ideally this would check the value of REDIS_URL, however bugs in start-tunnel make
# testing this annoying (eg https://github.com/heroku/heroku-buildpack-redis/issues/13
# and hangs if I try to capture the output), but this is better than nothing for now.
TEST_COMMAND="bin/start-stunnel bash -c 'sleep 2 && env && cat /app/vendor/stunnel/stunnel.conf'"
docker run --rm -t --env 'REDIS_URL=redis://:secret@example.tld:1234' "${OUTPUT_IMAGE}" bash -c "set -ex && ${TEST_COMMAND}"
docker run --rm -t --env 'REDIS_URL=redis://h:secret@example.tld:1234' "${OUTPUT_IMAGE}" bash -c "set -ex && ${TEST_COMMAND}"
docker run --rm -t --env 'REDIS_URL=rediss://:secret@example.tld:1234' "${OUTPUT_IMAGE}" bash -c "set -ex && ${TEST_COMMAND}"

echo "Success!"
