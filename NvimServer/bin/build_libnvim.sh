#!/bin/bash
set -Eeuo pipefail

readonly build_deps=${build_deps:-true}

build_libnvim() {
  if ${build_deps}; then
    build_gettext=true ./NvimServer/bin/build_deps.sh
  fi

  ln -f -s ./NvimServer/local.mk local.mk

  local -r deployment_target_file="./NvimServer/Resources/macos_deployment_target.txt"
  local -r deployment_target=$(cat ${deployment_target_file})

  # Brew's gettext does not get sym-linked to PATH
  export PATH=/usr/local/opt/gettext/bin:$PATH

  # Use custom gettext source only when building libnvim => not in local.mk which is also used to build the full nvim
  # to get the full runtime.
  make \
    SDKROOT=$(xcrun --show-sdk-path) \
    CFLAGS="-mmacosx-version-min=${deployment_target}" \
    CXXFLAGS="-mmacosx-version-min=${deployment_target}" \
    MACOSX_DEPLOYMENT_TARGET=${deployment_target} \
    CMAKE_EXTRA_FLAGS="-DGETTEXT_SOURCE=CUSTOM -DCMAKE_OSX_DEPLOYMENT_TARGET=${deployment_target} -DCMAKE_CXX_COMPILER=$(xcrun -find c++)" \
    DEPS_CMAKE_FLAGS="-DCMAKE_OSX_DEPLOYMENT_TARGET=${deployment_target} -DCMAKE_CXX_COMPILER=$(xcrun -find c++)" \
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

