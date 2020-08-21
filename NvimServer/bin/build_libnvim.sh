#!/bin/bash
set -Eeuo pipefail

readonly build_deps=${build_deps:-true}

build_libnvim() {
  if ${build_deps}; then
    build_gettext=true ./NvimServer/bin/build_deps.sh
  fi

  ln -f -s ./NvimServer/local.mk local.mk

  local -r deployment_target=$(cat "./NvimServer/Resources/x86_64_deployment_target.txt")

  # Brew's gettext does not get sym-linked to PATH
  export PATH="/usr/local/opt/gettext/bin:${PATH}"

  make \
    SDKROOT="$(xcrun --show-sdk-path)" \
    MACOSX_DEPLOYMENT_TARGET="${deployment_target}" \
    CMAKE_EXTRA_FLAGS="-DGETTEXT_SOURCE=CUSTOM -DCMAKE_OSX_DEPLOYMENT_TARGET=${deployment_target} -DCMAKE_CXX_COMPILER=$(xcrun -find c++)" \
    DEPS_CMAKE_FLAGS="-DCMAKE_OSX_DEPLOYMENT_TARGET=${deployment_target} -DCMAKE_CXX_COMPILER=$(xcrun -find c++)" \
    CMAKE_BUILD_TYPE=Release \
    libnvim
}

main() {
  echo "### Building libnvim"

  # This script is located in /NvimServer/bin and we have to go to /
  pushd "$(dirname "${BASH_SOURCE[0]}")/../.." >/dev/null

  build_libnvim

  popd >/dev/null
  echo "### Built libnvim"
}

main
