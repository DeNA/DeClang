set -e

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 {ndk_path}" >&2
  exit 1
fi

ndk_path=$1
dir=`dirname "$ndk_path"`

pushd "$dir" > /dev/null

if [ "_$OS" = "_Windows_NT" ]; then # MSYS2
  ndk_clang_path=`find "$ndk_path" -type f -name "clang++.exe"`
elif uname -r | grep -i microsoft > /dev/null; then # WSL2
  ndk_clang_path=`find "$ndk_path" -type f -name "clang++.exe"`
else
  ndk_clang_path=`find "$ndk_path" -name "clang++"`
fi

darwin_path=`dirname "$ndk_clang_path"`
darwin_path=`dirname "$darwin_path"`

if uname -r | grep -i microsoft > /dev/null; then # WSL2
  # restore bin
  if [[ -f "${darwin_path}"/bin/clang.orig.exe ]]; then
    cp -v "${darwin_path}"/bin/clang.orig.exe "${darwin_path}"/bin/clang.exe
    rm "${darwin_path}"/bin/clang.orig.exe
  fi
  if [[ -f "${darwin_path}"/bin/clang++.orig.exe ]]; then
    cp -v "${darwin_path}"/bin/clang++.orig.exe "${darwin_path}"/bin/clang++.exe
    rm "${darwin_path}"/bin/clang++.orig.exe
  fi

else
  # restore bin
  if [[ -f "${darwin_path}"/bin/clang.orig ]]; then
    cp -v "${darwin_path}"/bin/clang.orig "${darwin_path}"/bin/clang
    rm "${darwin_path}"/bin/clang.orig
  fi
  if [[ -f "${darwin_path}"/bin/clang++.orig ]]; then
    cp -v "${darwin_path}"/bin/clang++.orig "${darwin_path}"/bin/clang++
    rm "${darwin_path}"/bin/clang++.orig
  fi
fi

# restore lib
if [[ -d "${darwin_path}"/lib.orig ]]; then
  rm -rf "${darwin_path}"/lib/
  mv "${darwin_path}"/lib.orig "${darwin_path}"/lib
fi

popd >/dev/null
