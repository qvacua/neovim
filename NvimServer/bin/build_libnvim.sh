#!/bin/bash
set -Eeuo pipefail

readonly build_deps=${build_deps:?"true or false"}

build_libnvim() {
  local -r deployment_target=$1
  local -r target=$2

  local -r target_option="--target=${target}-apple-macos${deployment_target}"

  # Brew's gettext does not get sym-linked to PATH
  export PATH="/opt/homebrew/opt/gettext/bin:/usr/local/opt/gettext/bin:${PATH}"

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

build_universal_libs() {
  local -r arm64_lib_parent_path=$1
  local -r x86_64_lib_parent_path=$2

  local lib_name
  local x86_64_lib

  for arm64_lib in "${arm64_temp_lib_parent_path}"/*.a ; do
    lib_name="$(basename ${arm64_lib})"
    x86_64_lib="${x86_64_temp_lib_parent_path}/${lib_name}"
    lipo -create -output "./.deps/usr/lib/${lib_name}" "${arm64_lib}" "${x86_64_lib}"
  done
  mv ./.deps/usr/lib/libnvim.a ./build/lib/
}

main() {
  # This script is located in /NvimServer/bin and we have to go to /
  pushd "$(dirname "${BASH_SOURCE[0]}")/../.." >/dev/null


  echo "### Building libnvim"
    if [[ "${build_deps}" == true ]]; then
      ./NvimServer/bin/build_deps.sh
    fi

    local -r temp_lib_parent_path="$(mktemp -d -t 'nvimserver-temp-lib-parent')"
    local target
    local deployment_target

    target="arm64"
    deployment_target=$(cat "./NvimServer/Resources/${target}_deployment_target.txt")
    make distclean
    build_libnvim "${deployment_target}" "${target}"

    local -r arm64_temp_lib_parent_path="${temp_lib_parent_path}/arm64"
    mkdir -p "${arm64_temp_lib_parent_path}"
    mv ./build/lib/libnvim.a "${arm64_temp_lib_parent_path}"
    mv ./.deps/usr/lib/*.a "${arm64_temp_lib_parent_path}"


    target="x86_64"
    deployment_target=$(cat "./NvimServer/Resources/${target}_deployment_target.txt")
    make distclean
    build_libnvim "${deployment_target}" "${target}"

    local -r x86_64_temp_lib_parent_path="${temp_lib_parent_path}/x86_64"
    mkdir -p "${x86_64_temp_lib_parent_path}"
    mv ./build/lib/libnvim.a "${x86_64_temp_lib_parent_path}"
    mv ./.deps/usr/lib/*.a "${x86_64_temp_lib_parent_path}"

    echo "${arm64_temp_lib_parent_path}"
    echo "${x86_64_temp_lib_parent_path}"
    build_universal_libs "${arm64_temp_lib_parent_path}" "${x86_64_temp_lib_parent_path}"

  popd >/dev/null
  echo "### Built libnvim"
}

main
