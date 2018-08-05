#!/bin/bash
##Configuration of /etc/resolv.conf
##Written by Inna Gorbati, 14/03
##Gregory Danenberg - fixed resolv.conf, support for dynamic values from UnitGroup.xml
##Gregory Danenberg - added option to install it on OMU servers
##Gregory Danenberg - added fix for named.conf


if [ $# -lt 3  ] ; then    
	echo "USAGE: $0 SEM_SYS_NAME SEM_DOMAIN BALANCER_IPs"    
	exit 1
fi

RESOLV_CONF=/etc/resolv.conf
NAMED_CONF=/etc/named.conf

Date=`date '+%d%m%Y%H%M%S'`

SEM_HOSTNAME=`hostname`
SEM_SYS_NAME=$1
SEM_DOMAIN=$2
BALANCERS=$3
BALANCER_ENABLED=$4


declare -a BAL_ARR=(${BALANCERS//,/ })
declare -a SYS_ARR=(${SEM_SYS_NAME//,/ })

#on OMU servers, local nameserver should be first
#if [[ $SEM_HOSTNAME =~ [oO][mM][uU] ]] ||  [[ $SEM_HOSTNAME =~ [Dd][Ss][Cc][Mm] ]] || [[ $SEM_HOSTNAME =~ [Oo][Nn][Ss] ]]; then
	for i in `seq 0 $((${#BAL_ARR[*]}-1))`; do 
		if [ "`ifconfig -a|grep -w ${BAL_ARR[$i]}`" ]; then 
			temp=${BAL_ARR[$i]}
			BAL_ARR[$i]=${BAL_ARR[0]}
			BAL_ARR[0]=$temp
		fi
	done
#fi

###################
create_resolv_conf() {
###################
	
#domain still needed for MTA installation	
#cat > ${RESOLV_CONF} <<+++
#domain ${SEM_DOMAIN}
#search ${SYS_ARR[*]}
#nameserver 127.0.0.1
#+++

cat > ${RESOLV_CONF} <<+++
search ${SYS_ARR[*]}
nameserver 127.0.0.1
+++


if  [ "${BALANCER_ENABLED}" == "true" ]; then
	#for ns in `echo ${BAL_ARR}|perl -nle '@arr=split(/,/,); print "@arr"'`; do 
	for ns in `seq 0 $((${#BAL_ARR[*]}-1))`; do
		echo "nameserver ${BAL_ARR[$ns]}" >> ${RESOLV_CONF}
	done
fi

cat >> ${RESOLV_CONF} <<++++
options timeout:3
options retrans:1
options retry:1
++++

}

###################
update_named_conf() {
###################

	BAL_STR=$( IFS=";" ; echo "${BAL_ARR[*]}" )
		
	sed -i.${Date} 's/forwarders.*/forwarders {'$BAL_STR';};/' /etc/named.conf
	
	#if [ -z ${BAL_ARR[1]} ]; then
	#	sed -i.${Date} 's/forwarders.*/forwarders {'${BAL_ARR[0]}';};/' /etc/named.conf
	#else
	#	sed -i.${Date} 's/forwarders.*/forwarders {'${BAL_ARR[0]}';'${BAL_ARR[1]}';};/' /etc/named.conf
	#fi

}

##MAIN
if [ -f ${RESOLV_CONF} ]; then
	echo "${RESOLV_CONF} has been saved as ${RESOLV_CONF}.${Date}"
	cp -f ${RESOLV_CONF} ${RESOLV_CONF}.${Date}
	echo "Updating ${RESOLV_CONF}"
	create_resolv_conf
else
	echo "${RESOLV_CONF} does not exist. Creating a new one"
	create_resolv_conf
	chmod 644 ${RESOLV_CONF}
fi

if [ -f ${NAMED_CONF} ]; then
	echo "Updating ${NAMED_CONF}"
	update_named_conf
else
	echo "${NAMED_CONF} does not exist on this server"
fi