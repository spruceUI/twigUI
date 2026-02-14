#!/bin/bash

cd ../TIC-80
git checkout 8f7f36d2db99748bef8c65ee48657937ce4764cc

cd build/

BUILD_OPTS="-DBUILD_LIBRETRO=ON \
            -DBUILD_PLAYER=OFF \
            -DBUILD_SDL=OFF \
            -DBUILD_SDLGPU=OFF \
            -DBUILD_SOKOL=OFF \
            -DBUILD_TOUCH_INPUT=ON \
            -DBUILD_DEMO_CARTS=OFF \
            -DBUILD_EDITORS=OFF \
            -DBUILD_PRO=OFF \
            -DBUILD_STATIC=ON \
            -DBUILD_WITH_ZLIB=ON \
            -DBUILD_WITH_ALL=OFF \
            -DBUILD_WITH_LUA=ON \
            -DBUILD_WITH_WREN=ON \
            -DBUILD_WITH_FENNEL=ON \
            -DBUILD_WITH_MRUBY=OFF \
            -DBUILD_WITH_JANET=OFF \
            -DBUILD_WITH_WASM=OFF \
            -DBUILD_WITH_SCHEME=OFF \
            -DBUILD_WITH_SQUIRREL=OFF \
            -DBUILD_WITH_POCKETPY=OFF \
            -DBUILD_WITH_QUICKJS=OFF \
            -DBUILD_TOOLS=OFF \
            -DCMAKE_BUILD_TYPE=Release"

cmake "$BUILD_OPTS" ..
cmake --build . --parallel

strip tic80_libretro.so
