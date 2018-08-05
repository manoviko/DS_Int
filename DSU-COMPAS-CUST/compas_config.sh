#!/bin/bash
# Re-Written by Gregory Danenberg, 02/2012

#grep -i "spm " /etc/hosts
#resp=$?
#if [ $resp != 0 ]; then
#		echo "INFO: Setting spm spm.sys100.comverse.com in /etc/hosts"
#        echo "`hostname -i`     spm spm.sys100.comverse.com" >> /etc/hosts
#fi

#for f in /usr/cti/conf/compas/localsettings/parameters.xml /usr/cti/conf/compas/shared/parameters.xml /usr/cti/conf/compas/jdsv/parameters.xml; do
#	if [ -f $f ]; then
#		echo "INFO: Setting MW_ user name in $f"
#		sed -i.`date +%m%d%y.%H%M%S` -e "s/=\([\'\"]\)\(SPM_APP_USER\)/=\1MW_\2/ig" $f
#	fi
#done

echo "INFO: Setting permissions for /usr/cti/conf/profiledefinition"
chmod -R 755 /usr/cti/conf/profiledefinition

echo "INFO: Executing System Customization Tool"
/usr/cti/apps/compas/bin/systemCustomizationTool.sh /usr/cti/conf/profiledefinition/SysParamCustomization_MW.xml
if [ $? -ne 0 ]; then
	echo "ERROR: Failed to execute /usr/cti/apps/compas/bin/systemCustomizationTool.sh /usr/cti/conf/profiledefinition/SysParamCustomization_MW.xml"
	exit 1
fi

if [ ! -d /usr/cti/compas/deploy/Conf ]; then
		echo "INFO: Setting link between /usr/cti/compas/deploy/Conf and /usr/cti/compas/deploy/conf"
        ln -s /usr/cti/compas/deploy/conf  /usr/cti/compas/deploy/Conf
fi

if [ ! -d /var/cti/al/compas ]; then
	echo "INFO: Creating /var/cti/al/compas"
	mkdir -p /var/cti/al/compas
	chmod 755 /var/cti/al
	chown compas:compas /var/cti/al
fi



