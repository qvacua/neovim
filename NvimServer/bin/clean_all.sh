#!/bin/bash
set -Eeuo pipefail

readonly clean_deps=${clean_deps:-true}

pushd "$(dirname "${BASH_SOURCE[0]}")/../.." >/dev/null
  rm -rf ./build
  rm -rf ./.deps
  make distclean

  if [[ "${clean_deps}" == true ]]; then
    rm -rf ./NvimServer/third-party
    rm -rf ./NvimServer/.deps
    rm -rf ./NvimServer/build
  fi
popd >/dev/null
