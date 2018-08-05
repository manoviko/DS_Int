#!/bin/bash
#DR-0-193-272 - SWIM securing
#Written by Gregory Danenberg, 11/12. Used in SEM 5.1 product

#swim manager admin ips
MANAGER_LIST=$1

Date=`date +%m%d%y_%H%M%S`
ManagerXML=/usr/cti/conf/swim/swim/parameters.xml
AgentXML=/usr/cti/conf/swimagent/swimagent/parameters.xml

if [ -z $MANAGER_LIST ]; then
	echo "USAGE: $0 [list of swim manager ip's separated by comma]"
	exit 1
fi

declare -a MANAGER_ARR=(${MANAGER_LIST//,/ })

##another option is using /usr/cti/apps/swim/bin/systemCustomizationTool.sh and /usr/cti/apps/swimagent/bin/systemCustomizationTool.sh
##similar to compas idea

#secure swim manager
if [ -f $ManagerXML ]; then
	echo "INFO: Backing up $ManagerXML as $ManagerXML.${Date}"
	echo "INFO: Setting authorization and authentication server to be AAS only"
	sed -i.${Date} -e '/Name=.AuthServerType/,/\/Parameter/{s#<Item Value=.Internal./>#<Item Value=\"AAServer\"/>#}' $ManagerXML
	
#	/usr/cti/apps/swim/bin/monitorByVeritas.sh
#	if [ $? -eq 110 ]; then
#		echo "INFO: Restarting swim to apply update"
#		su - swim -c "/usr/cti/apps/swim/bin/restart.sh"
#	fi
else
		echo "INFO: No swim manager on this host"

fi

#secure swim agent
if [ -f $AgentXML ]; then
        echo "INFO: Backing up $AgentXML as $AgentXML.${Date}"
        echo "INFO: Setting OMU IP's to access white list : ${MANAGER_ARR[*]}"
        str='<Value>'
        for i in ${MANAGER_ARR[@]}; do
                str+="\n\t\t<Item Value=\"$i\"/>"
        done
        str+='\n\t</Value>'
        sed -i.${Date} -e "/Name=.ValidManagersList/,/\/Parameter/{s#<Value/>#$str#}" $AgentXML
		
		#agent will refresh this value after 3 min., no need for restart
		#/usr/cti/apps/swimagent/bin/restart.sh

else
        echo "ERROR: No swim Agent configuration file on that host!"
        exit 1
fi

echo "INFO: Removing permissions for other on /etc/rc.d/rc3.d/K20swimagent"
test -f /etc/rc.d/rc3.d/K20swimagent && chmod o-rwx /etc/rc.d/rc3.d/K20swimagent

echo "INFO: Removing permissions for other on /etc/rc.d/init.d/swimagent"
test -f /etc/rc.d/init.d/swimagent && chmod o-rwx /etc/rc.d/init.d/swimagent