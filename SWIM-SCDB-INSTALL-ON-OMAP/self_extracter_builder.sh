#!/bin/bash
# Written by Gregory Danenberg, used as a build script for self-extracting package

NAME=OmapFirstSteps.tar.gz
BIN_NAME=vm-scdb_swim_installer
VERSION=6.0.0.0-05

test -f ${BIN_NAME}_${VERSION}.bin && /bin/rm -f ${BIN_NAME}_${VERSION}.bin
test -f $NAME && /bin/rm -f $NAME

if [ ! -d kits ]; then
	echo " -E- Failed to find kits directory"
	exit 1
fi

(cd kits; tar czf ../${NAME} ./*)

if [ -f ${NAME} ]; then
	/bin/cat decompress.sh ${NAME} > ${BIN_NAME}_${VERSION}.bin
else
	echo " -E- Failed to find $NAME"
	exit 1
fi

chmod +x ${BIN_NAME}_${VERSION}.bin
echo " -I- self extracting ${BIN_NAME}_${VERSION}.bin created"
