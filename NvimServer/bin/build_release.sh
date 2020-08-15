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
    CFLAGS="-mmacosx-version-min=${deployment_target}" \
    CXXFLAGS="-mmacosx-version-min=${deployment_target}" \
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

main() {
  echo "### Building release"
  # This script is located in /NvimServer/bin and we have to go to /
  pushd "$(dirname "${BASH_SOURCE[0]}")/../.." >/dev/null

  local -r deployment_target_file="./NvimServer/Resources/macos_deployment_target.txt"
  local -r deployment_target=$(cat ${deployment_target_file})

  if ${clean} ; then
    clean_everything
  fi

  build_runtime ${deployment_target}
  make clean

  build_deps=${clean} ./NvimServer/bin/build_libnvim.sh

  build_nvimserver

  popd >/dev/null
  echo "### Built release"
}

main
