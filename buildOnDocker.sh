#!/bin/bash
# Script for automatically building Yocto Linux for ADSP-SC5xx processors
# Copyright David Gibson <wintee@gmail.com> All Rights Reserved.
# This script is distributed under the standard MIT Licnse.
# Configure these for your build
echo "I AM RUNNING AS:"
whoami
id
echo " "
REPO_URL=https://github.com/analogdevicesinc/lnxdsp-repo-manifest.git
REPO_BRANCH=develop/g-xp
REPO_MANIFEST=default.xml
GIT_EMAIL="win.tee@gmail.com"
GIT_NAME="ADI Linux Test"
SCRIPT_TARGET=""
BUILD_ARGS=""
WORK_DIR="/linux"
BUILD_DIR="build"
GH_REPO_USER=""
GH_REPO_PASS=""
CONF_APPEND="/linux/conf_append"
BUILDING_MIRROR=flase

function usage() {
    echo "$0: -r <repo> -b <branch> -m <machine> [-gu <github user> -gp <github password>][-f <manifest file>][-mu <mirror url>][-mr ] <bitbake commands>"
    echo "     where machine is one of:"
    echo "          sc589-mini"
    echo "          sc589-ezkit"
    echo "          sc584-ezkit"
    echo "          sc573-ezkit"
    echo "          sc594-som-ezkit"
    echo ""
    echo "Bitbake commands are usually the commands to build ADI images:"
    echo "          adsp-sc5xx-full"
    echo "          adsp-sc5xx-ramdisk"
    echo "          u-boot-adi"
    echo "          linux-adi"
    echo "  Please refer to wiki.analog.com/resources/tools-software/linuxdsp for more details"
    echo "  Default repo is ${REPO_URL} but you still need to specify it with -r "
    exit $1
}
# Parse default args
if [ $# -lt 7 ]
then
  echo "Error: Please provide correct arguments to the script"
  usage -1
fi
if [  "$1" == "-r" ]
then
  shift
  REPO_URL=$1
  shift
else
  echo "Error: Require a repo to be provided"
  usage -2
fi
if [ "$1" == "-b" ]
then
  shift
  REPO_BRANCH=$1
  shift
else
  echo "Error: Require a branch"
  usage -3
fi
if [ "$1" == "-m" ]
then
  shift
  SCRIPT_TARGET=$1
  shift
else
  echo "Error: Please provide a valid machine"
  usage -1
fi
# Optional args
if [ "$1" == "-gu" ]
then
  shift
  GH_REPO_USER=$1
  if [ "${GH_REPO_USER}" == "null" ]
  then
    GH_REPO_USER=""
  fi
  shift
fi
if [ "$1" == "-gp" ]
then
  shift
  GH_REPO_PASS=$1
  if [ "${GH_REPO_PASS}" == "null" ]
  then
    GH_REPO_PASS=""
  fi

  shift
fi
if [ "$1" == "-f" ]
then
  shift
  REPO_MANIFEST=$1
  shift
fi
if [ "$1" == "-mu" ]
then
  shift
  MIRROR_URL=$1
  shift
fi
if [ "$1" == "-mr" ]
then
  BUILDING_MIRROR=true
  shift
fi

BUILD_ARGS="$*"

echo "    REPO: ${REPO_URL}"
echo "  BRANCH: ${REPO_BRANCH}"
echo "PLATFORM: ${SCRIPT_TARGET}"
echo "BB IMAGE: ${BUILD_ARGS}"
if [ "${GH_REPO_USER}" != "" ]
then
  # Left in for debug purposes, don't worry if you use the script correctly Jenkins will mask these lines out
  echo " GH USER: ${GH_REPO_USER}"
  echo " GH PASS: ${GH_REPO_PASS}"
  echo "https://${GH_REPO_USER}:${GH_REPO_PASS}@github.com" >> ~/.git-credentials
fi

# If building from a mirror
touch ${CONF_APPEND}    # even if not appending anything to conf, create an empty file so nothing will get appended
if [ "${MIRROR_URL}" != "" ]
then
  echo " MIRROR URL: ${MIRROR_URL}"
  echo """
# FORCE IT TO USE OUR MIRROR
INHERIT += \"own-mirrors\"
SOURCE_MIRROR_URL = \"${MIRROR_URL}/\${MACHINE}/\"
PREMIRRORS_prepend = \" \\
	git://.*/.*   \${SOURCE_MIRROR_URL} \\n \\
	ftp://.*/.*   \${SOURCE_MIRROR_URL} \\n \\
	http://.*/.*  \${SOURCE_MIRROR_URL} \\n \\
	https://.*/.* \${SOURCE_MIRROR_URL} \\n \"
BB_FETCH_PREMIRRORONLY = \"1\"

# USE THE GIVEN SRC REVS:""" > ${CONF_APPEND}
  curl ${MIRROR_URL}/adsp-${SCRIPT_TARGET}/src_revs >> ${CONF_APPEND}
fi
# If building a mirror
if $BUILDING_MIRROR
then
  echo """
# COLLECT TARBALLS TO BUILD A MIRROR AND DOCUMENT THE PACKAGE VERSIONS FOR PACKAGES WITH AUTOREV
INHERIT += \" buildhistory \"
DL_DIR = \"${WORK_DIR}/${BUILD_DIR}/downloads\"
BB_GENERATE_MIRROR_TARBALLS = \"1\"
""" >> ${CONF_APPEND}
fi

# Check to see if we are in test mode
if [ "${BUILD_ARGS}" = "test" ]
then
  # Emulate what would happen in a typical build. We need to create our artifacts
  mkdir -p build/tmp/deploy/images
  touch build/tmp/deploy/images/made_up
  mkdir -p build/tmp/deploy/licenses
  touch build/tmp/deploy/licenses/made_up
  mkdir -p build/tmp/log
  touch build/tmp/log/made_up
  exit
fi
echo "Sleeping for 5. Hit Ctrl-C if this looks wrong"
sleep 5

#  Locale used to stop python moaning
export SET_LANG=en_US.UTF-8

cd ${WORK_DIR}
WD=`pwd`

# Do we need to use sudo, you really shouldn't be running as root. See the readme
SCMD=""
if [ "`whoami`" != "root" ]
then
  SCMD="sudo"
fi

# Setup locale to stop python bitching
${SCMD} locale-gen ${SET_LANG}
${SCMD} update-locale LC_ALL=${SET_LANG} LANG=${SET_LANG}
export LANG=${SET_LANG}

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
# Disable colour output or the repo init hangs waiting on input and cache username and password
git config --global color.ui false
git config --global credential.helper store

# Change ownership of build directory to bob or he can't write to it
${SCMD} chown -R `whoami` ${BUILD_DIR}

# Update the certificates or we might run into issues cloning the repos
sudo apt-get update
sudo apt-get install --reinstall ca-certificates

# Sync repos
if [ ! -d ${WD}/.repo ]
then
    ${WD}/bin/repo init -u ${REPO_URL} -b ${REPO_BRANCH} -m ${REPO_MANIFEST}
fi
${WD}/bin/repo sync

# Set up environment to build
source ./setup-environment -m adsp-${SCRIPT_TARGET} -b ${BUILD_DIR}   && \
cat ${CONF_APPEND} >> conf/local.conf                          && \
bitbake -q ${BUILD_ARGS}

if $BUILDING_MIRROR
then
  buildhistory-collect-srcrevs -a > "${WORK_DIR}/${BUILD_DIR}/downloads/src_revs"
  chmod -R a+rw ${WORK_DIR}/${BUILD_DIR}/downloads
else
  chmod -R a+rw ${WORK_DIR}/${BUILD_DIR}/tmp/deploy
fi
