#!/bin/bash

set -e -x

# 0. Check
CURRENT_DIR="$(pwd)"
SOURCE_DIR="$CURRENT_DIR"
if [ ! -f "$SOURCE_DIR/llvm-project/llvm/CMakeLists.txt" ]; then
  echo "Error: $SOURCE_DIR/llvm-project/llvm/CMakeLists.txt is not found."
  echo "       Did you run git submodule update --init --recursive?"
  exit 1
fi

# Parse arguments
install_prefix=""
platform=""
build_config=""
num_jobs=8

usage() {
  echo "Usage: bash build_llvm.sh -o INSTALL_PREFIX -p PLATFORM -c CONFIG [-j NUM_JOBS]"
  echo "Ex: bash build_llvm.sh -o llvm-14.0.0-x86_64-linux-gnu-ubuntu-18.04 -p docker_ubuntu_18.04 -c assert -j 16"
  echo "INSTALL_PREFIX = <string> # \${INSTALL_PREFIX}.tar.xz is created"
  echo "PLATFORM       = {local|docker_ubuntu_18.04}"
  echo "CONFIG         = {release|assert|debug}"
  echo "NUM_JOBS       = {1|2|3|...}"
  exit 1;
}

while getopts "o:p:c:j:" arg; do
  case "$arg" in
    o)
      install_prefix="$OPTARG"
      ;;
    p)
      platform="$OPTARG"
      ;;
    c)
      build_config="$OPTARG"
      ;;
    j)
      num_jobs="$OPTARG"
      ;;
    *)
      usage
      ;;
  esac
done

if [ x"$install_prefix" == x ] || [ x"$platform" == x ] || [ x"$build_config" == x ]; then
  usage
fi

# Set up CMake configurations
CMAKE_CONFIGS="-DLLVM_ENABLE_PROJECTS=mlir -DLLVM_TARGETS_TO_BUILD=X86;NVPTX;AMDGPU"
if [ x"$build_config" == x"release" ]; then
  CMAKE_CONFIGS="${CMAKE_CONFIGS} -DCMAKE_BUILD_TYPE=Release"
elif [ x"$build_config" == x"assert" ]; then
  CMAKE_CONFIGS="${CMAKE_CONFIGS} -DCMAKE_BUILD_TYPE=MinSizeRel -DLLVM_ENABLE_ASSERTIONS=True"
elif [ x"$build_config" == x"debug" ]; then
  CMAKE_CONFIGS="${CMAKE_CONFIGS} -DCMAKE_BUILD_TYPE=Debug"
else
  usage
fi

# Create a temporary build directory
BUILD_DIR="$(mktemp -d)"
echo "Using a temporary directory for the build: $BUILD_DIR"
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

if [ x"$platform" == x"local" ]; then
  # Build LLVM locally
  pushd "$BUILD_DIR"
  cmake "$SOURCE_DIR/llvm-project/llvm" -DCMAKE_INSTALL_PREFIX="$BUILD_DIR/$install_prefix" $CMAKE_CONFIGS
  make -j${num_jobs} install
  tar -cJf "${CURRENT_DIR}/${install_prefix}.tar.xz" "$install_prefix"
  popd
elif [ x"$platform" == x"docker_ubuntu_18.04" ]; then
  # Prepare build directories
  cp -r "$SOURCE_DIR/scripts" "$BUILD_DIR/scripts"

  # Create a tarball of llvm-project
  echo "Creating llvm-project.tar.gz"
  pushd "$SOURCE_DIR"
  tar -czf "$BUILD_DIR/llvm-project.tar.gz" llvm-project
  popd

  # Run a docker
  DOCKER_TAG="build"
  DOCKER_REPOSITORY="clang-docker"
  DOCKER_FILE_PATH="scripts/docker_ubuntu18.04/Dockerfile"

  echo "Building $DOCKER_REPOSITORY:$DOCKER_TAG using $DOCKER_FILE_PATH"
  docker build -t $DOCKER_REPOSITORY:$DOCKER_TAG --build-arg cmake_configs="${CMAKE_CONFIGS}" --build-arg num_jobs="${num_jobs}" --build-arg install_dir_name="${install_prefix}" -f "$BUILD_DIR/$DOCKER_FILE_PATH" "$BUILD_DIR"

  # Copy a created tarball from a Docker container.
  # We cannot directly copy a file from a Docker image, so first
  # create a Docker container, copy the tarball, and remove the container.
  DOCKER_ID="$(docker create $DOCKER_REPOSITORY:$DOCKER_TAG)"
  docker cp "$DOCKER_ID:/tmp/${install_prefix}.tar.xz" "${CURRENT_DIR}/"
  docker rm "$DOCKER_ID"
else
  rm -rf "$BUILD_DIR"
  usage
fi

# Remove the temporary directory
rm -rf "$BUILD_DIR"

echo "Completed!"
