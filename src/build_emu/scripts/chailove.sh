#!/bin/bash

cd ../libretro-chailove/

git checkout 467cd453e3b1761c5c3611746b35e709328a2ced
git submodule update --init

make -j$(( $(nproc) - 1 ))
