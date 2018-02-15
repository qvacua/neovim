#!/bin/bash

set -e

do_upload=$1

echo "### Building runtime, libnvim and its dependencies"

if [[ ! -e ./local.mk ]]; then
  echo "### Error: no local.mk"
  exit 1
fi

rm -rf build
make distclean

echo "### Building nvim to get the complete runtime folder"
temp_runtime_folder="/tmp/qvacua-nvim-runtime"
rm -rf ${temp_runtime_folder}
make \
     CFLAGS='-mmacosx-version-min=10.10' \
     MACOSX_DEPLOYMENT_TARGET=10.10 \
     CMAKE_FLAGS="-DCUSTOM_UI=0 -DCMAKE_INSTALL_PREFIX=${temp_runtime_folder}" \
     install

rm -rf build
make clean

make \
     CFLAGS='-mmacosx-version-min=10.10' \
     MACOSX_DEPLOYMENT_TARGET=10.10 \
     CMAKE_EXTRA_FLAGS="-DGETTEXT_SOURCE=CUSTOM -DPREFER_LUA=ON" \
     libnvim

build_folder_name="nvim_artifacts"
build_folder_path="./build/${build_folder_name}"

rm -rf ${build_folder_path}
mkdir ${build_folder_path}

echo "### Copying runtime"
rm -rf ${build_folder_path}/runtime
cp -r ${temp_runtime_folder}/share/nvim/runtime ${build_folder_path}

echo "### Copying libnvim"
rm -rf ${build_folder_path}/lib
rm -rf ${build_folder_path}/include
mkdir -p ${build_folder_path}/include
mkdir -p ${build_folder_path}/lib

cp ./build/lib/libnvim.a ${build_folder_path}/lib

echo "### Copying dependencies"
cp ./.deps/usr/lib/libjemalloc.a ${build_folder_path}/lib
cp ./.deps/usr/lib/liblua.a ${build_folder_path}/lib
cp ./.deps/usr/lib/libluv.a ${build_folder_path}/lib
cp ./.deps/usr/lib/libmsgpackc.a ${build_folder_path}/lib
cp ./.deps/usr/lib/libuv.a ${build_folder_path}/lib
cp ./.deps/usr/lib/libvterm.a ${build_folder_path}/lib

echo "### Copying libintl"
cp ./custom_ui/libintl/include/* ${build_folder_path}/include
cp ./custom_ui/libintl/lib/* ${build_folder_path}/lib
pushd ${build_folder_path}/lib
rm -f libintl.dylib
ln -f -s libintl.8.dylib libintl.dylib
popd

echo "### Packaging"
pushd ./build
tar cjf ${build_folder_name}.tar.bz2 ${build_folder_name}
popd

echo "### Package is located in ./build/${build_folder_name}.tar.bz2"

