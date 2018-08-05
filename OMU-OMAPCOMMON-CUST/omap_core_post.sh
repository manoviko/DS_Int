#!/bin/bash
#Written by Gregory Danenberg, SEM 5.1 
#Performs OMAP CORE and COMMON customizations


#######################################
GetPackageIngo() {
#######################################

local comp=$1

local PackVers=`cat /home/smsc/.nyappl/smsc.OMAP|sed 's/.*:*\('${comp}'\.[0-9\.]*\)\:.*/\1/'`

if [ -z ${PackVers} ]; then
	echo "ERROR: Failed to get $comp version, exit..."
else
	PackVers=`echo ${PackVers}|sed -e 's/^ *//' -e '/^$/d'`
	echo "$PackVers"
fi

}

#######################################
BackupOrigFiles() {
#######################################

local File=$1

if [ ! -f ${File} ]; then
        echo "ERROR: ${File} does not exist, exit..."
        exit 1
fi

echo "INFO: Backup $File to ${File}.sem.${Date}"
/bin/cp -f $File ${File}.sem.${Date}

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

Curr=`grep ${Par} ${File}|awk -F= '{print $2}'`
Curr=`echo ${Curr}|sed -e 's/^ *//' -e '/^$/d'`

echo "$Curr"

}

#######################################
SetNewValue() {
#######################################

local File=$1
local Par=$2
local Val=$3

#GetCurValue $File $Par
Curr=$(GetCurValue $File $Par)

if [ "$Curr" = "$Val" ]; then
	echo "INFO: No need to replace value of $Par in $File, since there are the same"
elif [ -z $Curr ]; then
	echo "INFO: $Par in $File is empty, set new value: $Val"
	sed -i 's/'${Par}'=.*$/'${Par}'='${Val}'/' $File
else
	
	CMD='print "$1\n" if /[^\w]('$Val')[^\w]/'
	
	ifExist=$(echo $Curr | perl -ne "$CMD")
	if [ -z $ifExist ]; then
			echo "INFO: $Par in $File has already value: $Curr, append $Val to it"
		sed -i 's/'${Par}'=.*$/'${Par}'='${Curr}','${Val}'/' $File
	else
		echo "INFO: $Par in $File has already value: $Curr and $Val is already part of it"
	fi
fi

}

#######################################
## MAIN
#######################################

Date=`date +%m%d%y%H%M%S`
declare -a SEM_GROUPS=(isu_group sca_group sem_group omu_group ons_group sng_group psu_group dsc_group asu_group gsu_group)

CorePackVers=$(GetPackageIngo omapCoreAppl)
echo "INFO: omapCoreAppl version is $CorePackVers"
CommonPackVers=$(GetPackageIngo omapCommonAppl)
echo "INFO: omapCommonAppl version is $CommonPackVers"


CoreCustFile=/home/smsc/${CorePackVers}/config/omapCoreAppl.config
CommonCustFile=/home/smsc/${CommonPackVers}/config/omapCommonAppl.config
for f in $CoreCustFile $CommonCustFile; do
	BackupOrigFiles $f
done

#SetNewValue $CoreCustFile scdb.smsc_product_names ECS IPSMGW
SetNewValue $CoreCustFile scdb.smsc_product_names IPSMGW
#SetNewValue $CommonCustFile scdb.smsc_applications_list MGW IPGW
SetNewValue $CommonCustFile scdb.smsc_applications_list IPGW

for gr in ${SEM_GROUPS[*]}; do
	SetNewValue $CommonCustFile scdb.smsc_group_names $gr
done

##to do
# $CommonCustFile scdb.admin_system_name = HUB-Site-1 


