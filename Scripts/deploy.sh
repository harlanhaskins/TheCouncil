SCRIPTS_DIR_PATH=$(dirname $(realpath -s $0))
PACKAGE_PATH="$(dirname "$SCRIPTS_DIR_PATH")/Server"
WEB_PATH="$(dirname "$SCRIPTS_DIR_PATH")/Web"

set -x

swift build -c release --package-path "$PACKAGE_PATH"

if [[ $? -ne 0 ]]; then
  echo "Build failed; not deploying"
  exit -1
else
  echo "Build succeeded; building web site"
fi

pushd "$WEB_PATH"
bun run build
popd

sudo service council restart