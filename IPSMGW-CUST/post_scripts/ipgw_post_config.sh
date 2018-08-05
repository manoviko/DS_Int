#!/bin/bash
#Written by Gregory Danenberg, Post installation and configuration of IPGW 5.0

Host=`hostname`
ParserLocation=/home/smsc/autoconfig.all/scripts
ParserName=parser.pl
export Parser=${ParserLocation}/${ParserName}

IPGWBaseDir=/home/smsc/site/config
AutoBaseDir=/usr/cti/conf/autoconf
RollPath=/var/cti/rollback

export UnitFile=${AutoBaseDir}/UnitGroup.xml
export topologiesSite=/home/smsc/site/config/IPGW.1/topologiesSite.config

export LOG=${IPGWBaseDir}/IPGW.PostInstall.log
export Date=`date '+%d%m%Y%H%M'`

########################
print_log() {
########################
	echo "#`date +%m/%d/%y#%H:%M:%S`#$@ " |tee -a $LOG
}

########################
Usage() {
########################
	print_log "  Usage: `basename $0` [scratch | upgrade]"
	exit
}

########################
PreInstall_Check() {
########################
	if [ "`whoami`" != "root" ]; then
		print_log "PreInstall_Check[ERROR] Script must be executed as root"
		exit 1
	fi
	
	if [ ! -x ${Parser} ]; then
		print_log "PreInstall_Check[ERROR] ${Parser} not found. Exit..."
		exit 1
	fi
}

########################
Setup_control_channel() {
########################

	print_log "Setup_control_channel[INFO] setting IPGW.${IPGW_INST} for control_channel configuration files"
	for f in ${IPGWBaseDir}/IPGW.${IPGW_INST}/control_channel.config ${IPGWBaseDir}/IPGW.${IPGW_INST}/control_channel.config_ccm-metadata.xml; do
		if [ -f $f ]; then
			sed -i -e 's/IPGW.1.1/IPGW.'$IPGW_INST'/' $f
		else
			print_log "Setup_control_channel[ERROR] $f does not exist on $Host"
		fi
	done

}

########################
Rename_ccm-declare() {
########################
	CCM_DECLARE_DIR=/usr/cti/conf/ccm-register/sms_declare

	if [ -f ${CCM_DECLARE_DIR}/IPGW.1.1_ccm-declare.xml ]; then
		print_log "Rename_ccm-declare[INFO] setting IPGW.${IPGW_INST} instance on IPGW.1.1_ccm-declare.xml"
		/bin/mv ${CCM_DECLARE_DIR}/IPGW.1.1_ccm-declare.xml ${CCM_DECLARE_DIR}/IPGW.${IPGW_INST}_ccm-declare.xml
		sed -i -e 's/IPGW.1.1/IPGW.'$IPGW_INST'/g' ${CCM_DECLARE_DIR}/IPGW.${IPGW_INST}_ccm-declare.xml
		if [ -f ${CCM_DECLARE_DIR}/IPGW.1.2_ccm-declare.xmle ]; then
			rm -f ${CCM_DECLARE_DIR}/IPGW.1.2_ccm-declare.xmle
		fi
	else
		print_log "Rename_ccm-declare[ERROR] did not find ${CCM_DECLARE_DIR}/IPGW.1.1_ccm-declare.xml, skipping ..."
	fi
}

########################
Setup_SGAPClients() {
########################

	SGAPClients=/home/smsc/site/config/IPGW.${IPGW_INST}/SGAPClients.config
	
	if [ ! -f $SGAPClients ]; then
		print_log "Setup_SGAPClients[ERROR] $SGAPClients is not found on this unit, abort installation"
		exit 1
	fi
	
	#local SCA_Count=`${Parser} ${UnitFile} l/SCA//InstanceName -c`
	print_log "Setup_SGAPClients[INFO] Going to execute ${Parser} ${UnitFile} l/SCA//UnitName"
	declare -a SCA_Inst=(`${Parser} ${UnitFile} l/SCA//UnitName`)
	if [[ $? -ne 0 ]] || [[ "${SCA_Inst[0]}" =~ "ERROR" ]]; then
		print_log "Setup_SGAPClients[ERROR] Failed to get SCA instances info. Skipping on SCA connector configuration"
		exit 1
	fi
	
	print_log "Setup_SGAPClients[INFO] setting SGAP connectors in $SGAPClients"
	#sed -i -e '/^\s*SGAPClient_[0-9].*/d' $SGAPClients
	sed -i -e '/SGAPClient_.*.extends.*/,/SGAPClient_.*.port.*\n/d' $SGAPClients

	#echo -e "\n# SGAP connectors" >> ${SGAPClients}
	for (( i=1,s=0;i <= ${#SCA_Inst[@]}; i++,s++)); do
		echo "SGAPClient_${i}.extends=SGAPAccessService" >> ${SGAPClients}
		echo "SGAPClient_${i}.sg_address=${SCA_Inst[${s}]}" >> ${SGAPClients}
		echo "SGAPClient_${i}.sg_port=38000" >> ${SGAPClients}
		echo "SGAPClient_${i}.sgapi_application_id=${IPGW_ID}" >> ${SGAPClients}	

		SCA_ID=(`${Parser} ${UnitFile} l/SCA/${SCA_Inst[${s}]}/InstanceName`)
		if [[ $? -ne 0 ]] || [[ "$SCA_ID" =~ "ERROR" ]]; then
			print_log "setup_SGAPClients[ERROR] Failed to get SCA instance id for ${SCA_Inst[${s}]}. Skipping on SCA connector configuration"
			echo "" > ${SGAPClients}
			return
		fi
		#Requested by Nir Kon, changing instance from 1.1 to 1:1
		SCA_ID=$(echo $SCA_ID|tr '.' ':')
		echo "SGAPClient_${i}.ei_group_instance=${SCA_ID}" >> ${SGAPClients}
		
		echo "" >> ${SGAPClients}
	done

	local Count=${#SCA_Inst[@]}

	echo "Topology.IPGW.layer.12.service.number=${Count}" >> ${topologiesSite}
	for i in `seq 0 $((Count-1))`;do
		echo "Topology.IPGW.layer.12.service.${i}.name=SGAPClient_$((i+1))" >> ${topologiesSite}
	done

}


############### MAIN ##############
if [ $# -lt 1 ]; then
	Usage
fi

PreInstall_Check

InstallMode=`echo $1|tr "[:upper:]" "[:lower:]"`

print_log "MAIN[INFO] Going to execute ${Parser} ${UnitFile} l/IPGW/${Host}/InstanceName"
IPGW_INST=`${Parser} ${UnitFile} l/IPGW/${Host}/InstanceName`
if [ $? -ne 0 ] || [ -z "${IPGW_INST}" ]; then
	print_log "MAIN[ERROR] IPGW instance on ${Host} is: ${IPGW_INST}"
	print_log "MAIN[ERROR] Failed to identify IPGW instance id. Can not continue"
	exit 1
else
	print_log "MAIN[INFO] IPGW instance on ${Host}: ${IPGW_INST}"
	#IPGW_Count=`${Parser} ${UnitFile} l/IPGW//InstanceName -c`
	IPGW_Count=${#IPGW_Inst[@]}	
	export IPGW_INST IPGW_Count
	
	IPGW_ID=`echo $IPGW_INST|sed 's/\.//'`
	echo $IPGW_ID|grep '^[0-9]\{2,\}$' >> $LOG
	if [ $? -ne 0 ]; then
		print_log "MAIN[ERROR] Failed to create uid for IPGW from $IPGW_INST"
		exit 1
	else
		print_log "MAIN[INFO] IPGW uid built from $IPGW_INST is $IPGW_ID"
		export IPGW_ID
	fi
fi

mkdir -p ${RollPath}/${Date}
dirToBack=`ls -d /home/smsc/site/config/IPGW.?.?|sort|tail -1`
if [ -d $dirToBack ]; then
	print_log "MAIN[INFO] Backing up $dirToBack to ${RollPath}/${Date}"
	/bin/cp -rf $dirToBack ${RollPath}/${Date}/
else
	print_log "MAIN[ERROR] Failed to find IPGW instance directory on /home/smsc/site/config"
	exit 1
fi
test -f $topologiesSite && /bin/cp -f $topologiesSite ${RollPath}/${Date}/

		
if [ "$InstallMode" = "scratch" ]; then
	if [ ! -d /home/smsc/site/config/IPGW.${IPGW_INST} ]; then
		if [ -d /home/smsc/site/config/IPGW.1.1 ]; then
			print_log "MAIN[INFO] Moving /home/smsc/site/config/IPGW.1.1 to /home/smsc/site/config/IPGW.${IPGW_INST}"
			/bin/mv /home/smsc/site/config/IPGW.1.1 /home/smsc/site/config/IPGW.${IPGW_INST}
			chown -R smsc:sys /home/smsc/site/config/IPGW.${IPGW_INST}
			chmod 755 /home/smsc/site/config/IPGW.${IPGW_INST}
		else
			print_log "MAIN[ERROR]: Don't have /home/smsc/site/config/IPGW.1.1 directory to built IPGW.${IPGW_INST}"
			exit 1
		fi
		
		Rename_ccm-declare
	fi
	#prepare trace dir for tracelaoder-cust kit
	mkdir -p /home/smsc/site/trace/IPGW.${IPGW_INST}
	chown -R smsc:sys /home/smsc/site/trace/IPGW.${IPGW_INST}
	chmod 755 /home/smsc/site/trace/IPGW.${IPGW_INST}
	
	cat > ${topologiesSite} <<+++
#Topology IPGW site
##############################
#IPGW Client connectors
+++
	
	Setup_control_channel
	Setup_SGAPClients

elif [ "$InstallMode" == "upgrade" ]; then
	print_log "MAIN[INFO] No changes have been applied on configuration files"
else
	print_log "MAIN[ERROR] InstallMode=$InstallMode is not valid! "
	Usage
fi


