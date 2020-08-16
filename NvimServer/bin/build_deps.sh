#!/bin/bash
set -Eeuo pipefail

readonly build_gettext=${build_gettext:-false}
readonly gettext_version="0.20.1"

build_gettext() {
  local -r deployment_target=$1
  local -r libintl_path="third-party/libintl"

  echo "### Building gettext"
  rm -rf ${libintl_path}
  mkdir -p ${libintl_path}

  rm -rf .deps/gettext*
  mkdir -p .deps

  pushd .deps >/dev/null
  curl -L -o gettext.tar.xz https://ftp.gnu.org/gnu/gettext/gettext-${gettext_version}.tar.xz
  tar xf gettext.tar.xz
  mv gettext-${gettext_version} gettext

  pushd gettext >/dev/null
  # Configure from https://github.com/Homebrew/homebrew-core/blob/8d1ae1b8967a6b77cc1f6f1af6bb348b3268553e/Formula/gettext.rb
  # Set the deployment target to $deployment_target
  ./configure MACOSX_DEPLOYMENT_TARGET=${deployment_target} \
    --disable-dependency-tracking \
    --disable-silent-rules \
    --disable-debug \
    --prefix=$(pwd)/../../${libintl_path} \
    --with-included-gettext \
    --with-included-glib \
    --with-included-libcroco \
    --with-included-libunistring \
    --with-emacs \
    --disable-java \
    --disable-csharp \
    --without-git \
    --without-cvs \
    --without-xz
  make MACOSX_DEPLOYMENT_TARGET=${deployment_target} install
  popd >/dev/null
  popd >/dev/null

  echo "### Built gettext"
}

main() {
  echo "### Building deps"
  pushd "$(dirname "${BASH_SOURCE[0]}")/.." >/dev/null

  local -r deployment_target_file="./Resources/macos_deployment_target.txt"
  local -r deployment_target=$(cat ${deployment_target_file})

  if [[ ${build_gettext} == true ]]; then
    build_gettext ${deployment_target}
  fi

  popd >/dev/null
  echo "### Built deps"
}

main

