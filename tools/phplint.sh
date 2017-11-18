#!/usr/bin/env bash

function error_exit {
	echo "$1" 1>&2
	exit 1
}

if [ ! -d $1 ] ; then
    error_exit "Invalid dir"
fi

# Run in parallel:
# find -L $1 \( -name '*.php' -o -name '*.phtml' \) -print0 | xargs -0 -n 1 -P 20 php -l

#PHPLINT_IGNORE=`printf "! -ipath \"%s\" " $(find . -type f -name '.phplint_ignore' | xargs cat)`
#FILES=`find $1 -type f \( -name '*.php' -o -name '*.phtml' \) "${PHPLINT_IGNORE}"`


TARGET=${1%/}
XMLLINT_IGNORE=$(printf "! -ipath %s " `find . -type f -name '.phplint_ignore' | xargs cat`)
FILES=`find $TARGET -type f \( -name '*.php' -o -name '*.phtml' \) $XMLLINT_IGNORE`


echo "Ignore"
echo $PHPLINT_IGNORE
echo "Files"
echo $FILES
echo ""

TMP_FILE=/tmp/phplint.tmp
touch $TMP_FILE;

for i in $FILES; do
    md5=($(md5sum $i));
    if grep -Fxq "$md5" $TMP_FILE; then
        continue
    fi

    php -l "$i" >/dev/null 2>&1 || error_exit "Unable to parse file '$i'"
    echo $md5 >> $TMP_FILE
done

echo "No PHP syntax errors detected in $1"