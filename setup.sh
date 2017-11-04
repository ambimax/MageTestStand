#!/bin/bash
set -e
set -x
 
function error_exit {
	echo "$1" 1>&2
	exit 1
}

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

echo
echo "Run lint tests"
echo "------------------------------------------------"
tools/xmllint.sh .modman/ || error_exit "XML lint test failed"
tools/phplinit.sh .modman/ || error_exit "PHP lint test failed"

echo
echo "Install composer dependencies"
echo "------------------------------------------------"
if [ -f composer.json ]; then
    tools/composer.phar require aoepeople/composer-installers:* || error_exit "Unable to install composer installers"
    tools/composer.phar install --dev --no-interaction || error_exit "Composer install failed"
fi

echo
echo "Create build environment"
echo "------------------------------------------------"
BUILDENV=`mktemp -d /tmp/mageteststand.XXXXXXXX`

echo "Cloning ${MAGETESTSTAND_URL} to ${BUILDENV}"
git clone "${MAGETESTSTAND_URL}" "${BUILDENV}" || error_exit "Cloning MageTestStand failed"

echo
echo "Copy module and dependencies to build environment"
echo "------------------------------------------------"
cp -rf "${WORKSPACE}" "${BUILDENV}/.modman/" || error_exit "Cannot copy module to build environment"

if [ -d "${WORKSPACE}/vendor" ] ; then
  cp -f ${WORKSPACE}/composer.lock "${BUILDENV}/" || error_exit "Cannot copy composer.lock to build environment"
  cp -rf ${WORKSPACE}/vendor "${BUILDENV}/" || error_exit "Cannot copy vendor folder to build environment"
fi

if [ -d "${WORKSPACE}/.modman" ] ; then
  cp -rf ${WORKSPACE}/.modman/* "${BUILDENV}/.modman/" || error_exit "Cannot copy .modman folder to build environment"
fi

echo
echo "Install Magento"
echo "------------------------------------------------"
${BUILDENV}/install.sh || error_exit "Magento installation failed"

echo
echo "Run Unit Tests"
echo "------------------------------------------------"
PHPUNIT=${BUILDENV}/bin/phpunit
if [ ! -f $PHPUNIT ]; then
    PHPUNIT=${BUILDENV}/vendor/bin/phpunit
fi

cd ${BUILDENV}/htdocs || error_exit "Cannot switch to magento root in build environment"
${PHPUNIT} --colors -d display_errors=1