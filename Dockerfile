# Use offical Ubuntu 20.04 Release as parent image
FROM ubuntu:20.04

# Set the directory for building the product
WORKDIR /linux

# One of our dependent packages is ignoring the non-interactive request when being installed
RUN ln -fs /usr/share/zoneinfo/America/New_York /etc/localtime

# Install additional packages that are required to build Yocto Linux
RUN DEBIAN_FRONTEND=noninteractive apt-get update && apt-get install -y \
    sudo \
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
    cpio \
    libsdl1.2-dev \
    xterm \
    u-boot-tools \
    openssl \
    curl \
    tftpd-hpa \
    locales \
    python3 \
    python3-pip \
    python3-pexpect \
    xz-utils \
    debianutils \
    iputils-ping \
    python3-git \
    python3-jinja2 \
    pylint3 \
    python2.7 \
    vim \
    ssh

# Set up TFTP
COPY tftpd-hpa /etc/default/tftpd-hpa
RUN mkdir /tftpboot
RUN chmod 777 /tftpboot
RUN service tftpd-hpa restart

# Set up the development space
RUN mkdir -p /linux
RUN chmod a+rwx /linux
COPY buildOnDocker.sh /linux/buildOnDocker.sh
RUN chmod a+x /linux/buildOnDocker.sh

# Set up the rules for accesing github via the http port
RUN mkdir /root/.ssh
RUN chmod 0700 /root/.ssh
COPY config /root/.ssh/config
# RUN ssh-keyscan github.com > /root/.ssh/known_hosts
COPY id* /root/.ssh/
RUN chmod 600 /root/.ssh/id_*

# Link python2.7 to python 2
RUN ln -s /usr/bin/python2.7 /usr/bin/python2
RUN ln -s /usr/bin/python2.7 /usr/bin/python
# Set up an additional user to build the components. bitbake moans about root usage
# Also add user to sudo group so we can install cces
ARG USER=bob
ARG UID=1000
ARG GID=1000
ARG PW=bob

RUN useradd -m -s /bin/bash ${USER} --uid=${UID} && echo "${USER}:${PW}" | chpasswd && adduser ${USER} sudo
# Make sure bob has the power to do whatever they want in the container
RUN echo "${USER} ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers