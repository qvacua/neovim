#!/bin/bash
set -Eeuo pipefail

readonly build_libnvim=${build_libnvim:?"true or false"}
readonly build_deps=${build_deps:?"true or false"}
readonly build_dir=${build_dir:?"where to put the resuling binary"}

main() {
  echo "### Building libnvim"
  # This script is located in /NvimServer/bin and we have to go to /
  pushd "$(dirname "${BASH_SOURCE[0]}")/../.." >/dev/null
    mkdir -p "${build_dir}"

    if "${build_libnvim}" ; then
      ./NvimServer/bin/build_libnvim.sh
    fi

    xcodebuild -derivedDataPath "${build_dir}" -configuration Release -scheme NvimServer build

  popd >/dev/null
  echo "### Built libnvim"
}

main
