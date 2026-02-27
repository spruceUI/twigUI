#!/bin/bash

cd ../libretro-gme/

git checkout 495431b0f5951b9428253064370ac1272994c657
git submodule update --init

make -j$(( $(nproc) - 1 ))

strip gme_libretro.so
