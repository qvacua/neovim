#!/bin/bash
set -Eeuo pipefail

readonly clean=${clean:?"true or false"}
readonly download_gettext=${download_gettext:?"true or false"}
declare target; target="$(uname -m)"; readonly target

download_gettext() {
  local tag; tag=$(cat "./NvimServer/Resources/nvim-version-for-gettext.txt"); readonly tag
  local -r archive_folder="./NvimServer/build"
  rm -rf "${archive_folder}" && mkdir -p ${archive_folder}

  local -r archive_file_name="gettext-${target}.tar.bz2"
  local -r archive_file_path="${archive_folder}/${archive_file_name}"

  curl -o "${archive_file_path}" -L "https://github.com/qvacua/neovim/releases/download/${tag}/gettext-${target}.tar.bz2"

  pushd "${archive_folder}" >/dev/null
    tar xf "${archive_file_name}"
  popd >/dev/null

  local -r third_party_folder="./NvimServer/third-party"
  rm -rf "${third_party_folder}" && mkdir -p "${third_party_folder}"

  mv "${archive_folder}/lib" "${third_party_folder}"
  mv "${archive_folder}/include" "${third_party_folder}"
}

build_libnvim() {
  local -r deployment_target=$1

  # Brew's gettext does not get sym-linked to PATH
  export PATH="/opt/homebrew/opt/gettext/bin:/usr/local/opt/gettext/bin:${PATH}"
  ln -sf ./NvimServer/local.mk local.mk

  make \
    SDKROOT="$(xcrun --show-sdk-path)" \
    MACOSX_DEPLOYMENT_TARGET="${deployment_target}" \
    CMAKE_EXTRA_FLAGS="-DGETTEXT_SOURCE=CUSTOM -DCMAKE_OSX_DEPLOYMENT_TARGET=${deployment_target}" \
    DEPS_CMAKE_FLAGS="-DCMAKE_OSX_DEPLOYMENT_TARGET=${deployment_target} -DCMAKE_CXX_COMPILER=$(xcrun -find c++)" \
    CMAKE_FLAGS="-DCUSTOM_UI=1 -DFEAT_TUI=0" \
    CMAKE_BUILD_TYPE="Release" \
    libnvim
}

main() {
  # This script is located in /NvimServer/bin and we have to go to /
  pushd "$(dirname "${BASH_SOURCE[0]}")/../.." >/dev/null

  if [[ "${download_gettext}" == true ]]; then
    download_gettext
  fi

  echo "### Building libnvim"
  local deployment_target
  deployment_target=$(cat "./NvimServer/Resources/${target}_deployment_target.txt")
  readonly deployment_target

  if [[ "${clean}" == true ]]; then
    make distclean
  fi

  build_libnvim "${deployment_target}"

  popd >/dev/null
  echo "### Built libnvim"
}

main
