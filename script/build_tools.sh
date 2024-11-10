set -e

pushd $(dirname $0) > /dev/null

cd -P ../AntiHack/tools/
exec bash build_tools.sh $1

popd > /dev/null
