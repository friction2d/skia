#!/bin/sh
set -e -x

CWD=`pwd`
APT=${APT:-0}
OSX=${OSX:-0}

if [ "${APT}" = 1 ]; then
    sudo apt update -y
    sudo apt install -y libgl1-mesa-dev libglx-dev libglvnd-core-dev curl git clang build-essential python3 ninja-build libfontconfig1-dev libfreetype-dev libexpat1-dev libjpeg-turbo8-dev libpng-dev libwebp-dev zlib1g-dev libicu-dev libharfbuzz-dev
fi

git submodule update --init
python3 tools/git-sync-deps

if [ "${OSX}" = 0 ]; then
    mkdir ${CWD}/build
    cd ${CWD}/build
    cmake -G Ninja -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_CXX_COMPILER=clang++ -DCMAKE_C_COMPILER=clang ..
    cmake --build .
    cmake --install . --prefix=`pwd`/install
    cd ${CWD}
    rm -rf ${CWD}/build
fi

mkdir ${CWD}/build
cd ${CWD}/build
cmake -G Ninja -DINSTALL_DOCS=ON -DINSTALL_HEADERS=ON -DSKIA_USE_SYSTEM_LIBS=OFF -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_CXX_COMPILER=clang++ -DCMAKE_C_COMPILER=clang ..
cmake --build .
cmake --install . --prefix=`pwd`/install
