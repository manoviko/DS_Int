#!/bin/bash

dtdDir="/usr/cti/conf/swp/"
dtdFile="networking.dtd"
inputFile="/var/tmp/mVAS-Networking-dynamic.param"

if [ -f ${inputFile} ]; then
	#check that the number of interfaces match the number of devices in the input file
	ethCount=`cat ${inputFile} | grep eth | wc -l`
	deviceCount=`cat ${inputFile} | grep device | wc -l`

	if [ ! -d ${dtdDir} ]; then
			echo "[INFO] Folder ${dtdDir} does not exist, creating it."
			mkdir -p ${dtdDir}
	fi
	
	if [ ! -f ${dtdDir}/${dtdFile} ]; then
			echo "[INFO] File ${dtdDir}/${dtdFile} does not exist, creating it."
			touch ${dtdDir}/${dtdFile}
	else
			echo "[WARN] File ${dtdDir}/${dtdFile} exists, performing backup and creating a fresh file"
			mv ${dtdDir}/${dtdFile} ${dtdDir}/${dtdFile}_$(date +%F-%T)
			touch ${dtdDir}/${dtdFile}
	fi

	#Starting to Build the networking.dtd file
	if [ ${ethCount} == ${deviceCount} ];then
		for i in `cat ${inputFile} | grep device`; do
			deviceType=`echo $i | cut -d= -f2`
			deviceId=`echo $i | cut -d= -f1 | cut -d_ -f2`
			echo "Device ID:"${deviceId} " is " ${deviceType}
			
			interfaceName=`grep eth_${deviceId} ${inputFile} | cut -d= -f2`
			echo "Interface Name is: ${interfaceName}"

			#Adding lines to networking.dtd file only if the device and interface do not exist.
			#If the device or interface already exist, exiting with error.
			
			if [[ ! `grep ${interfaceName} ${dtdDir}/${dtdFile}` ]]; then
				echo "<!ENTITY ${deviceType}          \"${interfaceName}\">" >> ${dtdDir}/${dtdFile}
			else
				echo "[ERROR] ${interfaceName} already exists in ${dtdDir}/${dtdFile}, cannot have duplicate."
				exit 1
			fi
		done
	else
		echo "[ERROR] Number of devices and number of interfaces do not match, please check ${inputFile}"
		exit 1
	fi
else
	echo "[ERROR] File ${inputFile} does not exist, exiting!"
	exit 1
fi

