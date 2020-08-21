#!/bin/bash
set -Eeuo pipefail

readonly target=${1:?"1st argument = target: x86_64 or arm64"}

readonly gettext_version="0.20.1"
readonly gettext_default_cflags="-g -O2"

download_gettext() {
  local -r working_directory=$1

  rm -rf "${working_directory:?}/"gettext*

  pushd "${working_directory}" >/dev/null
    curl -L -o gettext.tar.xz "https://ftp.gnu.org/gnu/gettext/gettext-${gettext_version}.tar.xz"
    tar xf gettext.tar.xz
    mv "gettext-${gettext_version}" gettext
  popd >/dev/null
}

build_gettext() {
  local -r deployment_target=$1
  local -r cflags=$2
  local -r working_directory=$3
  local -r install_path=$4

  echo "### Building gettext"
  pushd "${working_directory}/gettext" >/dev/null
    make distclean || true
    ./configure \
        MACOSX_DEPLOYMENT_TARGET="${deployment_target}" \
        CFLAGS="${cflags}" \
        --disable-dependency-tracking \
        --disable-silent-rules \
        --disable-debug \
        --with-included-gettext \
        --with-included-glib \
        --with-included-libcroco \
        --with-included-libunistring \
        --without-emacs \
        --disable-java \
        --disable-csharp \
        --without-git \
        --without-cvs \
        --without-xz \
        --prefix="${install_path}"
    make MACOSX_DEPLOYMENT_TARGET="${deployment_target}" install
  popd >/dev/null
  echo "### Built gettext"
}

main() {
  echo "### Building deps"
  pushd "$(dirname "${BASH_SOURCE[0]}")/.." >/dev/null
  
  rm -rf "./third-party" && mkdir -p "./third-party"
  local -r install_path="$(realpath ./third-party)"
  local -r working_directory="$(realpath ./third-party/.deps)"

  local -r deployment_target=$(cat "./Resources/${target}_deployment_target.txt")
  local -r target_option="--target=${target}-apple-macos${deployment_target}"

  mkdir -p "${working_directory}"
  download_gettext "${working_directory}"

  build_gettext \
      "${deployment_target}" \
      "${gettext_default_cflags} ${target_option}" \
      "${working_directory}" \
      "${install_path}" \

  popd >/dev/null
  echo "### Built deps"
}

main
