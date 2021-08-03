set -e

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 {version_num}" >&2
  exit 1
fi

#copy declang 
pushd $(dirname $0) > /dev/null
cd ../

rm -rf ./Release/
mkdir -p ./Release/compiler/bin/
mkdir -p ./Release/compiler/lib/

cp -v build/bin/clang++ ./Release/compiler/bin/
cp -v build/bin/clang ./Release/compiler/bin/
cp -r build/lib/clang/ ./Release/compiler/lib/clang/
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

# cp -v tools/config/config.pre.json ./Release/
cp -v tools/config/gen_config_* ./Release/
cp -v tools/config/gen_config.sh ./Release/

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
