set -e

pushd $(dirname $0) > /dev/null

cd ../tools/
exec bash ios_release.sh $1

popd > /dev/null
