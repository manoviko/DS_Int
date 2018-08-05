#!/bin/bash
# Script merges files under MGW.1 that upgrade.pl usually fails to merge

CONFIG_DIR=/home/smsc/site/config
ROLLBACK_DIR=/home/smsc/.rollback
ROLLBACK_DIR_CUST=${ROLLBACK_DIR}/CUST_BACKUP
PKG_ENV_DIR=/var/lib/rpm/pkgadd/env
MERGECUST_LIST=$1
mergeExe=$2

if [ $# -ne 2 ]; then
	echo " USAGE: $0 [list of file to merge] [merge utility]"
	exit 1
fi

if [ ! -f $MERGECUST_LIST ]; then
	echo "ERROR: Failed to find $MERGECUST_LIST"
	exit 1
fi
	
if [ ! -f $mergeExe ]; then
	echo "ERROR: Failed to find merge utility"
	exit 2
else
	chmod +x $mergeExe
fi

if [ ! -d $ROLLBACK_DIR_CUST ]; then
	mkdir -p /home/smsc/.rollback/CUST_BACKUP
fi
	
if [ -s $MERGECUST_LIST ]; then
		
	while read line; do
			
		#check comments
		echo "$line"|perl -ne 'if ( /^\s*#/ ) { exit 1 }' &> /dev/null
		if [ $? -eq 1 ]; then
			continue
		fi
	
		COMP=`echo $line|awk -F',' '{print $1}'`
		FILE=`echo $line|awk -F',' '{print $2}'`
			
		if [[ -z $COMP ]] || [[ -z $FILE ]]; then
			echo "ERROR: $line in $MERGECUST_LIST is not valid"
			exit 1
		fi

		if [ ! -f ${PKG_ENV_DIR}/${COMP}.env ]; then
			echo "ERROR: Failed to find ${PKG_ENV_DIR}/${COMP}.env"
			exit 1
		fi
				
		COMP_VER=`grep VERSION ${PKG_ENV_DIR}/${COMP}.env|sed 's/VERSION=.\(.*\)./\1/'`
		RELEASE=`grep RELEASE ${PKG_ENV_DIR}/${COMP}.env|sed 's/RELEASE=.\(.*\)./\1/'`
		if [[ -z $COMP_VER ]] || [[ -z $RELEASE ]]; then
			echo "ERROR: Failed extracting $COMP version and release from ${PKG_ENV_DIR}/${COMP}.env"
			exit 1
		fi
		COMP_FULL_VER=${COMP_VER}_${RELEASE}
			
		COMP_PATH=`echo $COMP|tr [A-Z] [a-z]`
		COMP_CUST_PATH=/home/smsc/${COMP_PATH}.${COMP_VER}
			
		if [ ! -d $COMP_CUST_PATH ]; then
			echo "ERROR: Failed to find $COMP_CUST_PATH "
			exit 1
		fi
		
		#backup the file from site level
		if [ ! -f ${CONFIG_DIR}/${FILE} ]; then
			echo "WARN: The file ${CONFIG_DIR}/${FILE} from $MERGECUST_LIST is not on filesystem!"
			continue
		fi
		FILE_NAME=`basename ${CONFIG_DIR}/${FILE}`
		BASEDIR_FILE=`dirname ${CONFIG_DIR}/${FILE}`
		
		echo "INFO: Backup ${CONFIG_DIR}/${FILE} as ${ROLLBACK_DIR_CUST}/${FILE_NAME}_${COMP_FULL_VER}"
		/bin/cp -f ${CONFIG_DIR}/${FILE} ${ROLLBACK_DIR_CUST}/${FILE_NAME}_${COMP_FULL_VER}
		if [ $? -ne 0 ]; then
			echo "ERROR: Failed to copy ${CONFIG_DIR}/${FILE} to ${ROLLBACK_DIR_CUST}/${FILE_NAME}_${COMP_FULL_VER}"
			exit 1
		fi		
			
		COMP_CUST_PATH_FILE=$(find ${COMP_CUST_PATH}/config/site/group -name $FILE_NAME -type f)
		if [ ! -f $COMP_CUST_PATH_FILE ]; then
			echo "ERROR: $COMP_CUST_PATH_FILE is not found"
			exit 1
		fi
		
		echo "INFO: Copying $COMP_CUST_PATH_FILE to $BASEDIR_FILE"
		/bin/cp -f $COMP_CUST_PATH_FILE $BASEDIR_FILE
		if [ $? -ne 0 ]; then
			echo "ERROR: Failed to copy $COMP_CUST_PATH_FILE to $BASEDIR_FILE"
			exit 1
		fi
		
		echo "INFO: Merging ${ROLLBACK_DIR_CUST}/${FILE_NAME}_${COMP_FULL_VER} to ${CONFIG_DIR}/${FILE}"
		${mergeExe} ${CONFIG_DIR}/${FILE} ${ROLLBACK_DIR_CUST}/${FILE_NAME}_${COMP_FULL_VER}
		if [ $? -ne 0 ]; then
			echo "ERROR: Failed to merge $COMP_CUST_PATH_FILE to ${CONFIG_DIR}/${FILE}"
			exit 1
		else
			echo "INFO: Merged $COMP_CUST_PATH_FILE to ${CONFIG_DIR}/${FILE}"
		fi
			
	done <$MERGECUST_LIST
	
else
	echo "INFO: $MERGECUST_LIST is empty, nothing to do..."
fi