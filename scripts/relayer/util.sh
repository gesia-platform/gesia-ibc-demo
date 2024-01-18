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

