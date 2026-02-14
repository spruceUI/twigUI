#!/bin/bash

cd ../tyrquake
git checkout 471f2a72d2a7b0416f6a21eb945e5af831df06a4

make -j$(( $(nproc) - 1 ))

strip tyrquake_libretro.so
