#!/bin/bash
set -Eeuo pipefail

readonly gettext_version="0.20.1"
declare target; target="$(uname -m)"; readonly target

download_gettext() {
  local -r working_directory=$1

  rm -rf "${working_directory:?}/"gettext*

  pushd "${working_directory}" >/dev/null
    curl -L -o gettext.tar.xz "https://ftp.gnu.org/gnu/gettext/gettext-${gettext_version}.tar.xz"
  popd >/dev/null
}

extract_gettext() {
  local -r working_directory=$1

  pushd "${working_directory}" >/dev/null
    tar xf gettext.tar.xz
    mv "gettext-${gettext_version}" "gettext-${target}"
  popd >/dev/null
}

build_gettext() {
  local -r deployment_target=$1
  local -r working_directory=$2
  local -r install_path=$3

  echo "### Building gettext"
  pushd "${working_directory}/gettext-${target}" >/dev/null
    make distclean || true
    ./configure \
        MACOSX_DEPLOYMENT_TARGET="${deployment_target}" \
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

package() {
  local -r install_path=$1

  pushd "${install_path}" >/dev/null
    tar cjf "gettext-${target}.tar.bz2" include lib
    echo "Packaged gettext for ${target} at $(realpath "gettext-${target}.tar.bz2")"
  popd >/dev/null
}

main() {
  echo "### Building deps"
  pushd "$(dirname "${BASH_SOURCE[0]}")/.." >/dev/null

  rm -rf "./third-party" && mkdir -p "./third-party"
  local -r install_path="$(realpath ./third-party)"

  local working_directory; working_directory="$(realpath ./third-party/.deps)"
  readonly working_directory
  mkdir -p "${working_directory}"
  download_gettext "${working_directory}"

  local deployment_target; deployment_target=$(cat "./Resources/${target}_deployment_target.txt")
  readonly deployment_target

  extract_gettext "${working_directory}"
  build_gettext \
      "${deployment_target}" \
      "${working_directory}" \
      "${install_path}"

  package "${install_path}"

  popd >/dev/null
  echo "### Built deps"
}

main
