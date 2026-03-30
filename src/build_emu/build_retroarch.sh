#!/bin/bash

# git clone https://github.com/libretro/RetroArch.git

cd RetroArch
# git checkout e5eff6db27cd37c3c318741ee8bb9a3b8b60ec62
# git apply ../ra_patches/*


CFLAGS="-Ofast -march=armv8-a -mtune=cortex-a35 -fomit-frame-pointer -DNDEBUG -DHAVE_FILTERS_BUILTIN" \
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
            --disable-jack \
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

make HAVE_STATIC_VIDEO_FILTERS=1 HAVE_STATIC_AUDIO_FILTERS=1 -j$(( $(nproc) - 1 ))
strip retroarch

mkdir build/
mv retroarch build/ra64.pixel2

make -C gfx/video_filters extra_flags="$CFLAGS"
make -C libretro-common/audio/dsp_filters extra_flags="$CFLAGS"

strip gfx/video_filters/*.so
strip libretro-common/audio/dsp_filters/*.so

mkdir -p build/audio/
mkdir -p build/video/

cp gfx/video_filters/*.so build/video/
cp gfx/video_filters/*.filt build/video/

cp libretro-common/audio/dsp_filters/*.so build/audio/
cp libretro-common/audio/dsp_filters/*.dsp build/audio/
