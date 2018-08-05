#!/bin/bash
# Created by Gregory Danenberg, 10/2012
# DR-0-191-592, semus is used by OMAP SMS to monitor SEM processes

action=$1  #optional to remove the user
sudoFile=/etc/sudoers
appUser=semus
Date=`date '+%d%m%Y%H%M%S'`

check_pre () {

	rpm -qa|grep -i hkit
	if [ $? -eq 0 ]; then
		echo "ERROR: This script cannot be executed when HKIT is installed. "
		exit 1
	fi

	if [ ! -f /etc/sudoers ]; then
		echo "ERROR: /etc/sudoers does not exist"
		exit 1
	fi
}

create_user () {

	getent passwd ${appUser}
	if [ $? -ne 0 ]; then
		echo "INFO: Creating ${appUser} user"
		echo "INFO: Executing useradd -c \"${appUser} user created by Comverse\" -u 305339 -s /bin/bash -m -d /home/${appUser} ${appUser} "
		useradd -c "${appUser} user created by Comverse" -u 305339 -s /bin/bash -m -d /home/${appUser} ${appUser}
		echo Se6m58b\& |passwd --stdin ${appUser}
		su - ${appUser} -c "echo export PATH=\$PATH:/usr/cti/apps/babysitter >> /home/${appUser}/.bashrc"
	fi


}

del_from_sudo () {

	echo "INFO: Deleting previous entry for $appUser in $sudoFile"
	sed -i.${Date} -e '/.*SEMUS.*/d' -e '/.*Allows\s*'$appUser'\s*user/d' $sudoFile

}

add_to_sudo () {

	echo "INFO: Adding $appUser to $sudoFile"
	/bin/cp -f ${sudoFile} ${sudoFile}.${Date}

cat >> ${sudoFile} <<+++
##Allows ${appUser} user to execute Babysitter commands on this system
Cmnd_Alias SEMUSCMD = /usr/cti/apps/babysitter/MamCMD, /usr/bin/MamCMD
User_Alias SEMUS=${appUser}, %root
SEMUS ALL=NOPASSWD:SEMUSCMD

+++
}

remove_semus () {

	del_from_sudo
	
	echo "INFO: Deleting ${appUser} from this system"
	userdel -r ${appUser}
	
	exit 0

}

#### MAIN
check_pre

case $action in
	-h|-help) echo -e "\n\tThe script adds ${appUser} user to the system (executed without parameters)\n\n\tUSAGE: $0 <-h|help> <-uninstall>\n"
			  exit
	;;
	-uninstall) remove_semus
	;;
esac

create_user

numOfsemus=`grep SEMUS $sudoFile |wc -l`
if [ $numOfsemus -eq 0 ]; then
	add_to_sudo
elif [ $numOfsemus -gt 0 ] && [ $numOfsemus -lt 3 ]; then
	del_from_sudo
	add_to_sudo
elif [ $numOfsemus -eq 3 ]; then
	echo "INFO: semus is already part of $sudoFile"
fi


