#!/bin/bash
# Written by Gregory Danenberg, used to install scdb on OMU before any other package

############################
Usage () {
############################

PARENT=`ps --no-heading -o %c -p $PPID`

if [[ "$PARENT" =~ "decompress.sh" ]]; then
	echo -e "${bold} -E- Something wrong with this package version. Unable to proceed${end}"
else
	
cat <<USAGE
	
	USAGE: 
		$0 -install
		
		$0 -uninstall
		 *** ALL components (SCDB SWIM JAVA TOMCAT) will be uninstalled
		
		$0 -uninstall=[List of componets to uninstall separated by comma]
		 *** supported values: SCDB,SWIM,JAVA,TOMCAT
		
		$0 -help
		
USAGE

fi

exit 1

}

############################
findLocation () {
############################
	local rpmName=$1
	local compName=$2

	#find should start at component folder to avoid possible duplications
	local rpmLoc=$(find $compName -name ${rpmName}*.rpm -type f)

	if [ -z $rpmLoc ]; then
		echo -e "${bold} -E- Failed to find $rpmName${end}"
		exit 1
	fi
	
	if [ ! -f $rpmLoc  ]; then
		echo -e "${bold} -E- Something wrong with $rpmName rpm location: $rpmLoc${end}"
		exit 1
	fi
	
	echo "$rpmLoc"


}

############################
installRPM () {
############################
	local rpmDir=$1
	local rpmInstall=$2
	
	currDir=`pwd`
	cd $rpmDir || (echo -e "${bold} -E- Failed to visit $rpmDir${end}" && exit 1)
	
	#if [[ "$rpmInstall" =~ "scdb" ]]; then
	#	rpm -ivh --noscripts $rpmInstall &> stdout.temp
	#else
		rpm -ivh $rpmInstall &> stdout.temp
	#fi
	
	if [ $? -ne 0 ]; then
		echo -e "${bold} -E- Failed to install $rpmInstall ==>${end}"
		cat stdout.temp
		/bin/rm -f stdout.temp
		exit 1
	fi

	/bin/rm -f stdout.temp
	cd $currDir

}

############################
isInstalled () {
############################
	local rpmName=$1
	
	rpm -q $rpmName >> /dev/null

	return $?
	
}

############################
uninstall_java () {
############################
	local rpmName=$1
	local compName=$2
	
	rpm -e $rpmName &> stdout.temp
	
	if [ $? -eq 1 ]; then
		echo -e "${bold} -E- Failed to remove $compName component${end}"
		cat stdout.temp
		/bin/rm -f stdout.temp
		exit 1
	fi
		
	/bin/rm -f stdout.temp

}

############################
install_java () {
############################
	local rpmName=$1
	local compName=$2
		
	local rpmLoc=$(findLocation $rpmName $compName)
	
	local rpmDir=$(dirname $rpmLoc)
	local rpmInstall=$(basename $rpmLoc)
	
	installRPM $rpmDir $rpmInstall 
	

}

############################
uninstall_tomcat () {
############################
	local rpmName=$1
	local compName=$2
	
	rpm -e $rpmName &> stdout.temp
	
	if [ $? -eq 1 ]; then
		echo -e "${bold} -E- Failed to remove $compName component${end}"
		cat stdout.temp
		/bin/rm -f stdout.temp
		exit 1
	fi
		
	/bin/rm -f stdout.temp

}

############################
install_tomcat () {
############################
	local rpmName=$1
	local compName=$2
	
	local rpmLoc=$(findLocation $rpmName $compName)
	
	local rpmDir=$(dirname $rpmLoc)
	local rpmInstall=$(basename $rpmLoc)
	
	installRPM $rpmDir $rpmInstall	

}

############################
uninstall_scdb () {
############################
	local rpmName=$1
	local compName=$2
	
	su - scdb_user -c "/usr/cti/apps/scdb/catalinaBase/bin/scdb.sh stop" &> /dev/null
	
	#some work need to do in hands..
	grep scdb /etc/sudoers &> /dev/null
	if [ $? -eq 0 ]; then
		sed -i 's/scdb_user.*//g' /etc/sudoers
	fi
	
	#there a bug in uninstall section of scdb rpm
	#rpm -e --noscripts $rpmName &> stdout.temp
	rpm -e $rpmName &> stdout.temp
		
	if [ $? -eq 1 ]; then
		echo -e "${bold} -E- Failed to remove $compName component${end}"
		cat stdout.temp
		/bin/rm -f stdout.temp
		exit 1
	fi
	
	for dr in /usr/cti/apps/scdb /usr/cti/conf/scdb /var/cti/logs/scdb; do
		[ -d $dr ] && /bin/rm -rf $dr
	done
	
	/bin/rm -f stdout.temp
	/bin/rm -f /var/tmp/scdb_answer
	

}

############################
install_scdb () {
############################
	local rpmName=$1
	local compName=$2
	
	regLoc=$(find SAF-UAF-SCDB/SCDB -name $regName -type f)
	if [[ -z $regLoc || ! -f $regLoc ]]; then
		echo -e "${bold} -E- Failed to find ${regName}${end}"
		exit 1
	fi

	regSWIMLoc=$(find SAF-UAF-SCDB/SCDB -name $regSWIMName -type f)
	if [[ -z $regSWIMLoc || ! -f $regSWIMLoc ]]; then
		echo -e "${bold} -E- Failed to find ${regSWIMLoc}${end}"
		exit 1
	fi	
	
	local rpmLoc=$(findLocation $rpmName $compName)
	
	local rpmDir=$(dirname $rpmLoc)
	local rpmInstall=$(basename $rpmLoc)	

	local answerFile=${rpmDir}/scdb_answer_file_linux
	
	if [ ! -f $answerFile ]; then
		echo -e "${bold} -E- Failed to find $answerFile${end}"
		exit 1
	fi
	
	sed -e  's/Monitoring_Type=.*/Monitoring_Type=None/' \
		-e 	's#ShareLocation=.*#ShareLocation=/var/cti/temp#' \
		-e	's/ACTION_REGISTER_TO_BACKUP=.*/ACTION_REGISTER_TO_BACKUP=false/' \
		-e	's/ACTION_REGISTER_TO_CCM=.*/ACTION_REGISTER_TO_CCM=false/' \
		-e 	's/ACTION_REGISTER_TO_SB=.*/ACTION_REGISTER_TO_SB=false/' \
		-e	's/ACTION_REGISTER_TO_AAS=.*/ACTION_REGISTER_TO_AAS=false/' \
		-e	's/ACTION_REGISTER_TO_SYSLOG=.*/ACTION_REGISTER_TO_SYSLOG=false/' \
		-e 	's/ACTION_CLUSTER_MAKE_ONLINE=.*/ACTION_CLUSTER_MAKE_ONLINE=false/' \
		-e	's/ACTION_FORCE_ACTIVE_NODE=.*/ACTION_FORCE_ACTIVE_NODE=false/' \
		-e 	's/ACTION_GENERATE_UG=.*/ACTION_GENERATE_UG=false/' \
		-e 	's/ACTION_GENERATE_SL=.*/ACTION_GENERATE_SL=false/' \
		-e  's/Bind_To_IP=.*/Bind_To_IP=0.0.0.0/' \
		-e 	's#Java_Path=.*#Java_Path=/usr/java/jre1.7#' $answerFile > /var/tmp/scdb_answer
		
	installRPM $rpmDir $rpmInstall
	
	#manual post installation for scdb
	#currDir=`pwd`
	#cd /usr/cti/apps/scdb/scdb-install/installation/scripts
	#sed -i 's/$RESULT=`rpm -qa \"CSP\*\"`/#$RESULT=`rpm -qa "CSP*"`\n\t\t$RESULT=\"manaul_workaround\"/' scdb_install.pl
	#./scdb_install.pl install &> stdout.temp
	#grep "scdb_install.pl completed successfully" stdout.temp &> /dev/null
	#if [ $? -ne 0 ]; then
		#echo -e "${bold} -E- Failed to perform manual post install with /usr/cti/apps/scdb/scdb-install/installation/scripts/scdb_install.pl install${end}"
		
		#cat stdout.temp
		#/bin/rm -f stdout.temp		
		#uninstall_scdb
	#	exit 1
	#fi
	#/bin/rm -f stdout.temp
	#cd $currDir	

	if [ ! -f /usr/cti/conf/scdb/parameters.xml ]; then
		echo -e "${bold} -E- Failed to find /usr/cti/conf/scdb/parameters.xml${end}"
		uninstall_scdb
		exit 1
	fi
	
	sed -i -e '/Name=.*StandaloneAuthentication/,/\/Parameter/{s/Value=.false./Value="true"/}' \
		   -e '/Name=.*RegFileName/,/\/Parameter/{s/registrations_OMAP.xml/'$regName'/}'	/usr/cti/conf/scdb/parameters.xml
	
	/bin/rm -f /usr/cti/conf/scdb/registrations_*.xml
	/bin/cp -f $regLoc /usr/cti/conf/scdb/ &> stdout.temp
	if [ $? -eq 1 ]; then
		echo -e "${bold} -E- Failed to copy $regLoc to /usr/cti/conf/scdb/${end}"
		cat stdout.temp
		uninstall_scdb
		/bin/rm -f stdout.temp
		exit 1
	fi
	chown scdb_user:scdb $regLoc
	
	/bin/cp -f $regSWIMLoc /usr/cti/conf/scdb/ &> stdout.temp
	if [ $? -eq 1 ]; then
		echo -e "${bold} -E- Failed to copy $regSWIMLoc to /usr/cti/conf/scdb/${end}"
		cat stdout.temp
		uninstall_scdb
		/bin/rm -f stdout.temp
		exit 1
	fi
	chown scdb_user:scdb $regSWIMLoc
	
	#find $compName -name scdb.xml -type f -exec /bin/cp -f {} /var/cti/temp/scdb/data/ \; &> stdout.temp
	scdbLoc=$(find SAF-UAF-SCDB/SCDB -name scdb.xml -type f)
	if [ -z $scdbLoc ]; then
		echo -e "${bold} -E- Failed to find template for scdb.xml${end}"
		uninstall_scdb
		exit 1
	fi
	
	/bin/cp -f $scdbLoc /var/cti/temp/scdb/data/ &> stdout.temp
	if [ $? -eq 1 ]; then
		echo -e "${bold} -E- Failed to copy template of scdb.xml to /var/cti/temp/scdb/data/${end}"
		cat stdout.temp
		uninstall_scdb
		/bin/rm -f stdout.temp
		exit 1
	fi
	chown scdb_user:scdb $scdbLoc
	echo " -I- scdb.xml template was copied to /var/cti/temp/scdb/data"
	
	#work around for slow startup
	sed -i 's/sleep\s*10/sleep 30/' /usr/cti/apps/scdb/catalinaBase/bin/scdb.sh
	echo " -I- initializing scdb application, be patient..."
	#su - scdb_user -c '$CATALINA_BASE/bin/scdb.sh start' &> stdout.temp
	su - scdb_user -c "/usr/cti/apps/scdb/catalinaBase/bin/scdb.sh start" &> stdout.temp
	if [ $? -eq 0 ]; then
		echo " -I- scdb application started successfully"
	else
		echo -e "${bold} -E- Failed to start scdb application. See scdb log file to find out the reason${end}"
		cat stdout.temp	
	fi
	
	/bin/rm -f stdout.temp
	/bin/rm -f /var/tmp/scdb_answer
	
}

############################
uninstall_swim () {
############################
	local rpmName=$1
	local compName=$2

	/usr/cti/apps/swim/bin/rootStop.sh &> /dev/null

	rpm -e $rpmName &> stdout.temp
	
	if [ $? -eq 1 ]; then
		echo -e "${bold} -E- Failed to remove $compName component${end}"
		cat stdout.temp
		/bin/rm -f stdout.temp
		exit 1
	fi
		
	/bin/rm -f stdout.temp	
		
}

############################
install_swim () {
############################
	local rpmName=$1
	local compName=$2
	
	local rpmLoc=$(findLocation $rpmName $compName)
	
	local rpmDir=$(dirname $rpmLoc)
	local rpmInstall=$(basename $rpmLoc)

	if [ -f $rpmDir/install_SWIM.sh ]; then
		chmod +x $rpmDir/install_SWIM.sh
		currDir=`pwd`
		cd $rpmDir || (echo -e "${bold} -E- Failed to visit $rpmDir${end}" && exit 1)
		./install_SWIM.sh &> stdout.temp
	
		if [ $? -ne 0 ]; then
			echo -e "${bold} -E- Failed to execute install_SWIM.sh ==>${end}"
			cat stdout.temp
			/bin/rm -f stdout.temp
			exit 1
		fi
	else	
		installRPM $rpmDir $rpmInstall
	fi
	
	/bin/rm -f stdout.temp
	cd $currDir
	
	if [ -f /usr/cti/conf/swim/swim/parameters.xml ]; then
		if [ $isVM -eq 0 ]; then
			sed -i.${Date} -e '/Name=.UnitTypeFilterList/,/\/Parameter/{s#<Value/>#<Value>\n\t\t<Item Value="LBA_Group"/>\n\t\t<Item Value="IBM-BC_Group"/>\n\t\t<Item Value="HSBU_Group"/>\n\t\t<Item Value="OSS_BSS_Layer"/>\n\t\t<Item Value="vManagement_Group"/>\n\t\t<Item Value="NetApp_Group"/>\n\t</Value>#}' \
			-e  '/Name=.RemoteExecutionDefaultUsername/,/\/Parameter/{s#<Item Value=.swima./>#<Item Value=\"root\"/>#}' \
			-e '/Name=.RemoteExecutionDefaultPassword/,/\/Parameter/{s#<Item Value=.79y9DK2VWqTvtuP0SMR5xw==./>#<Item Value=\"wX3PpHRbi4kEAFYlRU3v2A==\"/>#}' \
			-e '/Name=.FileTransferDefaultUsername/,/\/Parameter/{s#<Item Value=.swima./>#<Item Value=\"root\"/>#}' \
			-e '/Name=.FileTransferDefaultPassword/,/\/Parameter/{s#<Item Value=.79y9DK2VWqTvtuP0SMR5xw==./>#<Item Value=\"wX3PpHRbi4kEAFYlRU3v2A==\"/>#}' \
			-e '/Name=.FilterUnitsWithoutLogicalApplication/,/\/Parameter/{s#<Item Value=.false./>#<Item Value=\"true\"/>#}' /usr/cti/conf/swim/swim/parameters.xml
		else
			sed -i.${Date} -e '/Name=.UnitTypeFilterList/,/\/Parameter/{s#<Value/>#<Value>\n\t\t<Item Value="LBA_Group"/>\n\t\t<Item Value="IBM-BC_Group"/>\n\t\t<Item Value="HSBU_Group"/>\n\t\t<Item Value="OSS_BSS_Layer"/>\n\t\t<Item Value="NetApp_Group"/>\n\t</Value>#}' \
			-e  '/Name=.RemoteExecutionDefaultUsername/,/\/Parameter/{s#<Item Value=.swima./>#<Item Value=\"root\"/>#}' \
			-e '/Name=.RemoteExecutionDefaultPassword/,/\/Parameter/{s#<Item Value=.79y9DK2VWqTvtuP0SMR5xw==./>#<Item Value=\"wX3PpHRbi4kEAFYlRU3v2A==\"/>#}' \
			-e '/Name=.FileTransferDefaultUsername/,/\/Parameter/{s#<Item Value=.swima./>#<Item Value=\"root\"/>#}' \
			-e '/Name=.FileTransferDefaultPassword/,/\/Parameter/{s#<Item Value=.79y9DK2VWqTvtuP0SMR5xw==./>#<Item Value=\"wX3PpHRbi4kEAFYlRU3v2A==\"/>#}' /usr/cti/conf/swim/swim/parameters.xml
		fi
	fi

	mkdir -p /var/cti/data/swim/systems /var/cti/data/swim/kits /var/cti/data/swim/swimAgentKits/Linux
	
	agentLoc=$(find $compName -name Agent -type d)
	if [ ! -d $agentLoc ]; then
		echo -e "${bold} -E- Failed to find $compName Agent directory under $compName ${end}"
		exit 1
	fi

	/bin/cp -r $agentLoc/* /var/cti/data/swim/swimAgentKits/Linux/
	
	if [ -d /var/cti/data/swim/swimAgentKits/Solaris ]; then
		/bin/rm -rf /var/cti/data/swim/swimAgentKits/Solaris
	fi	

	#prepare SAF UAF and so on
	for sys in "${SWIM_SYSTEMS[@]}"; do
	
		if [ -d SAF-UAF-SCDB/${sys} ]; then
			if [ ! -d /var/cti/data/swim/systems/${sys} ]; then
				/bin/cp -r SAF-UAF-SCDB/${sys} /var/cti/data/swim/systems/ &> stdout.temp
				if [ $? -eq 0 ]; then
					#remove crap from system folder
					find /var/cti/data/swim/systems/${sys} ! \( -name "*UAF.xml" -o -name "*SAF.xml" \) -type f -exec /bin/rm -f {} \;
					chown -R swim:swim /var/cti/data/swim/systems/${sys}
					echo " -I- created /var/cti/data/swim/systems/${sys}"
					
					if [ -f $convToPhysScript ]; then
						/bin/cp -f $convToPhysScript /var/cti/data/swim/systems/
						chmod +x /var/cti/data/swim/systems/${convToPhysScript}
					fi
				else
					echo -e "${bold} -E- Failed to create /var/cti/data/swim/systems/${sys}${end}"
					cat stdout.temp	
				fi
			else
				backupUAFDir=/var/cti/data/swim/systems/${sys}/backup_${Date}
				
				if [ -d $swimUAFDir ]; then
					echo -e " -I- Backup content of ${sys} under ${backupUAFDir}"
					mkdir -p ${backupUAFDir}
					find /var/cti/data/swim/systems/${sys} -maxdepth 1 -name logs -prune -o -type f -print -exec /bin/cp -f {} ${backupUAFDir} \; &> /dev/null
					echo -e " -I- Copy new swim assembly files to /var/cti/data/swim/systems/${sys}"
					/bin/cp -f SAF-UAF-SCDB/${sys}/*.xml /var/cti/data/swim/systems/${sys}/
				
				else
					/bin/cp -r SAF-UAF-SCDB/${sys} /var/cti/data/swim/systems/
					if [ $? -eq 0 ]; then
						#remove crap from system folder
						find ${swimUAFDir} ! \( -name "*UAF.xml" -o -name "*SAF.xml" \) -type f -exec /bin/rm -f {} \;
						chown -R swim:swim ${swimUAFDir}
						echo " -I- created ${swimUAFDir}"
					else
						echo -e "${bold} -E- Failed to create /var/cti/data/swim/systems/${sys}${end}"
						cat stdout.temp	
					fi
				fi
			fi
		else
			echo -e "${bold} -W- Failed to find ${sys} directory in installation kit${end}"
			echo -e "${bold} -W- ${sys} will NOT be created on /var/cti/data/swim/systems${end}"
		fi
	done		
	
	chown -R swim:swim /var/cti/data/swim
	chmod -R 755 /var/cti/data/swim	

        echo " -I- initializing swim application"
        /usr/cti/apps/swim/bin/rootStart.sh &> stdout.temp
        if [ $? -eq 0 ]; then
                echo " -I- swim application started successfully"
        else
                echo -e "${bold} -E- Failed to start swim application. See swim log file to find out the reason${end}"
                cat stdout.temp
        fi
	
	/bin/rm -f stdout.temp
	
}

upgrade_swim () {

	local rpmName=$1
	local compName=$2
	
	local rpmLoc=$(findLocation $rpmName $compName)
	
	local rpmDir=$(dirname $rpmLoc)
	local rpmInstall=$(basename $rpmLoc)
	
	local rpmNewVer=`rpm -qp --qf '%{VERSION}' $rpmLoc|sed 's/\.//g'`
	local rpmNewRel=`rpm -qp --qf '%{RELEASE}' $rpmLoc`
	
	local rpmInstalledVer=`rpm -q --qf '%{VERSION}' $rpmName|sed 's/\.//g'`
	local rpmInstalledRel=`rpm -q --qf '%{RELEASE}' $rpmName`
	
	if [[ $rpmNewVer -gt $rpmInstalledVer || $rpmNewRel -gt $rpmInstalledRel ]]; then
		echo -e "${bold} -I- Upgrading SWIM Manager version${end}"
		
		/usr/cti/apps/swim/bin/rootStop.sh &> /dev/null
		
		if [ -f $rpmDir/upgrade_SWIM.sh ]; then
			chmod +x $rpmDir/upgrade_SWIM.sh
			currDir=`pwd`
			cd $rpmDir || (echo -e "${bold} -E- Failed to visit $rpmDir${end}" && exit 1)
			./upgrade_SWIM.sh &> stdout.temp
	
			if [ $? -ne 0 ]; then
				echo -e "${bold} -E- Failed to execute upgrade_SWIM.sh ==>${end}"
				cat stdout.temp
				/bin/rm -f stdout.temp
				exit 1
			fi
		else	
			echo -e "${bold} -E- Failed to find upgrade_SWIM.sh script${end}"
			exit 1
		fi
		
		/bin/rm -f stdout.temp
		cd $currDir
		
        /usr/cti/apps/swim/bin/rootStart.sh &> stdout.temp
        if [ $? -eq 0 ]; then
                echo " -I- swim application started successfully"
        else
                echo -e "${bold} -E- Failed to start swim application. See swim log file to find out the reason${end}"
                cat stdout.temp
        fi
	
		/bin/rm -f stdout.temp		

		echo -e "${bold} -I- Updating SWIM Agent installation folder${end}"
		agentLoc=$(find $compName -name Agent -type d)
		if [ -z $agentLoc ]; then
			echo -e "${bold} -E- Failed to find $compName Agent directory under $compName ${end}"
			exit 1
		fi
		/bin/rm -f /var/cti/data/swim/swimAgentKits/Linux/*
		/bin/cp -r $agentLoc/* /var/cti/data/swim/swimAgentKits/Linux/
		
		if [ -d /var/cti/data/swim/swimAgentKits/Solaris ]; then
			/bin/rm -rf /var/cti/data/swim/swimAgentKits/Solaris
		fi
		
	
	fi

	for sys in "${SWIM_SYSTEMS[@]}"; do
		
		backupUAFDir=/var/cti/data/swim/systems/${sys}/backup_${Date}
		swimUAFDir=/var/cti/data/swim/systems/${sys}
		
		if [ -d SAF-UAF-SCDB/${sys} ]; then
			if [ -d $swimUAFDir ]; then
				echo -e " -U- Backup content of ${sys} under ${backupUAFDir}"
				mkdir -p ${backupUAFDir}
				find ${swimUAFDir} -maxdepth 1 -name logs -prune -o -type f -print -exec /bin/cp -f {} ${backupUAFDir} \; &> /dev/null
				echo -e " -U- Copy fresh swim assembly files to ${swimUAFDir}"
				/bin/cp -f SAF-UAF-SCDB/${sys}/*.xml ${swimUAFDir}/
			else
				/bin/cp -r SAF-UAF-SCDB/${sys} /var/cti/data/swim/systems/
				if [ $? -eq 0 ]; then
					#remove crap from system folder
					find ${swimUAFDir} ! \( -name "*UAF.xml" -o -name "*SAF.xml" \) -type f -exec /bin/rm -f {} \;
					chown -R swim:swim ${swimUAFDir}
					echo " -U- created ${swimUAFDir}"
				else
					echo -e "${bold} -E- Failed to create /var/cti/data/swim/systems/${sys}${end}"
					cat stdout.temp	
				fi
			fi
		else
			echo -e "${bold} -W- Failed to find ${sys} directory in installation kit${end}"
			echo -e "${bold} -W- ${sys} will NOT be created/updated on /var/cti/data/swim/systems${end}"
		fi
	done

}

############################
map_rpm () {
############################

	for comp in "${APPS_TO_INSTALL[@]}"; do
	
		case $comp in
			SCDB) RPM_NAMES_INSTALL=( "${RPM_NAMES_INSTALL[@]}" "scdb")
			;;
			JAVA) RPM_NAMES_INSTALL=( "${RPM_NAMES_INSTALL[@]}" "swp-jre")
			;;
			TOMCAT) 
                                        #if [ $RH_REL -eq 6 ]; then
                                        #       RPM_NAMES_INSTALL=( "${RPM_NAMES_INSTALL[@]}" 'swp-tomcat7*noarch')
                                        #else
                                        #       RPM_NAMES_INSTALL=( "${RPM_NAMES_INSTALL[@]}" 'swp-tomcat7*i386')
                                        #fi
                                        RPM_NAMES_INSTALL=( "${RPM_NAMES_INSTALL[@]}" 'swp-tomcat7')
			;;
			SWIM) RPM_NAMES_INSTALL=( "${RPM_NAMES_INSTALL[@]}" "SWIM")
			;;
			*)  echo "ERROR: Unable to map $comp to rpm name"
				exit 1
			;;
		esac
	
	done
	
}

## MAIN
export Date=`date +%m%d%Y_%H%M%S`
export serverIP=`ifconfig -a|grep "inet addr"|head -1|perl -ne '/:(\d+\.\d+.\d+\.\d+)\s+/ ; print $1'`
export hostName=`hostname`
export end='\E[m'
export bold='\E[1m'
export displayFullHelp=1

uname -a|grep el6.x86_64 > /dev/null
if [ $? -eq 0 ]; then
	export RH_REL=6
else
	export RH_REL=5
fi

#if [ `hostname` =~ "deploySRV" ]; then
hostname|grep -i deploySRV > /dev/null
if [ $? -eq 0 ]; then
	export isVM=1
else
	export isVM=0
fi


##########  CUST PARAMETERS ###############################################
#should be the same as registrations_swim_only.xml in SAF-UAF-SCDB/SCDB
if [ $isVM -eq 0 ]; then
	declare -a SWIM_SYSTEMS=(SEM-HBASE SEM-DSU SEM-OMU SEM-APP SEM-APP-RH5 SEM-GR)
	export regName=registrations_swim_only.xml
	export regSWIMName=swimOnlyRegistrations.xml
else
	declare -a SWIM_SYSTEMS=(VM-DEPLOY)
	export regName=registrations_swim_only_vm.xml
	export regSWIMName=swimOnlyRegistrations.xml
fi
###########################################################################


declare -a APPS_TO_INSTALL
declare -a RPM_NAMES_INSTALL

convToPhysScript=convert-NW-to-Phys.sh

declare -a input=($*)

if [ ${#input[@]} -eq 0 ]; then
	Usage
fi

for arg in "${input[@]}"; do
	case "$arg" in
		-help|-h|-usage) Usage
		;;
		-install)
			APPS_TO_INSTALL=(JAVA TOMCAT SCDB SWIM)
			map_rpm
			export ACTION=install
		;;
		-uninstall)
			APPS_TO_INSTALL=(SCDB SWIM TOMCAT JAVA) 
			map_rpm
			export ACTION=uninstall
		;;
		-uninstall=*) comp=${arg#*=}
					  APPS_TO_INSTALL=(`echo $comp|tr ',' ' '`)
					  map_rpm
					  export ACTION=uninstall
		;;
		*) Usage ;;
	esac
done


total=${#APPS_TO_INSTALL[*]}
for ((i=0; i<=$(($total -1)); i++ )); do
	
	isInstalled  ${RPM_NAMES_INSTALL[$i]}
	rc=$?
	
	if [ $ACTION == "install" ]; then
		if [ $rc -eq 0 ]; then
			if [ ${APPS_TO_INSTALL[$i]} == "SWIM" ]; then
				upgrade_swim ${RPM_NAMES_INSTALL[$i]} ${APPS_TO_INSTALL[$i]}
				displayFullHelp=0
				continue
			else
				echo -e "${bold} -W- ${APPS_TO_INSTALL[$i]} is already installed, skipping to the next component${end}"
				continue
			fi
		fi
	elif [ $ACTION == "uninstall" ]; then
		if [ $rc -eq 1 ]; then
			echo -e "${bold} -W- ${APPS_TO_INSTALL[$i]} is not installed, skipping to the next component${end}"
			continue
		fi
	else
		echo -e "${bold} -E- Action type should be either uninstall or install only ${end}"
		exit 1
	fi

	echo " -I- ${ACTION}ing ${APPS_TO_INSTALL[$i]} component"	
	
	case ${APPS_TO_INSTALL[$i]} in
		
		JAVA) 	${ACTION}_java	${RPM_NAMES_INSTALL[$i]} ${APPS_TO_INSTALL[$i]}
		;;
		TOMCAT) ${ACTION}_tomcat	${RPM_NAMES_INSTALL[$i]} ${APPS_TO_INSTALL[$i]}
		;;
		SCDB)	${ACTION}_scdb	${RPM_NAMES_INSTALL[$i]} ${APPS_TO_INSTALL[$i]}	
		;;
		SWIM)	${ACTION}_swim	${RPM_NAMES_INSTALL[$i]} ${APPS_TO_INSTALL[$i]}
		;;
		
		*)  echo -e "${bold} -E- ${APPS_TO_INSTALL[$i]} component ${ACTION}ation is not implemented yet${end}"
			exit 1
		;;
	esac	

done

if [[ $ACTION == "install" && $displayFullHelp -eq 1 ]]; then

echo -e "${bold}\n\n\n\t\t*************   WHAT TO DO NEXT ? *************\n\n${end}"
cat <<EOF
	1) Browse to https://$serverIP:5788/scdb and login with root/comverse
	   Note, scdb.xml temporary location is on /var/cti/temp/scdb/data/scdb.xml
	
	2) When scdb is ready, go to "ACTIONS" tab and perform "Deploy SCDB". 
	   UnitGroup.xml, SystemList.xml and scdb.xml will be copied to SWIM folders

	3) Complete SWIM preparations (Note, system folders were prepared for you automatically)
	
	4) This package will be uninstalled automatically during OMAP servers installation
	   If, for some reason, you need to uininstall it manually, get script help to figure out what the options are
	   /var/cti/temp/scdb/install/scdb_swim_installer.sh -help
	   
	5) Browse to https://$serverIP:55100/swim , login with swim/J6_W18fk and proceed with the rest of your product installation
	
	

	
EOF

else

	echo -e "${bold}\n\n\n\t\t*************   WHAT TO DO NEXT ? *************\n\n${end}"
	echo -e "\t Refer installation instructions doc and make sure you use most updated scdb.xml file"
	echo -e "\t Browse to https://$serverIP:55100/swim , login with swim/J6_W18fk and proceed with the rest of your product installation"
	echo -e "\n\n\n\n"

fi
