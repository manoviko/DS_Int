#!/bin/bash
#Written by Gregory Danenberg, manually adding IPGW instance to be part of monitor process
#Updated for IPGW 5, 09/2012

Host=`hostname`
Parser=/home/smsc/autoconfig.all/scripts/parser.pl
UnitFile=/usr/cti/conf/autoconf/UnitGroup.xml

SMSBASE_VER=`rpm -q --last NYSMSBASE|sed 's/NYSMSBASE-\([0-9]\{1,\}\.[0-9]\{1,\}\.[0-9]\{1,\}\)-.*/\1/'|tail -1`
#WA - temorary solution for handling upgrade version: 4.8.500-01 
#
#SMSBASE_VER=`rpm -q NYSMSBASE|sed 's/NYSMSBASE-\([0-9]\{1,\}\.[0-9]\{1,\}\.[0-9]\{1,\}\)\.[0-9]\{1,\}\?-.*/\1/'|tail -1`


if [ "X$SMSBASE_VER" = "X" ]; then
	echo "ERROR: Failed to identify NYSMSBASE version"
	exit 1
fi

if [ ! -x ${Parser} ]; then
	echo "ERROR: Couldn't find ${Parser} or it does not have executable permissions"
fi

if [ ! -r ${UnitFile} ]; then
	echo "ERROR: ${UnitFile} is not readable"
fi

echo "INFO: Going to execute ${Parser} ${UnitFile} l/IPGW/${Host}/InstanceName"
IPGW_INST=`${Parser} ${UnitFile} l/IPGW/${Host}/InstanceName`
if [ $? -ne 0 ] || [ -z "${IPGW_INST}" ]; then
	echo "ERROR: IPGW instance is: ${IPGW_INST}"
	echo "ERROR: Failed to identify IPGW instance id. Can not continue"
	exit 1
else
	echo "INFO: IPGW instance is: ${IPGW_INST}"
fi

if [ ! -f /home/smsc/smsbase.${SMSBASE_VER}/config/factory.ei.IPGW.startup ]; then
	echo "INFO: /home/smsc/smsbase.${SMSBASE_VER}/config/factory.ei.IPGW.startup does not exist, creating it"

cat > /home/smsc/smsbase.${SMSBASE_VER}/config/factory.ei.IPGW.startup << +++
ei.IPGW.monitored = yes
ei.IPGW.unique = no
ei.IPGW.exec = start_monitored_MRE
+++

	chown smsc:sys /home/smsc/smsbase.${SMSBASE_VER}/config/factory.ei.IPGW.startup
	chmod 444 /home/smsc/smsbase.${SMSBASE_VER}/config/factory.ei.IPGW.startup

else
	echo "INFO: /home/smsc/smsbase.${SMSBASE_VER}/config/factory.ei.IPGW.startup is already exists"
fi

if [ -f /home/smsc/smsbase.${SMSBASE_VER}/config/factory.monitor.config ]; then
	if [ ! "`egrep "monitor.system_protection.supported_classes=.*IPGW.*" /home/smsc/smsbase.${SMSBASE_VER}/config/factory.monitor.config`" ]; then
		sed -i 's/\(monitor.system_protection.supported_classes=.*\)/\1,IPGW/' /home/smsc/smsbase.${SMSBASE_VER}/config/factory.monitor.config
		echo "INFO: Added IPGW to /home/smsc/smsbase.${SMSBASE_VER}/config/factory.monitor.config"
	else
		echo "INFO: IPGW is already part of /home/smsc/smsbase.${SMSBASE_VER}/config/factory.monitor.config"
	fi
else
	echo "ERROR: /home/smsc/smsbase.${SMSBASE_VER}/config/factory.monitor.config does not exist"
	exit 2
fi

if [ -f /home/smsc/smsbase.${SMSBASE_VER}/config/monitor.config.dir ]; then
	if [ ! "`grep factory.ei.IPGW.startup /home/smsc/smsbase.${SMSBASE_VER}/config/monitor.config.dir`" ]; then
		echo "factory.ei.IPGW.startup		5" >> /home/smsc/smsbase.${SMSBASE_VER}/config/monitor.config.dir
		echo "INFO: Added IPGW to /home/smsc/smsbase.${SMSBASE_VER}/config/monitor.config.dir"
	else
		echo "INFO: IPGW is already part of /home/smsc/smsbase.${SMSBASE_VER}/config/monitor.config.dir"
	fi
else
	echo "ERROR: /home/smsc/smsbase.${SMSBASE_VER}/config/monitor.config.dir does not exist"
	exit 3
fi

if [ -f /home/smsc/smsbase.${SMSBASE_VER}/config/site.system_protection.config ]; then
	if [ ! "`grep system_protection.IPGW /home/smsc/smsbase.${SMSBASE_VER}/config/site.system_protection.config`" ]; then
		echo "system_protection.IPGW.${IPGW_INST}.soap_port=8014" >> /home/smsc/smsbase.${SMSBASE_VER}/config/site.system_protection.config
		echo "INFO: Added IPGW to /home/smsc/smsbase.${SMSBASE_VER}/config/site.system_protection.config"
	else
		echo "INFO: IPGW is already part of /home/smsc/smsbase.${SMSBASE_VER}/config/site.system_protection.config"
	fi
else
	echo "ERROR: /home/smsc/smsbase.${SMSBASE_VER}/config/site.system_protection.config does not exist"
fi


