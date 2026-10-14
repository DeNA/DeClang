set -e

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 {xcodeproj_path}" >&2
  exit 1
fi

project_path=$1

pushd $(dirname $1) > /dev/null

pbxproj=`find . -name "*.pbxproj"`
if [[ -f ${pbxproj}.orig ]]; then
    cp ${pbxproj}.orig ${pbxproj}
    rm ${pbxproj}.orig
fi

popd >/dev/null
