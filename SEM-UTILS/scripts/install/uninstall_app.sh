#!/bin/bash
# Written by Gregory Danenebrg, 12/11
# The script removes SEM tomcat based component from server

MAM_NAME=$1

if [ -z $MAM_NAME ]; then
	echo "ERROR: `basename $0` [Application Name]"
	exit 1
else
	export MAM_NAME=`echo ${MAM_NAME}|tr "[:lower:]" "[:upper:]"`
fi

export COMP_NAME=`echo ${MAM_NAME}|tr "[:upper:]" "[:lower:]"`
export MAM_XML=Applications${MAM_NAME}.xml
RPM_NAME=${MAM_NAME}-

MAM_EXE=/usr/cti/apps/babysitter/MamCMD

stop_MAM() {
#stopping process with babysitter

	#waiting to finish previous babysitter restart
	while [ "`${MAM_EXE} d |grep status:Starting`" ]; do 
		echo "INFO: Babysitter Unit is currently initializing" && sleep 1
	done

	MAM_INST=$(${MAM_EXE} d |grep ^${MAM_NAME}.*Up|awk '{print $1}')
	if [ ! -z $MAM_INST ]; then
		$MAM_EXE stop $MAM_INST
	fi	

}

remove_baby() {
#removes babysitter process xml file

	if [ -f /usr/cti/conf/babysitter/${MAM_XML} ]; then
		echo "INFO : Removing /usr/cti/conf/babysitter/${MAM_XML}"
		/bin/rm -f /usr/cti/conf/babysitter/${MAM_XML}
	else
		echo "INFO : /usr/cti/conf/babysitter/${MAM_XML} does not exist on this server"
	fi
	
}

remove_rpm() {
#removes rpm
	rpm -q ${RPM_NAME}
	if [ $? -eq 0 ]; then 
		rpm -e ${RPM_NAME}
		if [ $? -ne 0 ]; then
			echo "ERROR: Failed to remove ${RPM_NAME}..."
			exit 1
		fi
	else
		echo "INFO : ${RPM_NAME} rpm is not installed on that server"
	fi
	
}

remove_scraps() {
#remove all other unnecessary direcories and files
	
	for df in $@; do
		if [ -e $df ]; then
			echo "INFO : Removing $df"
			/bin/rm -rf $df
		else
			echo "INFO : $df does not exist"
		fi
	done

}

reload_baby() {
#reload babysitter service after Application.xml removal

	service babysitter status &> /dev/null
	if [ $? -eq 0 ]; then
		service babysitter reload
	fi					
				
}

#MAIN
if [ -f $MAM_EXE ]; then
#relevant only for Babysitter, rpm removal tops the process upon postun section
	stop_MAM
	remove_baby
else
	echo "INFO : Babysitter is not installed on this server..."
fi

remove_rpm
remove_scraps /usr/cti/apps/${COMP_NAME}/webapps /usr/cti/apps/${COMP_NAME}/work
reload_baby



