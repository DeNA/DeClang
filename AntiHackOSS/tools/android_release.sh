set -e

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 {version_num}" >&2
  exit 1
fi

#copy declang 
pushd $(dirname $0) > /dev/null
cd ../

rm -rf ./Release/
mkdir -p ./Release/compiler/android/bin/
mkdir -p ./Release/compiler/android/lib/

if [[ "_$OS" = "_Windows_NT" ]]; then
  cp -v build/Release/bin/clang++ ./Release/compiler/android/bin/
  cp -v build/Release/bin/clang ./Release/compiler/android/bin/
  cp -r build/Release/lib/clang/ ./Release/compiler/android/lib/clang/
else
  cp -v build/bin/clang++ ./Release/compiler/android/bin/
  cp -v build/bin/clang ./Release/compiler/android/bin/
  cp -r build/lib/clang/ ./Release/compiler/android/lib/clang/
fi

popd > /dev/null

# copy helper tools etc.
pushd $(dirname $0) > /dev/null
cd ../

cp -v tools/config/config.pre.json ./Release/
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
popd > /dev/null

pushd $(dirname $0) > /dev/null
cd ../

mv Release Release-$1
popd > /dev/null
