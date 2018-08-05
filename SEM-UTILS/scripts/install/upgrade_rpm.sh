#!/bin/bash
# Written by Gregory Danenberg, script upgrades real rpm based components
# Version=1.0

COMP_INSTALL=$1
BACKUP_DIR=/usr/cti/conf/.backup

MAM_EXE=/usr/cti/apps/babysitter/MamCMD

if [ $# -ne 1 ]; then
	echo "	USAGE: $0 [rpm to install]"
	exit 1
fi

if [ ! -f $COMP_INSTALL ]; then
	echo "MAIN[ERROR]: $COMP_INSTALL file is not found"
	exit 1
fi


set_params () {
	
	COMP_NAME=`echo ${COMP_INSTALL}|sed 's/-[0-9].*//'`
	if [ -z $COMP_NAME ]; then
		echo "set_params[ERROR]: Failed to extract component name from $COMP_INSTALL"
		exit 1
	else
		echo "set_params[INFO]: Component name is $COMP_NAME"
		export COMP_NAME
	fi
	
	CONF_DIR=/usr/cti/conf/`echo ${COMP_NAME}|tr [A-Z] [a-z]`
	if [ ! -d $CONF_DIR ]; then
		echo "set_params[ERROR]: Failed to find configuration directory for $COMP_NAME : $CONF_DIR"
		exit 1
	else
		echo "set_params[INFO]: CONF_DIR is $CONF_DIR"
		export CONF_DIR
	fi
	
	Date=`date +%m%d%Y.%H%M%S`
	export Date

}

check_installed () {
	
	echo -n "check_installed[INFO]: The current version of $COMP_NAME is: "
	rpm -q $COMP_NAME
	
	return $?
}

kill_proc () {
	
	COMP_USER=`echo $COMP_NAME|tr [A-Z] [a-z]`user
	echo "kill_proc[INFO]: Application is running with $COMP_USER"
	
	procId=`ps auwwx|grep ^${COMP_USER}|awk '{print $2}'`
	echo "kill_proc[INFO]: Process id is $procId"
	
	kill -9 $procId

}

stop_mamcmd () {

	if [ -f ${MAM_EXE} ]; then

		#waiting to finish previous babysitter restart
		while [ "`${MAM_EXE} d |grep status:Starting`" ]; do 
			echo "stop_mamcmd[INFO]: Babysitter Unit is currently initializing" && sleep 1
		done
		
		if [ "`${MAM_EXE} d|grep $COMP_NAME`" ]; then
			echo "stop_mamcmd[INFO]: $COMP_NAME is running under babysitter control"
			
			APP_INST=$(${MAM_EXE} d |grep ^${COMP_NAME}.*Up|awk '{print $1}')
		
			if [ ! -z $APP_INST ]; then
				${MAM_EXE} stop $APP_INST
			else
				echo "stop_mamcmd[INFO]: The $COMP_NAME is already down"
			fi
		else
			echo "stop_mamcmd[INFO]: $COMP_NAME is not running under babysitter control"
			kill_proc
		fi
	else
		echo "stop_mamcmd[INFO]: There is no babysitter on this system"
		kill_proc
	fi
	
	sleep 5
			
	
}


backup_comp () {
	
	if [ ! -d $BACKUP_DIR ]; then
		mkdir -p $BACKUP_DIR
		echo "backup_comp[INFO]: Created $BACKUP_DIR directory"
	fi
	
	INST_VERS=`rpm -q ${COMP_NAME}|perl -ne '/$COMP_NAME-(.*)/; print $1'`
	echo "backup_comp[INFO]: Installed version is $INST_VERS"
	
	tar cvf ${BACKUP_DIR}/${COMP_NAME}_${INST_VERS}_${Date}.tar $CONF_DIR
	if [ $? -eq 0 ]; then
		echo "backup_comp[INFO]: Saved $CONF_DIR as ${BACKUP_DIR}/${COMP_NAME}_${INST_VERS}_${Date}"
	else
		echo "backup_comp[ERROR]: Failed to save $CONF_DIR as ${BACKUP_DIR}/${COMP_NAME}_${INST_VERS}_${Date}"
	fi
	
	

}

uninstall_comp () {
	
	rpm -e $COMP_NAME
	
	if [ $? -ne 0 ]; then
		echo "uninstall_comp[ERROR]: Failed to remove $COMP_NAME"
		exit 1
	else
		echo "uninstall_comp[INFO]: $COMP_NAME has been removed"
	fi

}

install_comp () {

	rpm -Uvh $COMP_INSTALL
	if [ $? -ne 0 ]; then
		echo "install_comp[ERROR]: Failed to install $COMP_INSTALL"
		exit 1
	else
		echo "install_comp[INFO]: $COMP_INSTALL has been installed"
	fi	
	

}

# MAIN
set_params
check_installed
if [ $? -eq 0 ]; then
	echo "MAIN[INFO]: $COMP_NAME is installed on this server"
	stop_mamcmd
	#backup_comp
	uninstall_comp
else
	echo -e "\nMAIN[INFO]: $COMP_NAME is not installed on this server"
fi

install_comp
	
