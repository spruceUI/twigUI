# Use Ubuntu as the base image
FROM arm64v8/ubuntu:noble

# Set environment variables for running
ENV DEBIAN_FRONTEND=noninteractive
SHELL ["/usr/bin/bash", "-c"]

# Update and install prerequisites
RUN apt update && \
    apt install -y \
        build-essential \
        git \
        wget \
        jq \
        libdrm-dev \
        python3 \
        python3-pip \
        python3-setuptools \
        python3-wheel \
        ninja-build \
        libopenal-dev \
        premake4 \
        autoconf \
        libevdev-dev \
        ffmpeg \
        libpipewire-0.3-dev \
        libavcodec-dev \
        libavformat-dev \
        libavdevice-dev \
        libsnappy-dev \
        libboost-tools-dev \
        libboost-thread-dev \
        libboost-all-dev \
        liblzma-dev \
        pkg-config \
        zlib1g-dev \
        libpng-dev \
        libsdl2-dev \
        clang \
        cmake \
        cmake-data \
        libarchive13 \
        libcurl4 \
        libfreetype6-dev \
        libjsoncpp-dev \
        librhash0 \
        libuv1 \
        meson \
        rustup \
        ruby-dev \
        libcurl4-openssl-dev \
        libglvnd-dev \
        libglu1-mesa-dev \
        freeglut3-dev \
        libao-dev \
        libzip-dev \
        liblua5.4-dev \
        libminiupnpc-dev \
        check \
        libgbm-dev \
        wayland-protocols \
        libxcb-dri2-0 \
        libinih-dev \
        libfmt-dev \
        libpixman-1-dev \
        liblhasa-dev \
        libmpg123-dev \
        libwildmidi-dev \
        libxmp-dev \
        fluidsynth \
        libfluidsynth-dev \
        libopusfile-dev \
        libspeexdsp-dev \
        libvpx-dev \
        libsdl2-ttf-2.0-0 \
        libsdl2-ttf-dev && \
    apt autoremove -y && \
    apt clean

RUN wget -P /tmp/ https://github.com/ginkage/libmali-rockchip/releases/download/v1.9-1-04f8711/libmali-bifrost-g31-g13p0-wayland-gbm_1.9-1_arm64.deb
# RUN wget -P /tmp/ https://repo.rock-chips.com/edge/debian-release-v2.0.0/pool/main/r/rockchip-rga/rockchip-rga_2.2.2-1_arm64.deb
# RUN wget -P /tmp/ https://repo.rock-chips.com/edge/debian-release-v2.0.0/pool/main/r/rockchip-rga/rockchip-rga-dev_2.2.2-1_arm64.deb
# RUN wget -P /tmp/ https://raw.githubusercontent.com/amarula/rockchip-linux-rga/refs/heads/master/RockchipRgaMacro.h

RUN apt install -y /tmp/libmali-bifrost-g31-g13p0-wayland-gbm_1.9-1_arm64.deb
# RUN apt install -y /tmp/rockchip-rga_2.2.2-1_arm64.deb
# RUN apt install -y /tmp/rockchip-rga-dev_2.2.2-1_arm64.deb
# 
# RUN mv /tmp/RockchipRgaMacro.h /usr/include/rga/RockchipRgaMacro.h

RUN rustup default stable

WORKDIR /mnt/host

# RUN cd /mnt/host && /bin/bash
