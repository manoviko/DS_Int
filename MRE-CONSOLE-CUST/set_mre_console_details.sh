#!/bin/bash
#Written by Gregory Danenberg, 12/2011
#Customizing MRE CONSOLE DB parameters

if [ $# -lt 4  ] ; then    
	echo "USAGE: $0 DB_HOST DB_SID DB_USER MRE_CONSOLE_INST"    
	exit 1
fi

DBHOST=$1
DBSID=$2
DBUSER=$3
DBPASS=$4
MRE_CONS_INST=$5


MRE_CONS_DB_CONF=/home/smsc/site/config/MRE_CONSOLE.${MRE_CONS_INST}/db.config

test_rc() {
	rc=$1
	param_name=$2
	conf_file=$3
	param_value=$4
	
	if [ $rc -ne 0 ]; then
		echo "ERROR: Failed to set $param_name in $conf_file..."
		exit 1
	else
		echo "INFO : $param_name in $conf_file has been updated to $param_value ..."
	fi

}

##MAIN

if [ ! -f $MRE_CONS_DB_CONF ]; then
	echo "ERROR: Failed to find $MRE_CONS_DB_CONF"
	exit 1
fi

sed -i -e 's/db.main_user_name\s*=.*/db.main_user_name='$DBUSER'/' $MRE_CONS_DB_CONF
test_rc $? db.main_user_name MRE_CONS_DB_CONF $DBUSER

sed -i -e 's/db.main_password_name\s*=.*/db.main_password_name='$DBPASS'/' $MRE_CONS_DB_CONF
test_rc $? db.main_password_name MRE_CONS_DB_CONF $DBPASS

sed -i -e 's/db.main_db_instance\s*=.*/db.main_db_instance='$DBSID'/' $MRE_CONS_DB_CONF
test_rc $? db.main_db_instance MRE_CONS_DB_CONF $DBSID

sed -i -e 's/DBService.1.service_name\s*=.*/DBService.1.service_name='$DBSID'/' $MRE_CONS_DB_CONF
test_rc $? DBService.1.service_name MRE_CONS_DB_CONF $DBSID

sed -i -e 's/DBService.1.host.1\s*=.*/DBService.1.host.1='$DBHOST'/' $MRE_CONS_DB_CONF
test_rc $? DBService.1.host.1 MRE_CONS_DB_CONF $DBHOST
