#!/usr/bin/env bash
set -e

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 {unity_webgl_support_path}" >&2
  exit 1
fi

if [[ ! -d "$1" ]]; then
  echo "Error: Unity WebGL support directory not found: $1" >&2
  exit 1
fi

webgl_path="$(cd "$1" && pwd)"
webgl_clang_path="${webgl_path}/BuildTools/Emscripten/llvm"

if [[ ! -d "$webgl_clang_path" ]]; then
  echo "Error: Emscripten llvm directory not found: $webgl_clang_path" >&2
  exit 1
fi

if [[ "_${OS:-}" = "_Windows_NT" ]] || uname -r | grep -iq microsoft; then # MSYS2 or WSL2
  exe_ext=".exe"
else
  exe_ext=""
fi
orig_ext=".orig${exe_ext}"

# restore bin
if [[ -f "${webgl_clang_path}/clang${orig_ext}" ]]; then
  cp -v "${webgl_clang_path}/clang${orig_ext}" "${webgl_clang_path}/clang${exe_ext}"
  rm "${webgl_clang_path}/clang${orig_ext}"
fi
if [[ -f "${webgl_clang_path}/clang++${orig_ext}" ]]; then
  cp -v "${webgl_clang_path}/clang++${orig_ext}" "${webgl_clang_path}/clang++${exe_ext}"
  rm "${webgl_clang_path}/clang++${orig_ext}"
fi
