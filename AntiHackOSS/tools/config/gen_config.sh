#!/bin/bash

set -e

BASE=$(dirname "$0")
SCRIPT_DIR=$(cd "$BASE"; pwd)
os=$(uname -s)
if [ $os = "Darwin" ]; then
  "${SCRIPT_DIR}/gen_config_mac" "$@"
elif [[ "_$OS" = "_Windows_NT" ]]; then
  "${SCRIPT_DIR}/gen_config_windows" "$@"
else
  "${SCRIPT_DIR}/gen_config_linux" "$@"
fi
