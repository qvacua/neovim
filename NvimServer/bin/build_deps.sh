#!/bin/bash
set -Eeuo pipefail

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
  local -r x86_64_deployment_target=$1
  local -r cflags=$2
  local -r working_directory=$3
  local -r install_path=$4

  echo "### Building gettext"
  rm -rf "${install_path}"
  mkdir -p "${install_path}"

  pushd "${working_directory}/gettext" >/dev/null
    make distclean || true
    ./configure \
        CFLAGS="${cflags}" \
        MACOSX_DEPLOYMENT_TARGET="${x86_64_deployment_target}" \
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
    make MACOSX_DEPLOYMENT_TARGET="${x86_64_deployment_target}" install

    cp -r "${x86_64_install_path}/include"/* "${install_path_include}"
    cp -r "${x86_64_install_path}/lib"/* "${install_path_lib}"
  popd >/dev/null
  echo "### Built gettext"
}

main() {
  echo "### Building deps"
  pushd "$(dirname "${BASH_SOURCE[0]}")/.." >/dev/null

  local -r install_path="$(realpath ./third-party)"
  local -r install_path_lib="$(realpath ./third-party/lib)"
  local -r install_path_include="$(realpath ./third-party/include)"

  local -r working_directory="$(realpath ./third-party/.deps)"

  local -r x86_64_install_path="${install_path}/libintl/x86_64"
  local -r arm64_install_path="${install_path}/libintl/arm64"

  local -r x86_64_deployment_target=$(cat "./Resources/x86_64_deployment_target.txt")
  local -r arm64_deployment_target=$(cat "./Resources/arm64_deployment_target.txt")

  rm -rf "${install_path_lib:?}/"*
  rm -rf "${install_path_include:?}/"*
  mkdir -p "${install_path_lib}"
  mkdir -p "${install_path_include}"

  mkdir -p "${working_directory}"
  download_gettext "${working_directory}"

  build_gettext \
      "${x86_64_deployment_target}" \
      "${gettext_default_cflags}" \
      "${working_directory}" \
      "${x86_64_install_path}"

  popd >/dev/null
  echo "### Built deps"
}

main
