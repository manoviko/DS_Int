#!/bin/bash
# Written by Gregory Danenberg, IPGW 1.0 
#  Performs MAP customizations 
#  according mapchanges.doc on http://dmstlv/dynamicUrl.aspx?DocId=2ce28678-f7ac-4fe0-9389-4ce83fcffc3e , Version: 0.1 

Host=`hostname`
ParserLocation=/home/smsc/autoconfig.all/scripts
ParserName=parser.pl
export Parser=${ParserLocation}/${ParserName}

IPGWBaseDir=/home/smsc/site/config
AutoBaseDir=/usr/cti/conf/autoconf
RollPath=/var/cti/rollback

export UnitFile=${AutoBaseDir}/UnitGroup.xml

export LOG=${IPGWBaseDir}/MAP.PostInstall.log
export Date=`date +%m%d%y%H%M%S`

CustMAPConfig=/home/smsc/cust.map.all/config/MAP/cust.MAP.config
SiteMapSFEInst=/home/smsc/site/config/MAP/site.MAP.sfe_inst.config
SMSConfigAll=/home/smsc/site/config/sms.config.all
SiteMAPConfig=/home/smsc/site/config/MAP/site.MAP.config

export MAPPortNumber=5556

#enables HLR Cache feature
export HLRCacheFet=true
export HLRCahcePortNumber=4600

#group number for HOME_ROUTING.standard_sfe_group
HLRCacheGroupNum=2

NumOfSFEGroup=`grep "group\s*=" $SiteMAPConfig|egrep -v "^#|=\s*-1"|awk -F= '{print $2}'|sort|uniq|wc -l`

########################
print_log() {
########################
	echo "#`date +%m/%d/%y#%H:%M:%S`#$@ " |tee -a $LOG
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

#######################################
BackupOrigFiles() {
#######################################

	local File=$1
	
	print_log "BackupOrigFiles[INFO]: Executing function with $File"

	if [ ! -f ${File} ]; then
		print_log "BackupOrigFiles[ERROR] ${File} does not exist, exit..."
        exit 1
	fi

	print_log "BackupOrigFiles[INFO] Backup $File to ${File}.ipgw.${Date}"
	/bin/cp -f $File ${File}.ipgw.${Date}

}

#######################################
GetParamExist() {
#######################################
	
	local File=$1
	local Par=$2
	
	print_log "GetParamExist[INFO]: Executing function with $File,$Par"
	
	egrep "^\s*${Par}\s*=" ${File} &> /dev/null
	return $?

}

#######################################
GetCurValue() {
#######################################

	local File=$1
	local Par=$2
	
	Curr=`egrep "^\s*${Par}\s*=" ${File}|awk -F= '{print $2}'`
	Curr=`echo ${Curr}|sed -e 's/^ *//' -e '/^$/d'`

	echo "$Curr"

}

#######################################
SetNewValue() {
#######################################

	local File=$1
	local Par=$2
	local Val=$3
	
	if [ "${Val}" == "NONE" ]; then
		Val=
	fi

	print_log "SetNewValue[INFO]: Executing function with $File,$Par,$Val"
	
	#GetCurValue $File $Par
	Curr=$(GetCurValue $File $Par)

	if [ "$Curr" == "$Val" ]; then
		print_log "SetNewValue[INFO] No need to replace value $Val of $Par in $File, since there are the same"
	else
		sed -i 's/^\s*'${Par}'\s*=.*$/'${Par}'='${Val}'/' $File
		
		#lets check what we did
		Curr=$(GetCurValue $File $Par)
		if [ "$Curr" == "$Val" ]; then
			print_log "SetNewValue[INFO] $Par in $File got new value: $Val"
		else
			print_log "SetNewValue[ERROR] an error occured, $Par in $File was not set to a new value: ${Val}, exit..."
			exit 1
		fi
	fi

}

#######################################
AddNewValue() {
#######################################

	if [ $# -lt 5 ]; then
		print_log "AddNewValue[ERROR] not enough parameters"
		exit 1
	fi
	
	local File=$1
	local PrevLine=$2
	local Par=$3
	local Val=$4
	local NewLine=$5	
	
	if [ "$Val" == "NONE" ]; then
		Val=
	fi

	print_log "AddNewValue[INFO]: Executing function with $File,$PrevLine,$Par,$Val,$NewLine"
	
	local SEQ=${Par/*./}
	
	if [[ "$Par" =~ "sfe_host_name" ]]; then
		SEQ=$((SEQ-1))
	fi
	
	if [ $NewLine -eq 1 ]; then
		#add new line with extra new line
		print_log "AddNewValue[INFO] Adding $Par=$Val after ${PrevLine}.${SEQ}"
		sed -i '/^'$PrevLine'\.'$SEQ'/ a\\n'$Par'='$Val'' $File
	elif [ $NewLine -eq 2 ]; then
		#no need to SEQ in parameter name
		sed -i '/^'$PrevLine'/ a\\'$Par'='$Val'' $File
	else
		#add new line with no extra new line
		print_log "AddNewValue[INFO] Adding $Par=$Val after ${PrevLine}.${SEQ} (nl)"
		sed -i '/^'$PrevLine'\.'$SEQ'/ a\\'$Par'='$Val'' $File
	fi

}

#######################################
AppendNewVal() {
#######################################
	
	if [ $# -lt 3 ]; then
		print_log "AppendNewVal[ERROR] not enough parameters"
		exit 1
	fi
	
	local File=$1
	local Par=$2
	local Val=$3
	
	print_log "AppendNewVal[INFO]: Executing function with $File,$Par,$Val"
	
	GetParamExist $File $Par
	if [ $? -eq 0 ]; then
		#GetCurValue $File $Par
		Curr=$(GetCurValue $File $Par)
		if [ "$Curr" = "$Val" ]; then
			echo "AppendNewVal[INFO]: No need to append value of $Par in $File, since curent value $Curr and new value $Val are the same"
		else
			
			CMD='print "$1\n" if /[^\w]('$Val')[^\w]/'
			ifExist=$(echo $Curr | perl -ne "$CMD")
			if [ -z $ifExist ]; then	
				sed -i 's/^'${Par}'=.*$/'${Par}'='${Curr}','${Val}'/' $File
				echo "AppendNewVal[INFO]: $Par in $File has already value: $Curr, append $Val to it"
			else
				echo "INFO: $Par in $File has already value: $Curr and $Val is already part of it"
			fi
		fi
		
	else
		echo "AppendNewVal[ERROR]: Failed to find $Par in $File, unable to append ${Val}"
		exit 1
	fi	

	
	
}

#######################################
AddNewLineParam() {
#######################################

	if [ $# -lt 5 ]; then
		print_log "AddNewLineParam[ERROR] not enough parameters"
		exit 1
	fi
	
	local File=$1
	local PrevLine=$2
	local Par=$3
	local Val=$4
	local NewLine=$5
	
	print_log "AddNewLineParam[INFO]: Executing function with $File,$PrevLine,$Par,$Val,$NewLine"
	
	GetParamExist $File $Par
	if [ $? -eq 0 ]; then
		SetNewValue $File $Par $Val
	else
		AddNewValue $File $PrevLine $Par $Val $NewLine
	fi

}

#######################################
IncreseValue() {
#######################################

	if [ $# -lt 2 ]; then
		print_log "IncreseValue[ERROR] not enough parameters"
		exit 1
	fi	

	local File=$1
	local Par=$2
	
	print_log "IncreseValue[INFO]: Executing function with $File,$Par"
	
	Curr=$(GetCurValue $File $Par)
	NewVal=$((Curr+1))
	
	print_log "IncreseValue[INFO]: Increasing $Par value in $File from $Curr to $NewVal"
	SetNewValue $File $Par $NewVal
	
}

	
#######################################
## MAIN
#######################################
print_log "MAIN[INFO] installation log is on $LOG"
PreInstall_Check

#backup conf files
BackupOrigFiles $SiteMapSFEInst
BackupOrigFiles $SiteMAPConfig
BackupOrigFiles $SMSConfigAll
BackupOrigFiles $CustMAPConfig

SetNewValue $SMSConfigAll number_of_sfes 0

SetNewValue $CustMAPConfig mtgw_sri_mode 2
SetNewValue $CustMAPConfig receive_mtgw yes
SetNewValue $CustMAPConfig mtgw_enable_home_routing true
SetNewValue $CustMAPConfig ssn '8,6'
SetNewValue $CustMAPConfig mtgw_invalidate_cache false

#########################################
## setting connectors
#########################################
print_log "MAIN[INFO] Going to execute ${Parser} ${UnitFile} l/IPGW//UnitName"
IPGW_HOSTS=(`${Parser} ${UnitFile} l/IPGW//UnitName`)
if [ $? -ne 0 ] || [ -z "${IPGW_HOSTS}" ]; then
	print_log "MAIN[ERROR] Failed to find IPGW instances on this system. Can not continue"
	exit 1
else
	#IPGW_Count=`${Parser} ${UnitFile} l/IPGW//InstanceName -c`
	IPGW_Count=${#IPGW_HOSTS[@]}	
	print_log "MAIN[INFO] IPGW instances in system: $IPGW_Count, ${IPGW_HOSTS[@]}"
	export IPGW_HOSTS IPGW_Count
fi


SetNewValue $SiteMapSFEInst MAP.number_of_sfes $IPGW_Count
SetNewValue $SiteMapSFEInst MAP.sfe_group.1.instances 1
SetNewValue $SiteMapSFEInst MAP.sfe_group.1.routing_mechanism 3

#prefix part
#tot_range=10
#hop_num=$(($tot_range/$IPGW_Count))
#hop_next=$(($hop_num-1))

for (( i=1,s=0;i <= $IPGW_Count; i++,s++)); do
	AddNewLineParam $SiteMapSFEInst MAP.sfe_ei_tcp_port_number MAP.sfe_host_name.${i} ${IPGW_HOSTS[${s}]} 1
	AddNewLineParam $SiteMapSFEInst MAP.sfe_host_name MAP.sfe_ei_tcp_port_number.${i} $MAPPortNumber 0
	AddNewLineParam $SiteMapSFEInst MAP.sfe_ei_tcp_port_number MAP.sfe_alternate_host_name.${i} "NONE"	0
	
	AppendNewVal $SiteMapSFEInst MAP.sfe_group.1.instances $i
	
	if [ $i -eq 1 ]; then
		#SetNewValue $SiteMapSFEInst MAP.sfe.1.prefix "[0-${hop_next}][0-9]*,100"
		SetNewValue $SiteMapSFEInst MAP.sfe.1.prefix NONE
		#next_start=$hop_num
		#next_end=$(($next_start+$hop_next))		
	else
		#AddNewLineParam $SiteMapSFEInst MAP.sfe.${s}.prefix MAP.sfe.${i}.prefix "[${next_start}-${next_end}][0-9]*,100" 2
		AddNewLineParam $SiteMapSFEInst MAP.sfe.${s}.prefix MAP.sfe.${i}.prefix NONE 2
		#next_start=$(($next_end+1))
		#next_end=$(($next_start+$hop_next))		
	fi
	
done


#SetNewValue $SMSConfigAll number_of_sfes $IPGW_Count
#for (( i=1,s=0;i <= ${#IPGW_HOSTS[@]}; i++,s++)); do
#	AddNewLineParam $SMSConfigAll sfe_ei_tcp_port_number sfe_host_name.${i} ${IPGW_HOSTS[${s}]} 1
#	AddNewLineParam $SMSConfigAll sfe_host_name sfe_ei_tcp_port_number.${i} $MAPPortNumber 0
#done

#print_log "MAIN[INFO] Going to execute ${Parser} ${UnitFile} l/HLRC//UnitName"
#HLRC_HOSTS=(`${Parser} ${UnitFile} l/IPGW//UnitName`)
#if [ $? -ne 0 ] || [ -z "${HLRC_HOSTS}" ]; then
#	print_log "MAIN[ERROR] Failed to find HLRC instances on this system, no need to configure this feature"
#	exit 0
#else
	#IPGW_Count=`${Parser} ${UnitFile} l/IPGW//InstanceName -c`
#	HLRC_Count=${#HLRC_HOSTS[@]}	
#	print_log "MAIN[INFO] HLRC instances in system: $HLRC_Count, ${HLRC_HOSTS[@]}"
#	export HLRC_HOSTS HLRC_Count
#fi

#The following test will return the same hostname, just to make sure that HLRC is enabled
print_log "MAIN[INFO] Going to execute ${Parser} ${UnitFile} l/HLRC/${Host}/UnitName"
HLRC_HOST=(`${Parser} ${UnitFile} l/HLRC/${Host}/UnitName`)

#if [ $HLRCacheFet == "true" ]; then
if [ -z $HLRC_HOST ]; then
	print_log "MAIN[INFO] HLRC is not found on that host, HLR cache will not be configured automatically"
	
else
	
	instance_number=$(($IPGW_Count+1))

	SetNewValue $SiteMapSFEInst MAP.number_of_sfes $instance_number

	#IncreseValue $SiteMapSFEInst MAP.number_of_sfe_groups
	SetNewValue $SiteMapSFEInst MAP.number_of_sfe_groups $NumOfSFEGroup

	SetNewValue $SiteMAPConfig HOME_ROUTING.standard_sfe_group ${HLRCacheGroupNum}
	SetNewValue $SiteMAPConfig HLR_CACHE.standard_sfe_group ${HLRCacheGroupNum}
	
	AddNewLineParam $SiteMapSFEInst MAP.sfe_group.1.instances MAP.sfe_group.${HLRCacheGroupNum}.instances $instance_number 2
	AddNewLineParam $SiteMapSFEInst MAP.sfe_group.1.multiple_sfes_enabled MAP.sfe_group.${HLRCacheGroupNum}.multiple_sfes_enabled yes 2
	AddNewLineParam $SiteMapSFEInst MAP.sfe_group.1.number_of_digits MAP.sfe_group.${HLRCacheGroupNum}.number_of_digits 2 2
	AddNewLineParam $SiteMapSFEInst MAP.sfe_group.1.routing_mechanism MAP.sfe_group.${HLRCacheGroupNum}.routing_mechanism 2 2
	AddNewLineParam $SiteMapSFEInst MAP.sfe_group.1.routing_mechanism MAP.sfe_group.${HLRCacheGroupNum}.routing_mechanism 2 2
	AddNewLineParam $SiteMapSFEInst MAP.sfe_group.1.route_address MAP.sfe_group.${HLRCacheGroupNum}.route_address 0 2	
	AddNewLineParam $SiteMapSFEInst MAP.sfe_group.1.broadcast_alerts MAP.sfe_group.${HLRCacheGroupNum}.broadcast_alerts no 2	
	
	#According Yehuda HLRC will be always local node
	AddNewLineParam $SiteMapSFEInst MAP.sfe_ei_tcp_port_number MAP.sfe_host_name.${instance_number} ${HLRC_HOST} 1
	AddNewLineParam $SiteMapSFEInst MAP.sfe_host_name MAP.sfe_ei_tcp_port_number.${instance_number} $HLRCahcePortNumber 0
	AddNewLineParam $SiteMapSFEInst MAP.sfe_ei_tcp_port_number MAP.sfe_alternate_host_name.${instance_number} "NONE" 0
	
	AppendNewVal $SiteMapSFEInst MAP.sfe_group.${HLRCacheGroupNum}.instances $instance_number
	
	AddNewLineParam $SiteMapSFEInst MAP.sfe.${IPGW_Count}.prefix MAP.sfe.${instance_number}.prefix "[0-9][0-9]*,100" 2
	
	
	#prefix part
	#tot_range=10
	#hop_num=$(($tot_range/$HLRC_Count))
	#hop_next=$(($hop_num-1))	
	
	#for (( i=$((IPGW_Count+1)),s=$IPGW_Count,h=0,k=1;i <= $(($HLRC_Count+$IPGW_Count)); i++,s++,k++,h++)); do
	#	AddNewLineParam $SiteMapSFEInst MAP.sfe_ei_tcp_port_number MAP.sfe_host_name.${i} ${HLRC_HOSTS[${h}]} 1
	#	AddNewLineParam $SiteMapSFEInst MAP.sfe_host_name MAP.sfe_ei_tcp_port_number.${i} $HLRCahcePortNumber 0
	#	AppendNewVal $SiteMapSFEInst MAP.sfe_group.${HLRCacheGroupNum}.instances $i

	#	if [ $k -eq 1 ]; then
	#		AddNewLineParam $SiteMapSFEInst MAP.sfe.${s}.prefix MAP.sfe.${i}.prefix "[0-${hop_next}][0-9]*,100" 2
	#		next_start=$hop_num
	#		next_end=$(($next_start+$hop_next))		
	#	else		
	#		AddNewLineParam $SiteMapSFEInst MAP.sfe.${s}.prefix MAP.sfe.${i}.prefix "[${next_start}-${next_end}][0-9]*,100" 2
	#		next_start=$(($next_end+1))
	#		next_end=$(($next_start+$hop_next))		
	#	fi
	
	#done
	
fi


