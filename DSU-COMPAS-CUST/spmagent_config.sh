#!/bin/bash
# Re-Written by Gregory Danenberg, 02/2012

#for f in /usr/cti/conf/spmagent/localsettings/parameters.xml /usr/cti/conf/spmagent/shared/parameters.xml /usr/cti/conf/spmagent/jdsv/parameters.xml; do
#	if [ -f $f ]; then
#		echo "INFO: Setting MW_ user name in $f"
#		sed -i.`date +%m%d%y.%H%M%S` -e "s/SPM_APP_USER/MW_SPM_APP_USER/ig" $f
#	fi
#done

#echo "INFO: Update SPM Agent to work with PGW"
#sed -i.`date +%m%d%y.%H%M%S` -e "s/Value=\([\'\"]\)SPM\([\'\"]\)/Value=\1PGW\2/" \
#	-e "s/Value=\([\'\"]\)51445\([\'\"]\)/Value=\152101\2/" \
#	-e "s#Value=\([\'\"]\)/compas/interfaces\/http\([\'\"]\)#Value=\1/compas/ProvisionServlet\2#" /usr/cti/conf/spmagent/spmagent/parameters.xml

echo "INFO: Executing System Customization Tool"
/usr/cti/apps/spmagent/bin/systemCustomizationTool.sh /usr/cti/conf/profiledefinition/SysParamCustomization_MW.xml
if [ $? -ne 0 ]; then
	echo "ERROR: Failed to execute /usr/cti/apps/spmagent/bin/systemCustomizationTool.sh /usr/cti/conf/profiledefinition/SysParamCustomization_MW.xml"
	exit 1
fi

echo "INFO: Adding spmagent to oinstall group, otherwise user will fail deleting old xml files"
usermod -aG oinstall spmagent
