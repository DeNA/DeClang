set -e

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 {version_num}" >&2
  exit 1
fi

#copy declang 
pushd $(dirname $0) > /dev/null
cd ../

rm -rf ./Release/
rm -rf ./Release-$1/
mkdir -p ./Release/compiler/bin/
mkdir -p ./Release/compiler/lib/

if [[ "_$OS" = "_Windows_NT" ]]; then
  cp -v build/Release/bin/clang++ ./Release/compiler/bin/
  cp -v build/Release/bin/clang ./Release/compiler/bin/
  cp -v build/Release/bin/clang-cl ./Release/compiler/bin/
  cp -r build/Release/lib/clang/ ./Release/compiler/lib/clang/
else
  cp -v build/bin/clang++ ./Release/compiler/bin/
  cp -v build/bin/clang ./Release/compiler/bin/
  cp -r build/lib/clang/ ./Release/compiler/lib/clang/
fi
popd > /dev/null


#copy include files
pushd $(dirname $0) > /dev/null
cd ../
mkdir -p ./Release/compiler/include/llvm/
mkdir -p ./Release/compiler/include/c++/v1/

cp -r build/include/llvm/* ./Release/compiler/include/llvm/
cp -r libcxx/include/* ./Release/compiler/include/c++/v1/
popd > /dev/null

pushd $(dirname $0) > /dev/null
cd ../

mkdir -p ./Release/gen_config/bin/macOS/Intel
mkdir -p ./Release/gen_config/bin/macOS/AppleSilicon
mkdir -p ./Release/gen_config/bin/Windows
mkdir -p ./Release/gen_config/bin/Linux

cp -v tools/config/gen_config_mac_intel ./Release/gen_config/bin/macOS/Intel/gen_config
cp -v tools/config/gen_config_mac_applesilicon ./Release/gen_config/bin/macOS/AppleSilicon/gen_config
cp -v tools/config/gen_config_linux ./Release//gen_config/bin/Linux/gen_config
cp -v tools/config/gen_config_windows.exe ./Release/gen_config/bin/Windows/gen_config.exe
cp -v tools/config/gen_config.sh ./Release/gen_config.sh

cp -v tools/config/config.pre.json ./Release/config.pre.json

mkdir -p ./Release/script/
cp -v script/*setup.sh ./Release/script/
cp -v script/*unset.sh ./Release/script/
popd > /dev/null

# copy license
pushd $(dirname $0) > /dev/null
cd ..
cp ./AntiHackOSS/LICENSE-DeClang ./Release/
cp ./AntiHackOSS/LICENSE-ollvm ./Release/
cp ./LICENSE.txt ./Release/
popd > /dev/null

pushd $(dirname $0) > /dev/null
cd ../

mv Release Release-$1
popd > /dev/null
