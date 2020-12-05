#!/bin/bash
set -Eeuo pipefail

declare -x target; target="$(uname -m)"; readonly target
declare -r -x download_gettext=${download_gettext:?"true or falce"}
declare -r -x clean=${clean:?"if true, will clean libnvim and nvimserver"}
readonly build_libnvim=${build_libnvim:?"true or false"}
readonly build_dir=${build_dir:-"./build"}

package() {
  local -r build_folder_path=$1
  pushd "${build_folder_path}" >/dev/null
    tar cjf "NvimServer-${target}.tar.bz2" NvimServer
    echo "Packaged NvimServer for ${target} to $(realpath "NvimServer-${target}.tar.bz2")"
  popd >/dev/null
}

main() {
  echo "### Building NvimServer"
  # This script is located in /NvimServer/bin and we have to go to /
  pushd "$(dirname "${BASH_SOURCE[0]}")/../.." >/dev/null
    if [[ "${build_libnvim}" == true ]]; then
      ./NvimServer/bin/build_libnvim.sh
    fi

    if [[ "${clean}" == true ]]; then
      xcodebuild -derivedDataPath "${build_dir}" -configuration Release -scheme NvimServer ARCHS="${target}" clean
    fi

    xcodebuild -derivedDataPath "${build_dir}" -configuration Release -scheme NvimServer ARCHS="${target}" build

    package "${build_dir}/Build/Products/Release"

  popd >/dev/null
  echo "### Built NvimServer"
}

main
