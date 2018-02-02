#!/bin/bash

set -e

GETTEXT_VERSION="0.19.8.1"

#echo "### Building gettext ${GETTEXT_VERSION}"
#
target_path="./CUSTOM_UI/libintl"
#
#mkdir -p .deps
#pushd .deps
#
#curl -o gettext.tar.xz https://ftp.gnu.org/gnu/gettext/gettext-${GETTEXT_VERSION}.tar.xz
#tar xf gettext.tar.xz
#mv gettext-${GETTEXT_VERSION} gettext
#
#pushd gettext
## Configure from https://github.com/Homebrew/homebrew-core/blob/8d1ae1b8967a6b77cc1f6f1af6bb348b3268553e/Formula/gettext.rb
## Set the deployment target to 10.10
#./configure CFLAGS='-mmacosx-version-min=10.10' MACOSX_DEPLOYMENT_TARGET=10.10 \
#            --disable-dependency-tracking \
#            --disable-silent-rules \
#            --disable-debug \
#            --prefix=$(pwd)/../${target_path}  \
#            --with-included-gettext \
#            --with-included-glib \
#            --with-included-libcroco \
#            --with-included-libunistring \
#            --with-emacs \
#            --disable-java \
#            --disable-csharp \
#            --without-git \
#            --without-cvs \
#            --without-xz
#make
#echo "### libintl is located in ./.deps/gettext/gettext-runtime/intl/.libs"
#popd # gettext
#popd # .deps

echo "### Copying header/libs to ${target_path}"
mkdir -p ${target_path}
mkdir -p ${target_path}/include
mkdir -p ${target_path}/lib
cp .deps/gettext/gettext-runtime/intl/libintl.h ${target_path}/include/
cp .deps/gettext/gettext-runtime/intl/.libs/libintl.a ${target_path}/lib/
cp .deps/gettext/gettext-runtime/intl/.libs/libintl.8.dylib ${target_path}/lib/

pushd ${target_path}/lib
ln -f -s libintl.8.dylib libintl.dylib
popd

echo "### Built gettext"
