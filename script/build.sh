set -e

POSITIONAL=()
while [[ $# -gt 0 ]]
do
key="$1"

case $key in
    -a|--arch)
    build_arch="$2"
    shift # past argument
    shift # past value
    ;;
    -h|--help)
    echo "Usage: $0 -a {\"arm64;x86_64\"} " >&2
    exit
    shift # past argument
    ;;
    *)    # unknown option
    POSITIONAL+=("$1") # save it in an array for later
    shift # past argument
    ;;
esac
done
set -- "${POSITIONAL[@]}" # restore positional parameters

if [[ $build_arch == "" ]]; then
  build_arch="x86_64"
fi

pushd $(dirname $0) > /dev/null

cd ../

rm -f clang/lib/Driver/DeClangExtraProcess.cpp
rm -rf llvm/lib/Transforms/AntiHack
rm -rf llvm/include/llvm/Transforms/AntiHack
rm -rf tools

if [[ -e AntiHackDeNA ]]; then
  ln -s ../../../AntiHackDeNA/clang/DeClangExtraProcess.cpp clang/lib/Driver/DeClangExtraProcess.cpp
  ln -s ../../../AntiHackDeNA/src llvm/lib/Transforms/AntiHack
  ln -s ../../../../AntiHackDeNA/include llvm/include/llvm/Transforms/AntiHack
  ln -s AntiHackDeNA/tools tools
  bash tools/script/gen_dummy_files.sh
else
  ln -s ../../../AntiHackOSS/clang/DeClangExtraProcess.cpp clang/lib/Driver/DeClangExtraProcess.cpp
  ln -s ../../../AntiHackOSS/src llvm/lib/Transforms/AntiHack
  ln -s ../../../../AntiHackOSS/include llvm/include/llvm/Transforms/AntiHack
  ln -s AntiHackOSS/tools tools
fi

if [[ $# -eq 1 && $1 == "toolchain" ]]; then
  echo "build toolchain"
  cd ../
  SKIP_XCODE_VERSION_CHECK=1 ./swift/utils/build-toolchain jp.dena --use-os-runtime
  # popd > /dev/null
  # pushd $(dirname $0) > /dev/null
  # cd ../
  # ln -s build ../build/buildbot_osx/llvm-macosx-x86_64/
  # popd > /dev/null
else
  mkdir -p build/
  cd build/
  if [[ ! -e Makefile ]]; then
    use_ccache="false"
    if [ $(which ccache) ]; then
      use_ccache="true"
    fi

    if [[ "_$OS" = "_Windows_NT" ]]; then
      cmake \
        -DCMAKE_BUILD_TYPE=Release \
        -DLLVM_ENABLE_DUMP=ON \
        -DLLVM_ENABLE_ZSTD=OFF \
        -DLLVM_INCLUDE_BENCHMARKS=OFF \
        -DLLVM_INCLUDE_EXAMPLES=OFF \
        -DLLVM_INCLUDE_TESTS=OFF \
        -DLLVM_ENABLE_PROJECTS="clang;libcxx;libcxxabi" \
        -DCLANG_DEFAULT_RTLIB="libgcc" \
        -DLLVM_CCACHE_BUILD=${use_ccache}\
        -DLLVM_USE_CRT_RELEASE=MT \
        -DLLVM_USE_CRT_RELWITHDEBINFO=MT \
        -A x64\
        -Thost=x64\
          -G "Visual Studio 17 2022" ../llvm

    else
      echo "Build for $build_arch"
      cmake \
        -DLLVM_ENABLE_DUMP=ON \
        -DLLVM_ENABLE_ZSTD=OFF \
        -DLLVM_INCLUDE_BENCHMARKS=OFF \
        -DLLVM_INCLUDE_EXAMPLES=OFF \
        -DLLVM_INCLUDE_TESTS=OFF \
        -DCMAKE_BUILD_TYPE=Release \
        -DLLVM_ENABLE_PROJECTS="clang" \
        -DLLVM_ENABLE_RUNTIMES="libcxx;libcxxabi" \
        -DCLANG_DEFAULT_RTLIB="libgcc" \
        -DCMAKE_OSX_ARCHITECTURES="$build_arch" \
        -DLLVM_CCACHE_BUILD=${use_ccache} \
          -G "Unix Makefiles" ../llvm
    fi

  fi

# -DLLVM_EXPERIMENTAL_TARGETS_TO_BUILD="AARCH64;X64" \

  if [[ "_$OS" = "_Windows_NT" ]]; then
    echo "Build Release x64 in Visual Studio"
    cmd /c '"C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvars64.bat" && msbuild  /p:Configuration=Release;Platform=x64 tools\clang\tools\driver\clang.vcxproj'
  else
   make llvm-headers
   make -j 16
  fi
fi
 
popd > /dev/null
