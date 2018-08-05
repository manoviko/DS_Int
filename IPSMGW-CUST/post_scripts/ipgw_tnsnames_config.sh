#!/bin/bash
##Written by Gregory Danenberg, 05/08
##We want to make sure that tnsnames.ora holding alias to Trace and MW DB
##Updated for IP SM GW

if [ $# -lt 4  ] ; then    
	echo "USAGE: $0 IPGW_SERVICE_ID IPGW_DB_NAME OMAP_SERVICE_NAME OMAP_DB_NAME"    
	exit 1
fi

#TNS=/ora_client/network/admin/tnsnames.ora
TNS=/ora_client/instantclient_12_1/network/admin/tnsnames.ora
Date=`date '+%d%m%Y%H%M%S'`

IPGW_SID=$1
IPGW_DB_NAME=$2
OMAP_SID=$3
OMAP_DB_NAME=$4

###################
create_tns() {
	
cat > ${TNS} <<+++

ODS=
 (DESCRIPTION=
	(ADDRESS=
		(PROTOCOL=TCP)
		(HOST=${IPGW_DB_NAME})
		(PORT=1521)
	)
	(CONNECT_DATA=
		(SERVICE_NAME=${IPGW_SID})
	)
 )

SEM_DB=
 (DESCRIPTION=
	(ADDRESS=
		(PROTOCOL=TCP)
		(HOST=${IPGW_DB_NAME})
		(PORT=1521)
	)
	(CONNECT_DATA=
		(SERVICE_NAME=${IPGW_SID})
	)
 )
 
MWTRACESDB=
 (DESCRIPTION=
	(ADDRESS=
		(PROTOCOL=TCP)
		(HOST=${OMAP_DB_NAME})
		(PORT=1521)
	)
	(CONNECT_DATA=
		(SERVICE_NAME=${OMAP_SID})
	)
 )

+++

}

if [ -f ${TNS} ]; then
	echo "INFO: ${TNS} has been saved as ${TNS}.${Date}"
	cp -f ${TNS} ${TNS}.${Date}
	echo "INFO: Adding OMAPDB alias to ${TNS}"
	create_tns
else
	echo "INFO: ${TNS} does not exist. Creating a new one"
	create_tns
	chmod 744 ${TNS}
	chown oracle:sys ${TNS}
fi

