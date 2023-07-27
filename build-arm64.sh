#!/bin/bash
set -ev

LLVM_VER="$(python3 scripts/get_llvm_version.py llvm-project/llvm/CMakeLists.txt)"
PLATFORM_NAME="linux-gnu-ubuntu-18.04"
BUILD_PLATFORM="docker_ubuntu-18.04"
CPU_ARCH="arm64"
CONFIG_SUFFIX="release"
OUTPUT="llvm+mlir+clang-${LLVM_VER}-${CPU_ARCH}-${PLATFORM_NAME}-${CONFIG_SUFFIX}"

bash build_llvm.bash -o "$OUTPUT" -p "$BUILD_PLATFORM" -c "$CONFIG_SUFFIX" -j8

