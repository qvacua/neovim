#!/bin/bash
set -Eeuo pipefail

declare target; target="$(uname -m)"; readonly target
readonly download_gettext=${download_gettext:?"true or falce"}
readonly clean=${clean:?"if true, will clean libnvim and nvimserver"}
readonly build_libnvim=${build_libnvim:?"true or false"}
readonly build_dir=${build_dir:-"./build"}

main() {
  echo "### Building libnvim"
  # This script is located in /NvimServer/bin and we have to go to /
  pushd "$(dirname "${BASH_SOURCE[0]}")/../.." >/dev/null
    if [[ "${build_libnvim}" == true ]]; then
      ./NvimServer/bin/build_libnvim.sh
    fi

    if [[ "${clean}" == true ]]; then
      xcodebuild -derivedDataPath "${build_dir}" -configuration Release -scheme NvimServer ARCHS="${target}" clean
    fi

    xcodebuild -derivedDataPath "${build_dir}" -configuration Release -scheme NvimServer ARCHS="${target}" build

  popd >/dev/null
  echo "### Built libnvim"
}

main
