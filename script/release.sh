set -e

pushd $(dirname $0) > /dev/null

cd ../AntiHack/tools/
exec bash release.sh $1

popd > /dev/null
