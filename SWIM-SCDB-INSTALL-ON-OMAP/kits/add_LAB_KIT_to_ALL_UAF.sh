#!/bin/bash
#Written ny Gregory Danenberg, for internal use only!!!

xml=/var/cti/data/swim/systems/SEM/ASU_Group-UAF.xml
for xml in `find . -name "*-UAF.xml"`; do
	
	grep aa-LABs-POST $xml &> /dev/null
	if [ $? -eq 0 ]; then
		echo " -W- aa-LABs-POST is already part of $xml"
		continue
	fi

	grep Reboot-KIT $xml &> /dev/null
	if [ $? -ne 0 ]; then
		echo " -W- No need to update $xml"
		continue
	fi
			

	sed -i '/<Component Name=\"Reboot-KIT\"/a \
					<Component Name=\"aa-LABs-POST\" ExecutionOrder=\"5000\" UponError=\"Stop\"\/>' $xml
        if [ $? -eq 0 ]; then
                echo " -U- Updated $xml "
        else
                echo " -ERROR - Failed to update $xml"
        fi
done
