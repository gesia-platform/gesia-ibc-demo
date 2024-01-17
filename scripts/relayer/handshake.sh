#!/usr/bin/env bash

set -eu

SCRIPT_DIR=$(cd $(dirname ${BASH_SOURCE:-$0}); pwd)

source ${SCRIPT_DIR}/util.sh

rm -rf ${RELAYER_CONF} &> /dev/null

${RLY} config init
${RLY} chains add-dir ${CONF_DIR}/relayer/chains/

# add a path between eth0 and eth1
$RLY paths add $CHAINID_ONE $CHAINID_TWO $PATH_NAME --file=${CONF_DIR}/relayer/path.json

# handshake
set -x
$RLY tx clients $PATH_NAME
$RLY tx update-clients $PATH_NAME
$RLY tx connection $PATH_NAME
$RLY tx channel $PATH_NAME
set +x

