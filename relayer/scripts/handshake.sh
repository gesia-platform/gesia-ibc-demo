#!/usr/bin/env bash

set -eu

source /util.sh

rm -rf ${RELAYER_CONF} &> /dev/null

sleep 5

${RLY} config init
${RLY} chains add-dir /configs/${PATH_NAME}/chains

$RLY paths add $CHAINID_ONE $CHAINID_TWO $PATH_NAME --file=/configs/${PATH_NAME}/path.json

sleep 5

# handshake
set -x
$RLY tx clients $PATH_NAME
$RLY tx update-clients $PATH_NAME
$RLY tx connection $PATH_NAME
$RLY tx channel $PATH_NAME
set +x