#!/usr/bin/env bash

set -eu

RELAYER_CONF="/.relayer"
RLY_BINARY="/relayer"
RLY="${RLY_BINARY} --home ${RELAYER_CONF}"

echo "Loaded ${PATH_NAME} relayer command: $RLY"

RETRY_COUNT=5
RETRY_INTERVAL=1

waitRelay() {
  label=$1
  query_type=$2
  filter=".$3 | length"
  for i in `seq $RETRY_COUNT`
  do
      echo "[try:$i] waiting for ${label} finalization ..."
      sleep $RETRY_INTERVAL
      unrelayed=$(${RLY} query ${query_type} ${PATH_NAME} | jq "${filter}")
      if [ $unrelayed -gt 0 ]; then
        break
      fi
  done
}
