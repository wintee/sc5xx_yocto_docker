:
# Script for automatically building Yocto Linux for ADSP-SC5xx processors
# Copyright David Gibson <wintee@gmail.com> All Rights Reserved.
# This script is distributed under the standard MIT Licnse.
# Configure these for your build

export DEV_BRANCH=develop/yocto-1.0.0
export GIT_EMAIL="you@dev.null"
export GIT_NAME="Fill in your name and e-mail"
export ARCH=sc589
export BOARD=mini

# Configure these, not so much
#  CCES 2.8.3 is a known good version for Linux, don't update it
export CCES_VERSION=2.8.3
#  Locale used to stop python moaning
export SET_LANG=en_US.UTF-8

WD=`pwd`

# Do we need to use sudo
SCMD=""
if [ "`whoami`" != "root" ]
then
  SCMD="sudo"
fi

# Setup locale to stop python bitching
${SCMD} locale-gen ${SET_LANG}
update-locale LC_ALL=${SET_LANG} LANG=${SET_LANG}
export LANG=${SET_LANG}

# Install CCES, needed for open source tools
if [ ! -d /opt/analog/cces/${CCES_VERSION} ]
then
    echo "Installing CrossCore Embedded Studio ${CCES_VERSION}"
    CCESFILE=adi-CrossCoreEmbeddedStudio-linux-x86-${CCES_VERSION}.deb
    if [ ! -e ${CCESFILE} ]
    then
        wget http://download.analog.com/tools/CrossCoreEmbeddedStudio/Releases/Release_${CCES_VERSION}/${CCESFILE}
    fi
    export DEBIAN_FRONTEND=noninteractive
    echo "adi-cces-${CCES_VERSION} adi-cces-${CCES_VERSION}/run-ocd-config boolean true" | debconf-set-selections
    echo "adi-cces-${CCES_VERSION} adi-cces-${CCES_VERSION}/accept-sla boolean true" | debconf-set-selections    
    ${SCMD} dpkg -i ${CCESFILE}
fi

export PATH=/opt/analog/cces/${CCES_VERSION}/ARM/arm-none-eabi-bin:${PATH}
# Set up repo tool
if [ ! -e ${WD}/bin/repo ]
then
    mkdir -p ${WD}/bin
    curl http://commondatastorage.googleapis.com/git-repo-downloads/repo > ./bin/repo
    chmod a+x ${WD}/bin/repo
fi

# Set up git credentials
git config --global user.email "${GIT_EMAIL}"
git config --global user.name "${GIT_NAME}"
# Disable colour output or the repo init hangs waiting on input
git config --global color.ui false

# Sync repos
if [ ! -d ${WD}/.repo ]
then
    ${WD}/bin/repo init -u https://github.com/analogdevicesinc/lnxdsp-repo-manifest.git -b ${DEV_BRANCH}
fi
${WD}/bin/repo sync

# We're going to build as root and I don't care what you say!
cat sources/poky/meta/conf/sanity.conf | sed -e 's/^INHERIT/# INHERIT/' > sources/poky/meta/conf/sanity.conf

# Set up environment to build
source ./setup-environment -m adsp-${ARCH}-${BOARD}

bitbake adsp-sc5xx-full


