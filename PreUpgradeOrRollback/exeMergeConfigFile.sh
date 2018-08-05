#!/bin/bash
# Script merges cust level files according predefined list

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
	echo "ERROR: Failed to find $ROLLBACK_DIR_CUST"
	exit 1
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
		FLAG=`echo $line|awk -F',' '{print $3}'`
			
		if [[ -z $COMP ]] || [[ -z $FILE ]] || [[ -z $FLAG ]]; then
			echo "ERROR: $line is not valid"
			exit 1
		fi

		FLAG=`echo ${FLAG}|tr "[:upper:]" "[:lower:]"`
		restore=0
		
		case $FLAG in
			true|yes|y ) restore=1
								;;
			false|no|n ) restore=0
								;;
			*) echo "ERROR: Wrong flag (3rd parameter) for $line"
				exit 1
				;;
		esac
		
		if [ $restore -eq 0 ]; then
			echo "INFO: $FILE will not be restored from backup, flag is $FLAG" 
			continue
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
		FILE_PATH=/home/smsc/${COMP_PATH}.${COMP_VER}/${FILE}
			
		if [ ! -f $FILE_PATH ]; then
			echo "ERROR: Failed to find full path for $FILE : $FILE_PATH "
			exit 1
		fi
			
		FILE_NAME=`basename $FILE_PATH`
		BACK_FILE_NAME=`ls -tr $ROLLBACK_DIR_CUST/${FILE_NAME}*|tail -1`
		if [ ! -f $BACK_FILE_NAME ]; then
			echo "ERROR: Failed to find latest $FILE_NAME under $ROLLBACK_DIR_CUST"
			exit 1
		fi
			
		$mergeExe $FILE_PATH $BACK_FILE_NAME
		if [ $? -ne 0 ]; then
			echo "ERROR: Failed to merge $BACK_FILE_NAME and $FILE_PATH"
			exit 1
		else
			echo "INFO: Merged $BACK_FILE_NAME and $FILE_PATH"
		fi
			
	done <$MERGECUST_LIST
	
else
	echo "INFO: $MERGECUST_LIST is empty, nothing to do..."
fi