#!/bin/bash

#Written by Inna Kushner, 22/03/2016

#DR-0-230-028 auditd customization

UnitType=$1

if [ -z $UnitType ]; then
	echo "ERROR: You have to supply UnitType, for example: ISU_Group,MAP_Group..."
fi

file="/etc/audit/audit.rules"

Date=`date '+%d%m%Y%H%M'`
echo "WARN : /etc/audit/audit.rules exists. Backup it as /etc/audit/audit.rules.${Date}"
if [ -f $file  ]; then
 /bin/cp -f /etc/audit/audit.rules /etc/audit/audit.rules.${Date}
fi

#execute on all type of servers


case $UnitType in

	 ISU_Group)
			echo "INFO : Executing customization audit for $UnitType"
			id=`cd /var/cti/smsc/site/trace/; ls -l|grep IPGW|grep -v IPGW_ |cut -d "." -f 2,3|grep -v log`
                        echo "-a exit,always -F dir=/var/cti/smsc/site/trace/IPGW/event -F perm=warx -F auid!=smsc -F euid!=smsc -F key=Xura_IPGW_Trace" >> $file
                        echo "-a exit,always -F dir=/var/cti/smsc/site/trace/IPGW/header -F perm=warx -F auid!=smsc -F euid!=smsc -F key=Xura_IPGW_Trace" >> $file
			;;
	 MAP_Group) 
			echo "INFO : Executing customization audit for $UnitType"
                        echo "-a exit,always -F dir=/home/smsc/cust.map.all/config/MAP -F perm=warx -F auid!=smsc -F auid!=ftm -F euid!=smsc  -F euid!=ftm -F key=Xura_IPGW_Config" >> $file
			;;
	 Shared_OMU_Group)
			echo "INFO : Executing customization audit for $UnitType"
                        echo "-a exit,always -F dir=/data/ipgw_cdr -F perm=warx -F auid!=smsc -F auid!=ftm -F auid!=asntool -F euid!=smsc -F euid!=ftm -F euid!=asntool  -F key=Xura_IPGW_CDR"  >> $file
			;;
	 IPCDRPP_Group)
                        echo "INFO : Executing customization audit for $UnitType"
                        echo "-a exit,always -F dir=/data/ipsmgw_cdr/IPSMGW -F perm=warx -F auid!=smsc -F auid!=ftm -F auid!=asntool -F euid!=smsc -F euid!=ftm -F euid!=asntool  -F key=Xura_IPGW_CDR"  >> $file
                        ;;
	*)
			echo "WARN : Failed to find instructions for $UnitType"
			;;
esac 
