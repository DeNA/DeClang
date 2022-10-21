#!/bin/bash

set -e

BASE=$(dirname "$0")
SCRIPT_DIR=$(cd "$BASE"; pwd)
os=$(uname -s)

if [ $os = "Darwin" ]; then
  if uname -a | grep x86_64 > /dev/null; then
    "${SCRIPT_DIR}/gen_config/bin/macOS/Intel/gen_config" "$@"
  else
    "${SCRIPT_DIR}/gen_config/bin/macOS/AppleSilicon/gen_config" "$@"
  fi
elif [[ "_$OS" = "_Windows_NT" ]]; then
  "${SCRIPT_DIR}/gen_config/bin/Windows/gen_config.exe" "$@"
else
  "${SCRIPT_DIR}/gen_config/bin/Linux/gen_config" "$@"
fi
