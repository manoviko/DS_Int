#!/bin/sh
#Created by Inna Gorbati 09/03/2011

if [ $# -lt 4 ]; then
	echo " USAGE: $0 BALANCER_ENABLED MIDDLEWARE_DB SYSLOG_IP AAS_IP"
	exit 1
fi

BALANCER_ENABLED=$1
mw_db=$2
syslog=$3
aas=$4
TraceDBHOST=$5

if  [ "${BALANCER_ENABLED}" == "true" ]; then

	echo "INFO: Balancer is enabled, remove scdb values from /etc/hosts..."
    cp -p /etc/hosts /etc/hosts.`date +%m%d%y.%H%M%S`
	cp /etc/hosts /etc/hosts.new
	
	#echo -e "INFO: The following values will be removed from /etc/hosts: \n `egrep "\-vip|SPU|_vip" /etc/hosts`" 
	#egrep -v "\-vip|SPU|_vip" /etc/hosts.new > /etc/hosts
	echo -e "INFO: The following values will be removed from /etc/hosts: \n `egrep "SPU" /etc/hosts`" 
	egrep -v "SPU" /etc/hosts.new > /etc/hosts
	/bin/rm -f /etc/hosts.new
	
else
	echo "Balancer not in use..."
	
	DBHOST=`echo $mw_db | awk -F= '{print $1}'`
	DBIP=`echo $mw_db | awk -F= '{print $2}'`
	echo "INFO: Setting $DBHOST $DBIP in /etc/hosts"
	/usr/cti/apps/CSPbase/csp_networking.pl --action=set_host --hostname=$DBHOST --ip=$DBIP
	
	SYSHOST=`echo $syslog | awk -F= '{print $1}'`
	SYSIP=`echo $syslog | awk -F= '{print $2}'`
	echo "INFO: Setting $SYSHOST $SYSIP in /etc/hosts"
	/usr/cti/apps/CSPbase/csp_networking.pl --action=set_host --hostname=$SYSHOST --ip=$SYSIP
	
	AASHOST=`echo $aas | awk -F= '{print $1}'`
	AASIP=`echo $aas | awk -F= '{print $2}'`
	echo "INFO: Setting $AASHOST $AASIP in /etc/hosts"
	/usr/cti/apps/CSPbase/csp_networking.pl --action=set_host --hostname=$AASHOST --ip=$AASIP
	
	MWTraceDBHOST=`echo $TraceDBHOST | awk -F= '{print $1}'`
	MWTraceDBHOSTIP=`echo $TraceDBHOST | awk -F= '{print $2}'`
	echo "INFO: Setting $MWTraceDBHOST $MWTraceDBHOSTIP in /etc/hosts"
	/usr/cti/apps/CSPbase/csp_networking.pl --action=set_host --hostname=$MWTraceDBHOST --ip=$MWTraceDBHOSTIP
	
	
fi