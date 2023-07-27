# Base Image
FROM ubuntu:18.04

# Install build dependencies of llvm.
RUN apt update && apt install -y git build-essential make wget python3

# g++-9
RUN apt install -y software-properties-common
RUN add-apt-repository ppa:ubuntu-toolchain-r/test
RUN apt update
RUN apt install -y g++-9

# Use newer CMake for LLVM
ARG arch
RUN cd tmp && wget -q https://github.com/Kitware/CMake/releases/download/v3.24.0/cmake-3.24.0-linux-${arch}.tar.gz && tar -xf cmake-3.24.0-linux-${arch}.tar.gz

# Copy necessary files from the host.  A tarball is automatically expanded.
ADD scripts /tmp/scripts
ADD llvm-project.tar.gz /tmp

# Compile LLVM
ARG cmake_configs
ARG install_dir_name
RUN mkdir /tmp/llvm-project/build && cd /tmp/llvm-project/build && /tmp/cmake-3.24.0-linux-${arch}/bin/cmake /tmp/llvm-project/llvm $cmake_configs -DCMAKE_C_COMPILER=gcc-9 -DCMAKE_CXX_COMPILER=g++-9 -DCMAKE_INSTALL_PREFIX="/tmp/${install_dir_name}"
ARG num_jobs
RUN cd /tmp/llvm-project/build && make -j${num_jobs} install

# Create a tarball
RUN cd /tmp && tar -cJf "${install_dir_name}.tar.xz" "${install_dir_name}"
