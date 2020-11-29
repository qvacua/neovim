#!/bin/bash
set -Eeuo pipefail

readonly gettext_version="0.20.1"
readonly gettext_default_cflags="-g -O2"

download_gettext() {
  local -r working_directory=$1

  rm -rf "${working_directory:?}/"gettext*

  pushd "${working_directory}" >/dev/null
    curl -L -o gettext.tar.xz "https://ftp.gnu.org/gnu/gettext/gettext-${gettext_version}.tar.xz"
  popd >/dev/null
}

extract_gettext() {
  local -r working_directory=$1
  local -r target=$2

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
  local -r target=$5
  local -r host=$6

  echo "### Building gettext"
  pushd "${working_directory}/gettext-${target}" >/dev/null
    make distclean || true
    ./configure \
        MACOSX_DEPLOYMENT_TARGET="${deployment_target}" \
        CFLAGS="${cflags} --target=${target}-apple-macos${deployment_target}" \
        CXXFLAGS="${cflags} --target=${target}-apple-macos${deployment_target}" \
        --host="${host}" \
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

install_universal_lib() {
  local -r x86_64_install_path_lib=$1
  local -r arm64_install_path_lib=$2
  local -r install_path_lib=$3

  pushd "${install_path_lib}" >/dev/null
    lipo -create -output libintl.8.dylib "${x86_64_install_path_lib}/libintl.8.dylib" "${arm64_install_path_lib}.libintl.8.dylib"
    lipo -create -output libintl.a "${x86_64_install_path_lib}/libintl.a" "${arm64_install_path_lib}/libintl.a"
  popd >/dev/null
}

main() {
  echo "### Building deps"
  pushd "$(dirname "${BASH_SOURCE[0]}")/.." >/dev/null

  rm -rf "./third-party" && mkdir -p "./third-party"
  local -r install_path="$(realpath ./third-party)"

  local -r install_path_lib="${install_path}/lib"
  local -r install_path_include="${install_path}/include"
  rm -rf "${install_path_lib}" && mkdir -p "${install_path_lib}"
  rm -rf "${install_path_include}" && mkdir -p "${install_path_include}"

  local -r x86_64_install_path="${install_path}-x86_64"
  local -r arm64_install_path="${install_path}-arm64"
  rm -rf "${x86_64_install_path}" && mkdir -p "${x86_64_install_path}"
  rm -rf "${arm64_install_path}" && mkdir -p "${arm64_install_path}"

  local -r working_directory="$(realpath ./third-party/.deps)"
  mkdir -p "${working_directory}"
  download_gettext "${working_directory}"

  local target="arm64"
  local deployment_target
  deployment_target=$(cat "./Resources/${target}_deployment_target.txt")
  extract_gettext "${working_directory}" "${target}"
  build_gettext \
      "${deployment_target}" \
      "${gettext_default_cflags}" \
      "${working_directory}" \
      "${arm64_install_path}" \
      "${target}" \
      "arm-apple-macos"

  target="x86_64"
  deployment_target=$(cat "./Resources/${target}_deployment_target.txt")
  extract_gettext "${working_directory}" "${target}"
  build_gettext \
      "${deployment_target}" \
      "${gettext_default_cflags}" \
      "${working_directory}" \
      "${x86_64_install_path}" \
      "${target}" \
      "x86_64-apple-macos"

  install_universal_lib "${x86_64_install_path}/lib" "${arm64_install_path}/lib" "${install_path_lib}"
  cp -r "${arm64_install_path}/include"/* "${install_path_include}"

  popd >/dev/null
  echo "### Built deps"
}

main
