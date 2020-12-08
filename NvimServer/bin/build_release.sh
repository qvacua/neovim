#!/bin/bash
set -Eeuo pipefail

build_runtime() {
  local -r deployment_target=$1
  local -r nvim_install_path=$2

  echo "#### runtime in ${nvim_install_path}"

  echo "### Building nvim to get the complete runtime"
  make \
    SDKROOT="$(xcrun --show-sdk-path)" \
    MACOSX_DEPLOYMENT_TARGET="${deployment_target}" \
    CMAKE_EXTRA_FLAGS="-DCMAKE_OSX_DEPLOYMENT_TARGET=${deployment_target} -DCMAKE_CXX_COMPILER=$(xcrun -find c++)" \
    DEPS_CMAKE_FLAGS="-DCMAKE_OSX_DEPLOYMENT_TARGET=${deployment_target} -DCMAKE_CXX_COMPILER=$(xcrun -find c++)" \
    CMAKE_FLAGS="-DCUSTOM_UI=0 -DCMAKE_INSTALL_PREFIX=${nvim_install_path}" \
    CMAKE_BUILD_TYPE="Release" \
    install

  echo "#### runtime is installed at ${nvim_install_path}/share/nvim/runtime"
}

download_and_build_universal_nvimserver() {
  local -r working_dir=$1
  local tag; tag=$(cat "./NvimServer/Resources/nvim-version-for-download.txt"); readonly tag

  mkdir -p "${working_dir}"
  pushd "${working_dir}" >/dev/null
    curl -o "NvimServer-x86_64.tar.bz2" -L "https://github.com/qvacua/neovim/releases/download/${tag}/NvimServer-x86_64.tar.bz2"
    curl -o "NvimServer-arm64.tar.bz2" -L "https://github.com/qvacua/neovim/releases/download/${tag}/NvimServer-arm64.tar.bz2"

    tar xf "NvimServer-x86_64.tar.bz2"
    mv NvimServer NvimServer-x86_64

    tar xf "NvimServer-arm64.tar.bz2"
    mv NvimServer NvimServer-arm64

    lipo -create -output NvimServer NvimServer-x86_64 NvimServer-arm64
    echo "Resulting binary is located in $(realpath NvimServer)"
  popd >/dev/null
}

package() {
  local -r nvimserver_build_folder=$1
  local -r nvim_install_path=$2

  local -r nvimserver_exec_path="${nvimserver_build_folder}/NvimServer"

  echo "### Packaging"
  local -r resources_path="./NvimServer/Resources"
  local -r package_name="NvimServer"
  local -r package_dir_path="${nvimserver_build_folder}/package/${package_name}"
  rm -rf "${package_dir_path}" && mkdir -p "${package_dir_path}"

  cp -r "${nvimserver_exec_path}" "${package_dir_path}"
  cp "${resources_path:?}/"* "${package_dir_path}"
  cp -r "${nvim_install_path}/share/nvim/runtime" "${package_dir_path}"

  pushd "${package_dir_path}/.." >/dev/null
    tar jcvf "${package_name}.tar.bz2" ${package_name}
    echo "### Packaged to $(realpath "${package_name}.tar.bz2")"
  popd >/dev/null
}

main() {
  echo "### Building release"
  # This script is located in /NvimServer/bin and we have to go to /
  pushd "$(dirname "${BASH_SOURCE[0]}")/../.." >/dev/null

    local -r nvim_build_dir_path="./build"
    local nvim_install_path; nvim_install_path="$(mktemp -d -t 'nvim-runtime')"
    readonly nvim_install_path
    local -r nvimserver_folder="./NvimServer/build"

    ./NvimServer/bin/clean_all.sh

    # Build only *once* with some target
    local some_deployment_target; some_deployment_target=$(cat "./NvimServer/Resources/arm64_deployment_target.txt")
    readonly some_deployment_target
    build_runtime "${some_deployment_target}" "${nvim_install_path}"

    rm -rf "${nvim_build_dir_path}"
    make distclean

    rm -rf "${nvimserver_folder}"
    download_and_build_universal_nvimserver "${nvimserver_folder}"

    package "${nvimserver_folder}" "${nvim_install_path}"

  popd >/dev/null
  echo "### Built release"
}

main
