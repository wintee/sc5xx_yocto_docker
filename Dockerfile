# Use offical Ubuntu 18.04 Release as parent image
FROM ubuntu:18.04

# Set the directory for building the product
WORKDIR /linux

# Install additional packages that are required to build Yocto Linux
RUN DEBIAN_FRONTEND=noninteractive apt-get update && apt-get install -y \
    gawk \
    wget \
    git-core \
    diffstat \
    unzip \
    texinfo \
    gcc-multilib \
    build-essential \
    chrpath \
    socat \
    libsdl1.2-dev \
    xterm \
    u-boot-tools \
    openssl \
    curl \
    tftpd-hpa
