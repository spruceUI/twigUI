#!/bin/bash

cd ../ppsspp
git checkout e49c0bd8836a8a8f678565357773386f1174d3f5
git submodule update --recursive

git apply ../emu_patches/ppsspp*

mkdir build
cd build/

cmake -DUSING_EGL=OFF \
      -DCMAKE_BUILD_TYPE=Release \
      -DUSING_GLES2=ON \
      -DUSE_FFMPEG=YES \
      -DUSE_SYSTEM_FFMPEG=NO \
      -DUSE_SYSTEM_LIBPNG=OFF \
      -DVULKAN=OFF \
      -DSDL2_LIBRARY="/usr/lib/aarch64-linux-gnu/libSDL2.so" \
      -DSDL2_INCLUDE_DIR="/usr/include/SDL2" \
      -DUSE_VULKAN_DISPLAY_KHR=OFF \
      -DUSING_X11_VULKAN=OFF \
      -DUSE_WAYLAND_WSI=OFF \
      -DUSING_FBDEV=ON \
      -DCMAKE_C_COMPILER=/usr/bin/clang \
      -DCMAKE_CXX_COMPILER=/usr/bin/clang++ \
      -DCMAKE_C_FLAGS="-Ofast -fno-tree-slp-vectorize -D_NDEBUG -march=armv8-a+crc -mtune=cortex-a35 -ftree-vectorize -funsafe-math-optimizations" \
      -DCMAKE_CXX_FLAGS="-Ofast -fno-tree-slp-vectorize -D_NDEBUG -march=armv8-a+crc -mtune=cortex-a35 -ftree-vectorize -funsafe-math-optimizations" \
      -DUSE_MINIUPNPC=OFF \
      -DUSING_QT_UI=OFF \
      -DUSE_DISCORD=OFF \
      -DCMAKE_CXX_FLAGS=-fpermissive ../.

make -j$(( $(nproc) - 1 ))

strip PPSSPPSDL
