#!/bin/bash

cd ../fbalpha2012
git checkout c547d8cf3f7748f4094cee658a5d31ec1b79ece4

cd svn-current/trunk

export CFLAGS="${CXXFLAGS} -Ofast -Wno-error=array-bounds -march=armv8-a -mtune=cortex-a35"
export CXXFLAGS="${CXXFLAGS} -Ofast -Wno-error=array-bounds -march=armv8-a -mtune=cortex-a35"

make -j$(( $(nproc) - 1 )) -f makefile.libretro

strip fbalpha2012_libretro.so
