#!/bin/bash

cd ../flycast
git checkout 392a429e8b040b3e5bf6696cb4f984274fc44123
git submodule update --recursive

mkdir build
cd build

cmake -DUSE_VULKAN=OFF \
      -DUSE_GLES=ON \
      -DCMAKE_BUILD_TYPE="Release" \
	  -DCMAKE_C_FLAGS_RELEASE="-Ofast -DNDEBUG -Wno-error=array-bounds -march=armv8-a -mtune=cortex-a35" \
	  -DCMAKE_CXX_FLAGS_RELEASE="-Ofast -DNDEBUG -Wno-error=array-bounds -march=armv8-a -mtune=cortex-a35" \
      -DWITH_SYSTEM_ZLIB=ON \
      -DUSE_HOST_SDL=ON \
      -DUSE_OPENMP=ON ../.

make -j$(( $(nproc) - 1 ))
strip flycast