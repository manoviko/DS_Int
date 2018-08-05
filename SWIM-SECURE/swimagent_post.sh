#!/bin/bash

Date=`date +%m%d%y_%H%M%S`

AgentXML=/usr/cti/conf/swimagent/swimagent/parameters.xml
AgentCCMXML=/usr/cti/conf/ccm-register/SwimAgent_ccm-declare.xml

if [ -f $AgentXML ]; then
	
	echo "INFO: Backing up $AgentXML as $AgentXML.${Date}"
	
	sed -i.${Date} 	-e '/Name=.MaxAuditFilesPerComponent/,/\/Parameter/{s#<Item Value=.*/>#<Item Value=\"20\"/>#}' \
					-e '/Name=.AuditFilesExpirationTime/,/\/Parameter/{s#<Item Value=.*/>#<Item Value=\"365\"/>#}' $AgentXML

fi

if [ -f $AgentCCMXML ]; then
	if [ ! "`grep isUnitSpecific $AgentCCMXML`" ]; then
		echo "INFO: Updating AgentCCMXML to support different configuration files over the system"
		sed -i.${Date} 's/\/>/ isUnitSpecific=\"true\"\/>/g' /usr/cti/conf/ccm-register/SwimAgent_ccm-declare.xml
	fi
fi

