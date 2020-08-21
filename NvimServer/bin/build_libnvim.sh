#!/bin/bash
set -Eeuo pipefail

readonly build_deps=${build_deps:-true}

build_libnvim() {
  local -r deployment_target=$1

  ln -f -s ./NvimServer/local.mk local.mk

  # Brew's gettext does not get sym-linked to PATH
  export PATH="/usr/local/opt/gettext/bin:${PATH}"

  make \
    SDKROOT="$(xcrun --show-sdk-path)" \
    MACOSX_DEPLOYMENT_TARGET="${deployment_target}" \
    CMAKE_EXTRA_FLAGS="-DGETTEXT_SOURCE=CUSTOM -DCMAKE_OSX_DEPLOYMENT_TARGET=${deployment_target} -DCMAKE_CXX_COMPILER=$(xcrun -find c++)" \
    DEPS_CMAKE_FLAGS="-DCMAKE_OSX_DEPLOYMENT_TARGET=${x86_64_deployment_target} -DCMAKE_CXX_COMPILER=$(xcrun -find c++)" \
    CMAKE_BUILD_TYPE=Release \
    libnvim
}

main() {
  echo "### Building libnvim"
  # This script is located in /NvimServer/bin and we have to go to /
  pushd "$(dirname "${BASH_SOURCE[0]}")/../.." >/dev/null

    local -r x86_64_deployment_target=$(cat "./NvimServer/Resources/x86_64_deployment_target.txt")
    local -r arm64_deployment_target=$(cat "./NvimServer/Resources/arm64_deployment_target.txt")
    local -r x86_64_target="x86_64-apple-macos${x86_64_deployment_target}"
    local -r arm64_target="arm64-apple-macos${arm64_deployment_target}"

    if ${build_deps} ; then
      build_gettext=true ./NvimServer/bin/build_deps.sh
    fi

    build_libnvim "${x86_64_deployment_target}"

  popd >/dev/null
  echo "### Built libnvim"
}

main
