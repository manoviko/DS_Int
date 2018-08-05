#!/bin/bash
#Written by Gregory Danenberg, 1/2013

BABY_INI=/usr/cti/conf/babysitter/Babysitter.ini
CSP_BASE=/usr/cti/apps/CSPbase

BabyUnitType=$1

if [ ! -f $BABY_INI ]; then
	echo "MAIN[WARN]: $BABY_INI is not here, assuming no Babysitter on this server"
	exit 0
fi

PLATF=`${CSP_BASE}/csp_scanner.pl --machine_type`
makeUpd=0

#virtual env. should not test CPU performance
if [ "$PLATF" == "VMWARE" ] ; then
	echo "MAIN[INFO]: Running on $PLATF platform, updating babysitter configuration"

	sed -i 's/^UnitCpuCheckEnabled=.*/UnitCpuCheckEnabled=0/' $BABY_INI
	if [ $? -eq 0 ]; then
		echo "MAIN[INFO]: UnitCpuCheckEnabled was set to 0 in $BABY_INI"
	else
		echo "MAIN[ERROR]: Failed to set UnitCpuCheckEnabled=0 in $BABY_INI"
		exit 1
	fi
	
	makeUpd=1

fi

if [ ! -z $BabyUnitType ]; then
	
	echo "MAIN[INFO]: Need to update UnitType to $BabyUnitType"
	
	sed -i 's/^UnitType=.*/UnitType='$BabyUnitType'/' $BABY_INI
	if [ $? -eq 0 ]; then
		echo "MAIN[INFO]: UnitType was set to $BabyUnitType in $BABY_INI"
	else
		echo "MAIN[ERROR]: Failed to set UnitType=$BabyUnitType in $BABY_INI"
		exit 1
	fi
	
	makeUpd=1

fi

if [ $makeUpd -eq 1 ]; then

	service babysitter status > /dev/null
	if [ $? -eq 0 ]; then
		service babysitter reload
	fi
fi
		
exit 0	
	
	
