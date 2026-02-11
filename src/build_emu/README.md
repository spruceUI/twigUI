# Build scripts

For Retroarch, cores, and standalone emulators.

Based mostly on [rk3326_core_builds](https://github.com/christianhaitian/rk3326_core_builds) and [rk-core-builder](https://github.com/cscribn/rk-core-builder) with some patches from [UnofficialOS](https://github.com/RetroGFX/UnofficialOS).

## How to use

Install and setup `qemu-user-static-binfmt`, `qemu-user-static` and `docker` following your preferred distro instructions.

Then `cd` into the current folder and run:

```
docker run --rm -it --privileged linuxserver/qemu-static --reset -p yes
docker pull --platform arm64 arm64v8/ubuntu:noble
docker-compose build
docker-compose run --rm rk-builder-3326-64 bash
```

#### Scripts

To build Retroarch:

`build_retroarch.sh`

To build most of the retroarch cores, except mame (using [rk3326_core_builds](https://github.com/christianhaitian/rk3326_core_builds)) :

`build_main_cores.sh`

To build all the extra cores and standalone emulators:

`build_extra_emu.sh all`

To build individual extra cores or standalone emulators:

`build_extra_emu.sh name`

Where `name` is a value from `extra_emu.json`