#!/bin/bash

cd ../openbor
git checkout 7569231a0ae3f0a7f5a6697b2ce4f09a0cf50a43

rm -rf build.lin.arm64
cmake -DBUILD_LINUX=ON -DTARGET_ARCH="ARM64" -S . -B build.lin.arm64 && cmake --build build.lin.arm64 --config Release -- -j $(( $(nproc) - 1 ))
