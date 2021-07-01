set -e

POSITIONAL=()
while [[ $# -gt 0 ]]
do
key="$1"

case $key in
    -x|--xcode-appdir)
    xcode_app_dir="$2"
    shift # past argument
    shift # past value
    ;;
    -p|--xcodeproj)
    xcode_project_path="$2"
    shift # past argument
    shift # past value
    ;;
    -h|--help)
    echo "Usage: $0 -x {xcode_app_dir} -p {xcode_project_path}" >&2
    exit
    shift # past argument
    ;;
    *)    # unknown option
    POSITIONAL+=("$1") # save it in an array for later
    shift # past argument
    ;;
esac
done
set -- "${POSITIONAL[@]}" # restore positional parameters


if [[ $xcode_app_dir = "" ]]
then
  xcode_app_dir="/Applications/Xcode.app/"
fi
echo xcode_app_dir = $xcode_app_dir
echo xcode_project_path = $xcode_project_path

# $pwd=`pwd`
# pushd $(dirname $pwd) > /dev/null

xcode_clang_path="$xcode_app_dir/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/clang/"
xcode_lib_path=`find "$xcode_clang_path" -d -name "darwin"`

pbxproj=`find $xcode_project_path -name "*.pbxproj"`

if [[ ! -f ${pbxproj}.orig ]]; then
    cp $pbxproj ${pbxproj}.orig
fi


echo modifying $pbxproj
# sed -i '' $'s~COMPILER_INDEX_STORE_ENABLE = YES;~COMPILER_INDEX_STORE_ENABLE = NO;\\\n{CC_placeholder}\\\n{CXX_placeholder}~g' "$pbxproj"
# sed -i '' "s~{CC_placeholder}~CC = ${clang_8};~g" "$pbxproj"
# sed -i '' "s~{CXX_placeholder}~CPLUSPLUS = ${clang_8};~g" "$pbxproj"

perl -i -pe 'BEGIN{undef $/;} s~(OTHER_LDFLAGS = \(.*?)\);~$1"-L{/path/to/xcode_lib_path}",\n"-lclang_rt.ios",\n"-lc++",\n);~smg' "$pbxproj"
sed -i '' "s~{/path/to/xcode_lib_path}~${xcode_lib_path}~g" "$pbxproj"

if [[ -z "$DECLANG_HOME" ]]; then
  HOMEDIR=$HOME
else
  HOMEDIR=$DECLANG_HOME
fi

DECLANG=$HOMEDIR/.DeClang/compiler/bin/clang
DECLANGXX=$HOMEDIR/.DeClang/compiler/bin/clang++
sed -i '' $"s~buildSettings = {~buildSettings = {\\
CC = \"${DECLANG}\";\\
CPLUSPLUS = \"${DECLANGXX}\";\\
LD = \"${DECLANG}\";\\
LDPLUSPLUS = \"${DECLANGXX}\";\\
COMPILER_INDEX_STORE_ENABLE = NO;\\
~g" "$pbxproj"
sed -i '' $'s~COMPILER_INDEX_STORE_ENABLE = YES;~COMPILER_INDEX_STORE_ENABLE = NO;~g' "$pbxproj"
sed -i '' $'s~COMPILER_INDEX_STORE_ENABLE = DEFAULT;~COMPILER_INDEX_STORE_ENABLE = NO;~g' "$pbxproj"
sed -i '' $'s~CLANG_ENABLE_MODULES = YES;~CLANG_ENABLE_MODULES = NO;~g' "$pbxproj"

# popd >/dev/null
