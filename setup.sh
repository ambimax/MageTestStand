#!/bin/bash
set -e
#set -x

# Colors
RED='\033[1;31m'
YELLOW='\033[1;33m'
ORANGE='\033[0;33m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

function error_exit {
    echo -e "${RED}$1${NC}" 1>&2
    exit 1
}

function cleanup {
  if [ -z $SKIP_CLEANUP ]; then
    step "Removing build directory ${BUILDENV}"
    rm -rf "${BUILDENV}"
  fi
}

function step {
    echo -e "${GREEN}$1${NC}"
}
trap cleanup EXIT

# check if this is a travis environment
if [ ! -z $TRAVIS_BUILD_DIR ] ; then
  WORKSPACE=$TRAVIS_BUILD_DIR
fi

if [ -z $WORKSPACE ] ; then
  error_exit "No workspace configured, please set your WORKSPACE environment"
fi

if [ -z $MAGETESTSTAND_URL ] ; then
    MAGETESTSTAND_URL="https://github.com/AOEpeople/MageTestStand.git"
fi


step "Create build environment"
BUILDENV=`mktemp -d /tmp/mageteststand.XXXXXXXX`

step "Cloning ${MAGETESTSTAND_URL} to ${BUILDENV}"
git clone "${MAGETESTSTAND_URL}" "${BUILDENV}" || error_exit "Cloning MageTestStand failed"
(cd ${BUILDENV} && tools/composer.phar install --no-interaction) || error_exit "MageTestStand composer install failed"

step "Copy module to build environment"
cp -rf "${WORKSPACE}" "${BUILDENV}/.modman/" || error_exit "Cannot copy module to build environment"

step "Run lint tests"
${BUILDENV}/tools/xmllint.sh "${WORKSPACE}" || error_exit "XML lint test failed"
${BUILDENV}/tools/phplint.sh "${WORKSPACE}" || error_exit "PHP lint test failed"

step "Run codesniffer tests"
PHPCS_IGNORE=$(find . -type f -name '.phpcs_ignore' | xargs cat | paste -s -d, -)
echo "Files to be ignored: ${PHPCS_IGNORE}"
${BUILDENV}/vendor/squizlabs/php_codesniffer/scripts/phpcs --standard=${BUILDENV}/vendor/zifius/magizendo/Magento1/ruleset.xml --ignore="${PHPCS_IGNORE}" ${WORKSPACE} || error_exit "CodeSniffer test failed"

step "Install module dependencies (composer)"
if [ -f composer.json ]; then
    ${BUILDENV}/tools/composer.phar require aoepeople/composer-installers:* || error_exit "Unable to install composer installers"
    ${BUILDENV}/tools/composer.phar install --no-interaction || error_exit "Composer install failed"
fi

step "Copy module dependencies to build environment"
if [ -d "${WORKSPACE}/vendor" ] ; then
  cp -rf ${WORKSPACE}/vendor "${BUILDENV}/" || error_exit "Cannot copy vendor folder to build environment"
fi

if [ -d "${WORKSPACE}/.modman" ] ; then
  cp -rf ${WORKSPACE}/.modman/* "${BUILDENV}/.modman/" || error_exit "Cannot copy .modman folder to build environment"
fi

step "Install Magento"
${BUILDENV}/install.sh || error_exit "Magento installation failed"

step "Run Unit Tests"
PHPUNIT=${BUILDENV}/bin/phpunit
if [ ! -f $PHPUNIT ]; then
    PHPUNIT=${BUILDENV}/vendor/bin/phpunit
fi

cd ${BUILDENV}/htdocs || error_exit "Cannot switch to magento root in build environment"
${PHPUNIT} --colors -d display_errors=1