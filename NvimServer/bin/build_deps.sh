#!/bin/bash
set -Eeuo pipefail

readonly gettext_version="0.20.1"
readonly gettext_default_cflags="-g -O2"
readonly target=${target:?"arm64 or x86_64: you can only build the same target as your machine"}

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
  local -r cflags=$2
  local -r working_directory=$3
  local -r install_path=$4

  echo "### Building gettext"
  pushd "${working_directory}/gettext-${target}" >/dev/null
    make distclean || true
    ./configure \
        MACOSX_DEPLOYMENT_TARGET="${deployment_target}" \
        CFLAGS="${cflags} --target=${target}-apple-macos${deployment_target}" \
        CXXFLAGS="${cflags} --target=${target}-apple-macos${deployment_target}" \
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
  if [[ "$(uname -m)" != "${target}" ]]; then
    echo "We are not on ${target}!"
    exit 1
  fi

  echo "### Building deps"
  pushd "$(dirname "${BASH_SOURCE[0]}")/.." >/dev/null

  rm -rf "./third-party" && mkdir -p "./third-party"
  local -r install_path="$(realpath ./third-party)"

  local -r install_path_lib="${install_path}/lib"
  local -r install_path_include="${install_path}/include"
  rm -rf "${install_path_lib}" && mkdir -p "${install_path_lib}"
  rm -rf "${install_path_include}" && mkdir -p "${install_path_include}"

  local -r target_install_path="${install_path}-${target}"
  rm -rf "${target_install_path}" && mkdir -p "${target_install_path}"

  local -r working_directory="$(realpath ./third-party/.deps)"
  mkdir -p "${working_directory}"
  download_gettext "${working_directory}"

  local deployment_target
  deployment_target=$(cat "./Resources/${target}_deployment_target.txt")
  readonly deployment_target

  extract_gettext "${working_directory}"
  build_gettext \
      "${deployment_target}" \
      "${gettext_default_cflags}" \
      "${working_directory}" \
      "${target_install_path}"

  package "${target_install_path}"

  popd >/dev/null
  echo "### Built deps"
}

main
