#!/bin/bash
# Written by Gregory Danenberg, used as a self extracting installer

export TMPDIR=`mktemp -d /tmp/selfextract.XXXXXX`

ARCHIVE=`awk '/^__ARCHIVE_BELOW__/ {print NR + 1; exit 0; }' $0`

tail -n+$ARCHIVE $0 | tar xz -C $TMPDIR

CDIR=`pwd`
cd $TMPDIR
if [ ! -f scdb_swim_installer.sh ]; then
	echo " -E- Failed to find installation script scdb_swim_installer.sh"
	cd $CDIR
	/bin/rm -rf $TMPDIR	
	exit 1
else
	chmod +x scdb_swim_installer.sh
	mkdir -p /var/cti/temp/scdb/install
	/bin/cp -f scdb_swim_installer.sh /var/cti/temp/scdb/install/
	./scdb_swim_installer.sh -install
fi

cd $CDIR
#echo " -I- Removing scraps in $TMPDIR"
/bin/rm -rf $TMPDIR

exit 0
__ARCHIVE_BELOW__
