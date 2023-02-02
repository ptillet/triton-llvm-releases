# Base Image
FROM centos:7

# Install build dependencies of llvm.
RUN yum install -y git make wget python3
# GCC / G++
RUN yum install -y centos-release-scl
RUN yum install -y devtoolset-7-gcc*
SHELL [ "/usr/bin/scl", "enable", "devtoolset-7"]

# Use newer CMake for LLVM
RUN cd tmp && wget -q https://github.com/Kitware/CMake/releases/download/v3.24.0/cmake-3.24.0-linux-x86_64.tar.gz && tar -xf cmake-3.24.0-linux-x86_64.tar.gz

# Copy necessary files from the host.  A tarball is automatically expanded.
ADD scripts /tmp/scripts
ADD llvm-project.tar.gz /tmp

# Compile LLVM
ARG cmake_configs
ARG install_dir_name
RUN mkdir /tmp/llvm-project/build && cd /tmp/llvm-project/build && /tmp/cmake-3.24.0-linux-x86_64/bin/cmake /tmp/llvm-project/llvm $cmake_configs -DCMAKE_INSTALL_PREFIX="/tmp/${install_dir_name}"
ARG num_jobs
RUN cd /tmp/llvm-project/build && make -j${num_jobs} install

# Create a tarball
RUN cd /tmp && tar -cJf "${install_dir_name}.tar.xz" "${install_dir_name}"d