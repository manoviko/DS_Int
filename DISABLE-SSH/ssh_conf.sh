#!/bin/bash

#Written by Inna Kushner, 23/03/2016

#DR-0-229-533 allow incoming SSH traffic only to the required interfaces per unit type

UnitType=$1

if [ -z $UnitType ]; then
	echo "ERROR: You have to supply UnitType, for example: ISU_Group,MAP_Group..."
fi

file="/etc/sysconfig/iptables"

Date=`date '+%d%m%Y%H%M'`
if [ -f $file ]; then
 echo "WARN : /etc/sysconfig/iptables exists. Backup it as /etc/sysconfig/iptables.${Date}"
 /bin/cp -f /etc/sysconfig/iptables /etc/sysconfig/iptables.${Date}
fi

#execute on all type of servers


case $UnitType in

	    SCA_Group)
			echo "INFO : enable ssh to Admin for $UnitType"
                        iptables -A INPUT -i eth0 -p tcp --dport 22 -j ACCEPT
                        iptables -A INPUT -i lo -p tcp --dport 22 -j ACCEPT
                        iptables -A INPUT -p tcp --dport 22 -j REJECT
                        service iptables save

			;;
		ISU_Group)
			echo "INFO : enable ssh to Admin for $UnitType"
                        iptables -A INPUT -i eth0 -p tcp --dport 22 -j ACCEPT
                        iptables -A INPUT -i lo -p tcp --dport 22 -j ACCEPT
                        iptables -A INPUT -p tcp --dport 22 -j REJECT
                        service iptables save

			;;
         DSU_Group)
                        echo "INFO : enable ssh to Admin for $UnitType"
                        iptables -A INPUT -i eth0 -p tcp --dport 22 -j ACCEPT
                        iptables -A INPUT -i lo -p tcp --dport 22 -j ACCEPT
                        iptables -A INPUT -p tcp --dport 22 -j REJECT
                        service iptables save

            ;;
	 MAP_Group) 
			echo "INFO : enable ssh to Admin and SZ for $UnitType"
                        iptables -A INPUT -i eth0 -p tcp --dport 22 -j ACCEPT
                        iptables -A INPUT -i eth1 -p tcp --dport 22 -j ACCEPT
                        iptables -A INPUT -i lo -p tcp --dport 22 -j ACCEPT
                        iptables -A INPUT -p tcp --dport 22 -j REJECT
                        service iptables save

			;;
	   IPCDRPP_Group)
                        echo "INFO : enable ssh to Admin and SZ for IPCDRPP_Group"
                        iptables -A INPUT -i eth0 -p tcp --dport 22 -j ACCEPT
                        iptables -A INPUT -i lo -p tcp --dport 22 -j ACCEPT
                        iptables -A INPUT -p tcp --dport 22 -j REJECT
                        service iptables save

			;;
	*)
			echo "WARN : Failed to find instructions for $UnitType"
			;;
esac 
