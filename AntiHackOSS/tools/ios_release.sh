set -e

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 {version_num}" >&2
  exit 1
fi

#copy declang 
pushd $(dirname $0) > /dev/null
cd ../

rm -rf ./Release/
mkdir -p ./Release/compiler/ios/bin/
mkdir -p ./Release/compiler/ios/lib/

cp -v build/bin/clang++ ./Release/compiler/ios/bin/
cp -v build/bin/clang ./Release/compiler/ios/bin/
cp -r build/lib/clang/ ./Release/compiler/ios/lib/clang/
popd > /dev/null


#copy include files
pushd $(dirname $0) > /dev/null
cd ../
mkdir -p ./Release/compiler/ios/include/llvm/
mkdir -p ./Release/compiler/ios/include/c++/v1/

cp -r build/include/llvm/* ./Release/compiler/ios/include/llvm/
cp -r libcxx/include/* ./Release/compiler/ios/include/c++/v1/
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
cp ../LICENSE-DeClang ./Release/
cp ../LICENSE-ollvm ./Release/
cp ./LICENSE ./Release/
popd > /dev/null

pushd $(dirname $0) > /dev/null
cd ../

mv Release Release-$1
popd > /dev/null
