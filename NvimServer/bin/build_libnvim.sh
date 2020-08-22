#!/bin/bash
set -Eeuo pipefail

readonly target=${target:?"x86_64 or arm64"}
readonly build_deps=${build_deps:?"true or false"}

build_libnvim() {
  local -r deployment_target=$1
  local -r target_option=$2

  # Brew's gettext does not get sym-linked to PATH
  export PATH="/usr/local/opt/gettext/bin:${PATH}"

  make \
    SDKROOT="$(xcrun --show-sdk-path)" \
    MACOSX_DEPLOYMENT_TARGET="${deployment_target}" \
    CFLAGS="${target_option}" \
    CXXFLAGS="${target_option}" \
    CMAKE_EXTRA_FLAGS="-DGETTEXT_SOURCE=CUSTOM -DCMAKE_OSX_DEPLOYMENT_TARGET=${deployment_target}" \
    DEPS_CMAKE_FLAGS="-DCMAKE_OSX_DEPLOYMENT_TARGET=${deployment_target} -DCMAKE_CXX_COMPILER=$(xcrun -find c++) -DCMAKE_C_COMPILER_ARG1=${target_option}" \
    CMAKE_BUILD_TYPE=Release \
    libnvim
}

main() {
  # This script is located in /NvimServer/bin and we have to go to /
  pushd "$(dirname "${BASH_SOURCE[0]}")/../.." >/dev/null

  local -r deployment_target=$(cat "./NvimServer/Resources/${target}_deployment_target.txt")
  local -r target_option="--target=${target}-apple-macos${deployment_target}"

  echo "### Building libnvim"
    if "${build_deps}" ; then
      ./NvimServer/bin/build_deps.sh
    fi

    build_libnvim "${deployment_target}" "${target_option}"
  popd >/dev/null
  echo "### Built libnvim"
}

main
