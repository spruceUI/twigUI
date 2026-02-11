#!/bin/bash

cd ../flycast
git checkout 392a429e8b040b3e5bf6696cb4f984274fc44123

mkdir build && cd build

BUILD_OPTS="-DUSE_OPENGL=ON \
            -DUSE_GLES=ON \
            -DUSE_HOST_SDL=ON \
            -DUSE_OPENMP=ON"

export CXXFLAGS="${CXXFLAGS} -Wno-error=array-bounds"

cmake $BUILD_OPTS ..
make -j$(( $(nproc) - 1 ))
