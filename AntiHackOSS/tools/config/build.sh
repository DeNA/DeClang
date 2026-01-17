set -e

pushd $(dirname $0) > /dev/null

make $1

popd > /dev/null
