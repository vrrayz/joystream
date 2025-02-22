#!/usr/bin/env bash
set -e

SCRIPT_PATH="$(dirname "${BASH_SOURCE[0]}")"
cd $SCRIPT_PATH

CONTAINER_ID=$(./run-test-node-docker.sh)

function cleanup() {
    echo "# Colossus-1 Logs"
    docker logs colossus-1 --tail 100 || :
    echo "# Colossus-2 Logs"
    docker logs colossus-2 --tail 100 || :
    docker logs ${CONTAINER_ID} --tail 15
    docker stop ${CONTAINER_ID}
    docker rm ${CONTAINER_ID}
    docker-compose -f ../../docker-compose.yml down -v
}

trap cleanup EXIT

sleep 3

# Display runtime version
yarn workspace api-scripts tsnode-strict src/status.ts | grep Runtime

# Start any other services we want
# docker-compose -f ../../docker-compose.yml up -d colossus-1

# Start a query-node
if [ "${NO_QN}" != true ]
then
  ../../query-node/start.sh
fi

# Execute tests

if [ "${NO_STORAGE}" != true ]
then
  ./start-storage.sh
  export REUSE_KEYS=true
  export SKIP_STORAGE_AND_DISTRIBUTION=true
fi

# First scenario..
IGNORE_HIRED_LEADS=true ./run-test-scenario.sh $1

# In between pickup generated keys from first scenario or bootstrap scene with all well known
# keys for workers and members..

# Second scenario..
# ./run-test-scenario.sh $2
