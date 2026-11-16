#!/usr/bin/env bash
set -e

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 {ndk_path}" >&2
  exit 1
fi

if [[ ! -d "$1" ]]; then
  echo "Error: NDK directory not found: $1" >&2
  exit 1
fi

ndk_path="$(cd "$1" && pwd)"

if [[ "_${OS:-}" = "_Windows_NT" ]] || uname -r | grep -iq microsoft; then # MSYS2 or WSL2
  exe_ext=".exe"
  ndk_clang_candidates="$(find "$ndk_path" -type f -name "clang++.exe")"
else
  exe_ext=""
  # Keep -type f omitted so macOS universal binaries / symlinks are matched (PR #24)
  ndk_clang_candidates="$(find "$ndk_path" -name "clang++")"
fi
orig_ext=".orig${exe_ext}"

ndk_clang_path="$(echo "$ndk_clang_candidates" | grep "/bin/clang++${exe_ext}$" | head -n 1 || true)"
if [[ -z "$ndk_clang_path" ]]; then
  ndk_clang_path="$(echo "$ndk_clang_candidates" | head -n 1)"
fi

if [[ -z "$ndk_clang_path" ]]; then
  echo "Error: Could not find clang++${exe_ext} under $ndk_path" >&2
  exit 1
fi

darwin_path="$(dirname "$(dirname "$ndk_clang_path")")"

# restore bin
if [[ -f "${darwin_path}/bin/clang${orig_ext}" ]]; then
  cp -v "${darwin_path}/bin/clang${orig_ext}" "${darwin_path}/bin/clang${exe_ext}"
  rm "${darwin_path}/bin/clang${orig_ext}"
fi
if [[ -f "${darwin_path}/bin/clang++${orig_ext}" ]]; then
  cp -v "${darwin_path}/bin/clang++${orig_ext}" "${darwin_path}/bin/clang++${exe_ext}"
  rm "${darwin_path}/bin/clang++${orig_ext}"
fi

# restore lib
if [[ -d "${darwin_path}/lib.orig" ]]; then
  rm -rf "${darwin_path}/lib"
  mv "${darwin_path}/lib.orig" "${darwin_path}/lib"
fi
