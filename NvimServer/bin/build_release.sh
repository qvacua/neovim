#!/bin/bash
set -Eeuo pipefail

readonly clean=${clean:-true}
readonly build_dir_name="build"
readonly build_dir_path="./${build_dir_name}"

clean_everything() {
  rm -rf build
  make distclean

  xcodebuild -derivedDataPath ${build_dir_path} -configuration Release -scheme NvimServer clean
}

build_runtime() {
  local -r deployment_target=$1
  local -r install_path=$(mktemp -d -t 'nvim-runtime')

  echo "#### runtime in ${install_path}"

  ln -f -s ./NvimServer/local.mk .

  echo "### Building nvim to get the complete runtime"
  make \
    SDKROOT=$(xcrun --show-sdk-path) \
    MACOSX_DEPLOYMENT_TARGET=${deployment_target} \
    CMAKE_EXTRA_FLAGS="-DGETTEXT_SOURCE=CUSTOM -DCMAKE_OSX_DEPLOYMENT_TARGET=${deployment_target} -DCMAKE_CXX_COMPILER=$(xcrun -find c++)" \
    DEPS_CMAKE_FLAGS="-DCMAKE_OSX_DEPLOYMENT_TARGET=${deployment_target} -DCMAKE_CXX_COMPILER=$(xcrun -find c++)" \
    CMAKE_FLAGS="-DCUSTOM_UI=0 -DCMAKE_INSTALL_PREFIX=${install_path}" \
    install

  mkdir -p ${build_dir_path}
  rm -rf "${build_dir_path}/runtime"
  cp -r ${install_path}/share/nvim/runtime "${build_dir_path}/runtime"
}

build_nvimserver() {
  xcodebuild -derivedDataPath ${build_dir_path} -configuration Release -scheme NvimServer build
}

package() {
  echo "### Packaging"
  local -r runtime_path=$1
  local -r nvimserver_path=$2
  local -r resources_path=./NvimServer/Resources
  local -r sources_path=./NvimServer/Sources
  local -r package_name="NvimServer"
  local -r package_dir_path="${build_dir_path}/${package_name}"

  rm -rf ${package_dir_path}
  mkdir -p ${package_dir_path}
  cp -r ${runtime_path} ${package_dir_path}
  cp -r ${nvimserver_path} ${package_dir_path}
  cp ${resources_path}/* ${package_dir_path}
  cp "${sources_path}/foundation_shim.h" ${package_dir_path}
  cp "${sources_path}/server_shared_types.h" ${package_dir_path}

  pushd ${build_dir_path} >/dev/null
  tar jcvf "${package_name}.tar.bz2" ${package_name}

  echo "### Packaged to ${build_dir_path}/${package_name}.tar.bz2"
  popd >/dev/null
}

main() {
  echo "### Building release"
  # This script is located in /NvimServer/bin and we have to go to /
  pushd "$(dirname "${BASH_SOURCE[0]}")/../.." >/dev/null

  local -r deployment_target_file="./NvimServer/Resources/macos_deployment_target.txt"
  local -r deployment_target=$(cat ${deployment_target_file})

  if ${clean} ; then
    clean_everything
  fi

  rm -rf ${build_dir_path}
  make clean
  build_runtime ${deployment_target}

  rm -rf ${build_dir_path}
  make clean
  build_deps=${clean} ./NvimServer/bin/build_libnvim.sh

  build_nvimserver

  package "${build_dir_path}/runtime" "${build_dir_path}/Build/Products/Release/NvimServer"

  popd >/dev/null
  echo "### Built release"
}

main
