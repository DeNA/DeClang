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

HOMEDIR="${DECLANG_HOME:-${HOME:-${USERPROFILE:-}}}"
if [[ -z "$HOMEDIR" ]]; then
  echo "Error: DECLANG_HOME, HOME, or USERPROFILE is not set." >&2
  exit 1
fi
compiler_path="${HOMEDIR}/.DeClang/compiler"
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

src_clang="${compiler_path}/bin/clang${exe_ext}"
src_clangxx="${compiler_path}/bin/clang++${exe_ext}"

if [[ ! -f "$src_clang" || ! -f "$src_clangxx" ]]; then
  echo "Error: DeClang compiler binaries not found under ${compiler_path}/bin" >&2
  exit 1
fi

# backup bin
if [[ ! -f "${webgl_clang_path}/clang${orig_ext}" ]]; then
  cp "${webgl_clang_path}/clang${exe_ext}" "${webgl_clang_path}/clang${orig_ext}"
fi
if [[ ! -f "${webgl_clang_path}/clang++${orig_ext}" ]]; then
  cp "${webgl_clang_path}/clang++${exe_ext}" "${webgl_clang_path}/clang++${orig_ext}"
fi

# copy bin
if [[ -L "${webgl_clang_path}/clang${exe_ext}" ]]; then
  rm -f "${webgl_clang_path}/clang${exe_ext}"
fi
cp -v "$src_clang" "${webgl_clang_path}/clang${exe_ext}"

if [[ -L "${webgl_clang_path}/clang++${exe_ext}" ]]; then
  rm -f "${webgl_clang_path}/clang++${exe_ext}"
fi
cp -v "$src_clangxx" "${webgl_clang_path}/clang++${exe_ext}"
