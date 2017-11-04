#!/bin/bash
set -e
set -x
 

function cleanup {
  if [ -z $SKIP_CLEANUP ]; then
    echo "Removing build directory ${BUILDENV}"
    rm -rf "${BUILDENV}"
  fi
}
 
trap cleanup EXIT

# check if this is a travis environment
if [ ! -z $TRAVIS_BUILD_DIR ] ; then
  WORKSPACE=$TRAVIS_BUILD_DIR
fi

if [ -z $WORKSPACE ] ; then
  echo "No workspace configured, please set your WORKSPACE environment"
  exit 1
fi

if [ -z $MAGETESTSTAND_URL ] ; then
    MAGETESTSTAND_URL="https://github.com/AOEpeople/MageTestStand.git"
fi

BUILDENV=`mktemp -d /tmp/mageteststand.XXXXXXXX`

echo "Cloning ${MAGETESTSTAND_URL} to ${BUILDENV}"
git clone "${MAGETESTSTAND_URL}" "${BUILDENV}"
cp -rf "${WORKSPACE}" "${BUILDENV}/.modman/"

# if module came with own dependencies that were installed, use these:
if [ -d "${WORKSPACE}/vendor" ] ; then
  cp -f ${WORKSPACE}/composer.lock "${BUILDENV}/"
  cp -rf ${WORKSPACE}/vendor "${BUILDENV}/"
fi
if [ -d "${WORKSPACE}/.modman" ] ; then
  cp -rf ${WORKSPACE}/.modman/* "${BUILDENV}/.modman/"
fi

${BUILDENV}/install.sh

PHPUNIT=${BUILDENV}/bin/phpunit
if [ ! -f $PHPUNIT ]; then
    PHPUNIT=${BUILDENV}/vendor/bin/phpunit
fi

cd ${BUILDENV}/htdocs
${PHPUNIT} --colors -d display_errors=1

export BUILDENV=${BUILDENV}
