#!/bin/bash -ex
KERNEL="${KERNEL:-$PWD/../linux-new}"
ARCH="${ARCH:-mipsel-linux}"

gcc_ver="$(./mipsel-linux/bin/mipsel-linux-gcc --version | grep 'mipsel-linux-gcc (GCC)' | awk '{print $NF}')"
linux_ver="$(cd "$KERNEL"; git rev-parse --short HEAD)"
release="${ARCH}-${gcc_ver}-${linux_ver}"
mv "${ARCH}" "$release"

tar acf "${release}.tar.xz" "$release"
