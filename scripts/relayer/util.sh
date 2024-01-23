#!/usr/bin/env bash

set -eu

source ${SCRIPT_DIR}/color.sh

CONF_DIR=${SCRIPT_DIR}/../../configs
DEMO_DIR=${SCRIPT_DIR}/../../temp
BIN_DIR=${SCRIPT_DIR}/../../build

RELAYER_CONF="${DEMO_DIR}/.relayer"
RLY_BINARY=${BIN_DIR}/relayer
RLY="${RLY_BINARY} --home ${RELAYER_CONF}"

println "Loaded relayer command: $RLY"

CHAINID_ONE=eth0
CHAINID_TWO=eth1
PATH_NAME=eth01

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
