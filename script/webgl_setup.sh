set -e

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 {unity_webgl_support_path}" >&2
  exit 1
fi

webgl_path=$1
dir=`dirname "$webgl_path"`

pushd "$dir" > /dev/null

if [[ -z "$DECLANG_HOME" ]]; then
  HOMEDIR=$HOME
else
  HOMEDIR=$DECLANG_HOME
fi
compiler_path="$HOMEDIR"/.DeClang/compiler

webgl_clang_path="$webgl_path"/BuildTools/Emscripten/llvm

if uname -r | grep -i microsoft > /dev/null; then # WSL2
  # backup bin
  if [[ ! -f "${webgl_clang_path}"/clang.orig.exe ]]; then
    cp "${webgl_clang_path}"/clang.exe "${webgl_clang_path}"/clang.orig.exe
  fi
  if [[ ! -f "${webgl_clang_path}"/clang++.orig.exe ]]; then
    cp "${webgl_clang_path}"/clang++.exe "${webgl_clang_path}"/clang++.orig.exe
  fi
  # copy bin
  cp -v "${compiler_path}"/bin/clang.exe "${webgl_clang_path}"/clang.exe
  cp -v "${compiler_path}"/bin/clang++.exe "${webgl_clang_path}"/clang++.exe

else # MSYS2 and others
  # backup bin
  if [[ ! -f "${webgl_clang_path}"/clang.orig ]]; then
    cp "${webgl_clang_path}"/clang "${webgl_clang_path}"/clang.orig
  fi
  if [[ ! -f "${webgl_clang_path}"/clang++.orig ]]; then
    cp "${webgl_clang_path}"/clang++ "${webgl_clang_path}"/clang++.orig
  fi
  # copy bin
  cp -v "${compiler_path}"/bin/clang "${webgl_clang_path}"/clang
  cp -v "${compiler_path}"/bin/clang++ "${webgl_clang_path}"/clang++

fi

popd >/dev/null
