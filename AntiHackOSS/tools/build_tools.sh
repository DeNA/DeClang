set -e

#build gen_config
pushd $(dirname $0) > /dev/null

cd config/
bash build.sh $1
popd > /dev/null

