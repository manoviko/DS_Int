#!/bin/bash
# Script stops all running instances and backup predefined cust level files

ROLLBACK_DIR=/home/smsc/.rollback
PKG_ENV_DIR=/var/lib/rpm/pkgadd/env
#MERGECUST_LIST=$1

#if [ $# -ne 1 ]; then
#	echo " USAGE: $0 [list of file to merge]"
#	exit 1
#fi

stopMonitor () {
	
	if [ -e /home/smsc ]; then
		echo "INFO: Stopping smsc monitor"
		su - smsc -c "smsc -class monitor boot_script.monitor stop"
		if [ $? -ne 0 ]; then
			echo "ERROR: Failed to stop smsc monitor"
			exit 1
		fi
	else 
		echo "WARN: no mre based system on this server"
	fi
}

stopBabysitter () {
	
	if [ -f /etc/init.d/babysitter ]; then
		service babysitter status &> /dev/null
		if [ $? -eq 0 ]; then
			echo "INFO: Stopping babysitter"
			service babysitter stop
			if [ $? -ne 0 ]; then
				echo "ERROR: Failed to stop babysitter"
				exit 1
			fi
		else
			echo "INFO: Babysitter already stopped"
		fi
	else
		echo "WARN: no babysitter on this server"
	fi
}

createBackup () {

	if [ ! -d $ROLLBACK_DIR ]; then
		mkdir -p $ROLLBACK_DIR
		echo "INFO: Created $ROLLBACK_DIR directory"
	fi

	backupTar=${ROLLBACK_DIR}/Backup_`cat /home/smsc/.nyappl/smsc|awk '{split($0,a," "); print a[1]}'`_`date +"%d-%m-%Y_%H-%M-%S"`.tar
	tar cvf $backupTar /home/smsc/site/config
	if [ $? -eq 0 ]; then
		echo "INFO: Created backup in $backupTar"
	else
		echo "ERROR: Failed to take backup on /home/smsc/site/config to $backupTar"
		exit 1
	fi
	/bin/cp -f $backupTar ${ROLLBACK_DIR}/lastBackup.tar 
	echo "INFO: Saved $backupTar as ${ROLLBACK_DIR}/lastBackup.tar"
	
	chown -R root:root /home/smsc/.rollback
	chmod -R o-rxw /home/smsc/.rollback
}

createBackupMergeCust () {

	if [ ! -f $MERGECUST_LIST ]; then
		echo "ERROR: Failed to find $MERGECUST_LIST"
		exit 1
	fi
	
	if [ ! -d $ROLLBACK_DIR/CUST_BACKUP ]; then
		mkdir -p $ROLLBACK_DIR/CUST_BACKUP
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
				echo "ERROR: $line is not valid"
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
			FILE_PATH=/home/smsc/${COMP_PATH}.${COMP_VER}/${FILE}
			
			if [ ! -f $FILE_PATH ]; then
				echo "ERROR: Failed to find full path for $FILE : $FILE_PATH "
				exit 1
			fi
			
			FILE_NAME=`basename $FILE_PATH`
			
			/bin/cp -f $FILE_PATH $ROLLBACK_DIR/CUST_BACKUP/${FILE_NAME}_${COMP_FULL_VER}
			
		done <$MERGECUST_LIST
	
	else
		echo "INFO: $MERGECUST_LIST is empty, nothing to do..."
	fi
}

stopOMNI () {

	if [[ `rpm -qa | grep OMNI` == "" ]]; then
	        echo "INFO: OMNI not found"
	else
	        echo "INFO: OMNI found, stopping"
	        su - smsc -c "Terminate 0"
	        echo "INFO: OMNI stopped"
	fi

}


removeRollbackLock () {

	if [ -f /home/smsc/.rollback/lock ]; then
		/bin/rm -f /home/smsc/.rollback/lock
		echo "INFO: Removed /home/smsc/.rollback/lock"
	fi
	
}

#MAIN
removeRollbackLock
stopMonitor
stopBabysitter
stopOMNI
createBackup
#createBackupMergeCust
removeRollbackLock




