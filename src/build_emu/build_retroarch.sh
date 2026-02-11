#!/bin/bash

git clone https://github.com/libretro/RetroArch.git

cd RetroArch
git checkout e5eff6db27cd37c3c318741ee8bb9a3b8b60ec62
git apply ../ra_patches/*

./configure --disable-qt \
            --disable-discord \
            --disable-neon \
            --disable-vg \
            --disable-sdl \
            --disable-x11 \
            --disable-vulkan \
            --disable-vulkan_display \
            --disable-opengl1 \
            --disable-opengl_core \
            --enable-alsa \
            --enable-udev \
            --enable-zlib \
            --enable-freetype \
            --enable-sdl2 \
            --enable-kms \
            --enable-ffmpeg \
            --enable-wayland \
            --enable-opengles \
            --enable-opengles3 \
            --enable-opengles3_1 \
            --enable-opengles3_2 \
            --enable-opengl \

make -j$(( $(nproc) - 1 ))

strip retroarch
