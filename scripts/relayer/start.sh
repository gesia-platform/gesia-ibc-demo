#!/usr/bin/env bash

set -eu

SCRIPT_DIR=$(cd $(dirname ${BASH_SOURCE:-$0}); pwd)
source ${SCRIPT_DIR}/util.sh

$RLY service start $PATH_NAME &
