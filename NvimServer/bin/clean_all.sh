#!/bin/bash
set -Eeuo pipefail

pushd "$(dirname "${BASH_SOURCE[0]}")/../.." >/dev/null
  rm -rf ./build
  rm -rf ./.deps
  make distclean

  rm -rf ./NvimServer/third-party
  rm -rf ./NvimServer/.deps
  rm -rf ./NvimServer/build
popd >/dev/null
