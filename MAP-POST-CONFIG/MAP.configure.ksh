#!/bin/ksh
##################################################################
# This script designed for automatic MAP configuration
##################################################################
# Developed by Assaf Baranes
##################################################################
# Version 1.0.0 (17/08/2010) - For smsc 4.8.000
##################################################################


exiting()
{
	print $1  >> $activity_log
	echo [`date +"%d-%m-%Y %H:%M:%S"`] '************ EXITING MAP automatic configuration *************' >> $activity_log
	exit 1
}



configure_ce_instances()
{
        set -A ce_instances `$parser $UnitGroup_file l/MAP/$ce_name/InstanceName -U`
        echo ${ce_instances[@]} | grep -i ERROR > /dev/null 2>&1
        if [ $? -eq 0 ];then
        	exiting "ERROR: $ce_name is configured as CE in cestart.201, but MAP instances are not configured for it in $UnitGroup_file !!!"
        fi

        num_of_insts=${#ce_instances[@]};
        ctl_channel_port=10020
        iter=0
        while [ $iter -lt $num_of_insts ]
        do
		((++cluster_inst))
                inst=${ce_instances[${iter}]}
                # get the map folder with last version map.<> from .nyappl/smsc.MAP
		map_root_folder=`cat /home/smsc/.nyappl/smsc.MAP | awk -F : '{print $1}'`

                if [ $ce_name == $hostname ];then
			# Update omni_health.201
                	grep -x smsc-MAP-$cluster_inst $omni_health_201
                	if [ $? -ne 0 ];then
                        	print "smsc-MAP-$cluster_inst" >> $omni_health_201
                        	print "Adding smsc-MAP-$cluster_inst to the end of $omni_health_201" >> $activity_log
                	fi

			if [ $inst != 1.1 ];then
                        	((++ctl_channel_port))

                        	# Create MAP.<group>.<instance> config & trace directories
                       		print "Creating MAP.$inst config and trace directories" >> $activity_log
                       		su - smsc -c "rm -rf ~/site/config/MAP.$inst ; mkdir -p ~/site/config/MAP.$inst ; \
                               	cp -f ~/$map_root_folder/config/MAP.1.1/* ~/site/config/MAP.$inst/ ; \
				chmod +rw ~/site/config/MAP.$inst; chmod +rw ~/site/config/MAP.$inst/*  ; \
                               	rm -rf ~/site/trace/MAP.$inst ; mkdir -p ~/site/trace/MAP.$inst ;\
				mv ~/site/config/MAP.$inst/site.MAP.1.1.config.dir  ~/site/config/MAP.$inst/config.dir ;\
                        	rm ~/site/config/MAP.$inst/config; \
                                chmod +rw ~/site/trace/MAP.$inst/; chmod +rw ~/site/trace/MAP.$inst/*"

                        	# Copy and configure site.MAP.inst.config & site.MAP.inst.config_ccm-metadata.xml
                        	su - smsc -c "sed -i s/^MAP.1.1/MAP.$inst/g ~/site/config/MAP.$inst/site.MAP.inst.config ; \
                                	      sed -i s/MAP.1.1/MAP.$inst/g ~/site/config/MAP.$inst/site.MAP.inst.config_ccm-metadata.xml ; \
                                      	      smsc -nobanner -class MAP -inst $inst rm_set MAP.$inst.ctl_channel_port=$ctl_channel_port"
                        	print "Updating site.MAP.inst.config and site.MAP.inst.config_ccm-metadata.xml of MAP.$inst" >> $activity_log
                        	# Copy and configure MAP.<group>.<instance>_ccm-declare.xml
                        	su - smsc -c "cp -f ~/$map_root_folder/config/sms_declare/MAP.1.1_ccm-declare.xml ~/site/config/sms_declare/MAP.$inst\_ccm-declare.xml ; \
                                	      sed -i s/MAP.1.1/MAP.$inst/g ~/site/config/sms_declare/MAP.$inst\_ccm-declare.xml ; \
                                     	      perl -pi -e 's/reconfigurePath=\"10020\"/reconfigurePath=\"'$ctl_channel_port'\"/g' ~/site/config/sms_declare/MAP.$inst\_ccm-declare.xml"
                        	print "Creating MAP.${inst}_ccm-declare.xml file" >> $activity_log
			fi
                fi

                # Update cestart.201
                grep "\-class MAP \-inst $inst gsm_ei \-name smsc\-MAP\-$cluster_inst" $cestart_201_CURRENT
                if [ $? -ne 0 ];then
			print "smsc-MAP-$cluster_inst . 0 DEF DEF 20001 3 /home/smsc/scripts/smsc -class MAP -inst $inst gsm_ei -name smsc-MAP-$cluster_inst  -GUARD_TV 360000 -CLEANUP -TTOPT" >> $cestart_201
                fi

                ((++iter))
        done

	return
}



configure_ces_instances()
{

        cestart_201=/tmp/cestart.201
        su - smsc -c "cp /dev/null $cestart_201"	

        # Backup cestart.201
        cestart_201_BKP=$cestart_201.NYAUTOCONFIG
        if [ ! -f $cestart_201_BKP ];then
                su - smsc -c "DFcat cestart.201 >! $cestart_201_BKP"
        fi

        cestart_201_CURRENT=$cestart_201.CURRENT
        su - smsc -c "DFcat cestart.201 >! $cestart_201_CURRENT"

        num_of_map_hosts=${#cur_map_hosts[@]};
        iter=0          
        while [ $iter -lt $num_of_map_hosts ]
        do      
                map_host=${cur_map_hosts[${iter}]}
                grep -x ".CE $map_host" $cestart_201_CURRENT
		if [ $? -ne 0 ];then
                	exiting "ERROR: $map_host is configured as hostname in $UnitGroup_file, but is not configured as CE in cestart.201 !!!"
                fi

                ((++iter))
        done

        # Backup omni_watch.201
        omni_health_201=/home/omni/conf/omni_health.201
        omni_health_201_BKP=$omni_health_201.NYAUTOCONFIG
        su - smsc -c "cp -f $omni_health_201 $omni_health_201_BKP"

	cluster_inst=0
        ce_name=""
	while read line; do
        	echo $line >> $cestart_201;

        	echo $line  | grep "^.CE" > /dev/null 2>&1
        	if [ $? -eq 0 ];then
                	ce_name=`echo $line | awk '{ print $2 }'`
			echo ${cur_map_hosts[@]} | grep $ce_name > /dev/null 2>&1
        		if [ $? -ne 0 ];then
                		exiting "ERROR: $ce_name is configured as CE in cestart.201, but is not configured as hostname in $UnitGroup_file !!!"
        		fi
        	else
                	if [ ! -z $ce_name ];then
				configure_ce_instances
                        	ce_name=""
                	fi
        	fi
	done < $cestart_201_CURRENT;

	# Load cestart.201
	stderr=/tmp/stderr
        cp /dev/null $stderr
	su - smsc -c "cd /tmp ; DFconvert cestart.201" 2> $stderr
	if [ -s $stderr ];then
		exiting "ERROR: fail to convert cestart.201 !!!"
	fi

	print "Updating cestart.201 with MAP instances" >> $activity_log

	return
}



configure_sfe_group()
{
	if [ "$#" -ne 1 ];then
 		exiting "Usage: configure_sfe_group  MRE/sfe/HLRC"
	fi

	application=$1
	case $application in
	MRE)
		set -A hosts `$parser $UnitGroup_file l/MRE//Hostname -U`
		first_port=5556
		;;
	sfe)
                set -A hosts `$parser $UnitGroup_file v/sfe//VHostname -U` 
		echo ${hosts[@]} | grep -i ERROR > /dev/null 2>&1
		if [ $? -eq 0 ];then
			virtual=false
			set -A hosts `$parser $UnitGroup_file l/sfe//Hostname -U`
		else
                        virtual=true
		fi
		first_port=2401
                ;;
        HLRC)    
                #set -A hosts `$parser $UnitGroup_file l/HLRC//Hostname -U`
		set -A hosts ${cur_hlrc_hosts[@]}
                first_port=4600
                ;;      
	*)
		exiting "Usage: configure_sfe_group  MRE/sfe/HLRC"
		;;
	esac

        echo ${hosts[@]} | grep -i ERROR > /dev/null 2>&1
        if [ $? -eq 0 ];then
		print "$application instances are not configured" >> $activity_log
		return
        fi

        instances="" 
        num_of_hosts=${#hosts[@]};
	if [ ${application} == "HLRC" -a ${num_of_hosts} -eq 0 ];then
		print "WARNING: no HLRC host configured for the current group" >> $activity_log
	fi
        host=0
        while [ $host -lt $num_of_hosts ]
        do
                host_name=${hosts[${host}]}

		case $application in
       		MRE|HLRC)
			num_of_insts=`$parser $UnitGroup_file l/$application/$host_name/InstanceName -U -C`
                ;;
		sfe)
			if [ $virtual == "true" ];then
				num_of_insts=`$parser $UnitGroup_file v/sfe/$host_name/InstanceName -U -C`
				host_name=`$parser $UnitGroup_file v/sfe/$host_name/Data/VHostname -U`
			else
				num_of_insts=`$parser $UnitGroup_file l/sfe/$host_name/InstanceName -U -C`
			fi
		;;
		esac

                inst=0
		if [ $application != "sfe" -o $host -eq 0 ]; then
                	port=$first_port
		fi
                while [ $inst -lt $num_of_insts ]
                do
                        ((++sfe_num))

                        grep "^[[:space:]]*MAP.sfe_host_name.$sfe_num[[:space:]]*=" $conn_config
                        if [ $? -eq 0 ];then
				su - smsc -c "smsc -nobanner -class MAP rm_set MAP.sfe_host_name.$sfe_num=$host_name"
			else
                        	print "\nMAP.sfe_host_name.$sfe_num=$host_name" >> $conn_config
			fi

                        grep "^[[:space:]]*MAP.sfe_ei_tcp_port_number.$sfe_num[[:space:]]*=" $conn_config
                        if [ $? -eq 0 ];then
                                su - smsc -c "smsc -nobanner -class MAP rm_set MAP.sfe_ei_tcp_port_number.$sfe_num=$port"
                        else
                                print "MAP.sfe_ei_tcp_port_number.$sfe_num=$port" >> $conn_config
                        fi      

                        grep "^[[:space:]]*MAP.sfe.$sfe_num.prefix[[:space:]]*=" $sfe_inst_config
                        if [ $? -eq 0 ];then
                                su - smsc -c "smsc -nobanner -class MAP rm_set MAP.sfe.$sfe_num.prefix="
                                print "Clearing parameter MAP.sfe.$sfe_num.prefix" >> $activity_log
                        fi

                        if [ -z $instances ];then
                                instances=$sfe_num
                        else
	                        instances="$instances,$sfe_num"
                        fi

                        print "Configuring parameters: \
			       \nMAP.sfe_host_name.$sfe_num=$host_name \nMAP.sfe_ei_tcp_port_number.$sfe_num=$port" >> $activity_log

                        ((++inst))
                        ((++port))
                done

                ((++host))
        done


        if [ -z $instances ];then
		if [ ${application} == "HLRC" ]; then
			print "WARNING: HLRC is not configured as sfe instance" >> $activity_log
                	
		else
			exiting "ERROR: fail to configure sfe instances of $application !!!"
		fi
        fi

        ((++num_of_sfe_groups))
	grep "^[[:space:]]*MAP.sfe_group.$num_of_sfe_groups.instances[[:space:]]*=" $sfe_inst_config
        if [ $? -eq 0 ];then
                su - smsc -c "smsc -nobanner -class MAP rm_set MAP.sfe_group.$num_of_sfe_groups.instances=$instances"
	else
                print "\nMAP.sfe_group.$num_of_sfe_groups.instances=$instances" >> $sfe_inst_config
	fi

        grep "^[[:space:]]*MAP.sfe_group.$num_of_sfe_groups.multiple_sfes_enabled[[:space:]]*=" $sfe_inst_config
        if [ $? -eq 0 ];then
                su - smsc -c "smsc -nobanner -class MAP rm_set MAP.sfe_group.$num_of_sfe_groups.multiple_sfes_enabled=yes"
        else
                print "MAP.sfe_group.$num_of_sfe_groups.multiple_sfes_enabled=yes" >> $sfe_inst_config
        fi

        print "Configuring parameters: \
	       \nMAP.sfe_group.$num_of_sfe_groups.instances=$instances \
	       \nMAP.sfe_group.$num_of_sfe_groups.multiple_sfes_enabled=yes" >> $activity_log

        if [ $application == "MRE" ]; then
                su - smsc -c "smsc -nobanner -class MAP rm_set MAP.sfe_group.1.routing_mechanism=3"
                print "Configuring MAP.sfe_group.1.routing_mechanism=3" >> $activity_log
        elif [ $application == "sfe" ]; then
		grep "^[[:space:]]*MAP.sfe_group.$num_of_sfe_groups.routing_mechanism[[:space:]]*=" $sfe_inst_config
		if [ $? -eq 0 ];then
			su - smsc -c "smsc -nobanner -class MAP rm_set MAP.sfe_group.$num_of_sfe_groups.routing_mechanism=2"
		else
			print "MAP.sfe_group.$num_of_sfe_groups.routing_mechanism=2" >> $sfe_inst_config
		fi

		su - smsc -c "smsc -nobanner -class MAP rm_set ALERT.standard_sfe_group=$num_of_sfe_groups"

		grep "^[[:space:]]*MAP.sfe_group.$num_of_sfe_groups.broadcast_alerts[[:space:]]*=" $sfe_inst_config
		if [ $? -eq 0 ];then
			su - smsc -c "smsc -nobanner -class MAP rm_set MAP.sfe_group.$num_of_sfe_groups.broadcast_alerts=yes"
		else
			print "MAP.sfe_group.$num_of_sfe_groups.broadcast_alerts=yes" >> $sfe_inst_config
		fi

        	print "Configuring parameters: \
               	       \nMAP.sfe_group.$num_of_sfe_groups.routing_mechanism=2 \
               	       \nALERT.standard_sfe_group=$num_of_sfe_groups \
                       \nMAP.sfe_group.$num_of_sfe_groups.broadcast_alerts=yes" >> $activity_log
	else #HLRC
                su - smsc -c "smsc -nobanner -class MAP rm_set HLR_CACHE.standard_sfe_group=$num_of_sfe_groups"
                print "Configuring HLR_CACHE.standard_sfe_group=$num_of_sfe_groups" >> $activity_log
	fi

        return
}



configure_sfes()
{                               
        sfe_num=0               
        conn_config=/home/smsc/site/config/MAP/site.MAP.sfe_inst.config
	sfe_inst_config=/home/smsc/site/config/MAP/site.MAP.sfe_inst.config
        num_of_sfe_groups=0

        #configure MREs
#configure_sfe_group MRE
	mre_group=$num_of_sfe_groups

        #Configure SFEs
	configure_sfe_group sfe

        #configure HLRCs
#configure_sfe_group HLRC

        if [ $num_of_sfe_groups == 0 ];then
                exiting "ERROR: System isn't configured with MRE or SFE hosts !!!"
        fi

        if [ $sfe_num -ne 1 ];then
                su - smsc -c "smsc -nobanner -class MAP rm_set MAP.number_of_sfes=$sfe_num"
                print "Configuring MAP.number_of_sfes=$sfe_num" >> $activity_log
        fi

        if [ $num_of_sfe_groups -ne 1 ];then
                su - smsc -c "smsc -nobanner -class MAP rm_set MAP.number_of_sfe_groups=$num_of_sfe_groups"
		print "Configuring MAP.number_of_sfe_groups=$num_of_sfe_groups"	 >> $activity_log
        fi

        return
}



delete_unused_files()
{
        set -A host_applications `$parser $UnitGroup_file a/$hostname`
        if [ ${#host_applications[@]} -eq 0 ];then
                exiting "ERROR: No application is configured for this host $hostname !!!"
        fi

	echo ${host_applications[@]} | grep MAP > /dev/null 2>&1
        if [ $? -ne 0 ];then
                exiting "ERROR: MAP is not configured at all for this host $hostname !!!"
	fi

      	set -A application_insts `$parser $UnitGroup_file l/MAP/$hostname/InstanceName -U`
        echo ${application_insts[@]} | grep 1.1 > /dev/null 2>&1
        if [ $? -ne 0 ];then
                su - smsc -c "rm -rf ~/site/config/MAP.1.1 ; \
                              rm -f ~/site/config/sms_declare/MAP.1.1_ccm-declare.xml ; \
                              rm -rf ~/site/trace/MAP.1.1" 
                print "MAP.1.1 is not configured for this host $hostname so deleting its config and trace directories and ccm-declare file" >> $activity_log
	fi


        for application in IS41 CTRL HLRC MEAS2XML; do
                echo ${host_applications[@]} | grep $application > /dev/null 2>&1
                if [ $? -ne 0 ];then
                        # Delete config & trace directories and ccm-declare files
                        su - smsc -c "rm -rf ~/site/config/${application}* ; \
				      rm -rf ~/site/config/sms_declare/${application}* ; \
                                      rm -rf ~/site/trace/${application}*"
                        print "$application is not configured for this host $hostname. Deleting its config and trace directories and ccm-declare files" >> $activity_log
                else
                        set -A application_insts `$parser $UnitGroup_file l/$application/$hostname/InstanceName -U`
                        echo ${application_insts[@]} | grep 1.1 > /dev/null 2>&1
                        if [ $? -ne 0 ];then
                        su - smsc -c "rm -rf ~/site/config/${application}.1.1 ; \
                                      rm -f ~/site/config/sms_declare/${application}.1.1_ccm-declare.xml ; \
                                      rm -rf ~/site/trace/${application}.1.1"
                        print "$application is configured for this host $hostname, but not for instance 1.1 so deleting config and trace directories and ccm-declare file of ${application}.1.1" >> $activity_log
                        fi
                fi
        done

        return
}



configure_protocol()
{
	PROTOCOL=C7
	if [ `rpm -qa | grep OMNI-A7` ];then
		PROTOCOL=A7
	elif [ `rpm -qa | grep OMNI-J7` ];then
		PROTOCOL=J7
	elif [ `rpm -qa | grep OMNI-CH7` ];then
		PROTOCOL=CH7
	fi

	print "The protocol installed by OMNI is $PROTOCOL" >> $activity_log
	if [ $PROTOCOL == C7 ];then
		print "C7 is already configured by default" >> $activity_log
		return
	fi

        protocol=`echo $PROTOCOL | tr '[:upper:]' '[:lower:]'`
	su - smsc -c "smsc -nobanner rm_set omni_protocol=$protocol ; smsc -nobanner rm_set omni_node=$PROTOCOL"
	print "Configuring omni_protocol and omni_node parameters with $protocol and $PROTOCOL respectively" >> $activity_log

	protocol_conf_files=`grep -r C7 /home/smsc/site/config/MAP* | grep -v "#" | awk -F: '{print $1}'|uniq`
	if [ -z "$protocol_conf_files" ];then
		return
	fi

	for file in $protocol_conf_files
	do
		sed -i s/C7/$PROTOCOL/g $file
		print "Replacing protocol configuration of C7 with $PROTOCOL in $file" >> $activity_log
	done
		
        return
}


collect_cur_map_hosts()
{
	#extract from UnitGroup all MAP and HLRC hosts 
	set -A map_hosts `$parser $UnitGroup_file l/MAP//Hostname -U`
	set -A hlrc_hosts `$parser $UnitGroup_file l/HLRC//Hostname -U`
	echo ${map_hosts[@]} | grep -i ERROR > /dev/null 2>&1
	if [ $? -eq 0 ];then
             exiting "ERROR: MAP hosts are not configured at all in $UnitGroup_file !!!"
	fi
	echo ${hlrc_hosts[@]} | grep -i ERROR > /dev/null 2>&1
	if [ $? -eq 0 ];then
             print "WARNING: HLRC hosts are not configured at all in $UnitGroup_file !!!" >> $activity_log
	     hlrc_configured=false
	     set -A cur_hlrc_hosts ${hlrc_hosts[@]}
	else
	     hlrc_configured=true		
	fi
	#Ensure the current host is listed in UnitGroup MAP hosts list
	echo ${map_hosts[@]} | grep ${hostname} > /dev/null 2>&1
	if [ $? -ne 0 ];then
             exiting "ERROR: MAP host ${hostname} is not configured at all in $UnitGroup_file !!!"
	fi
	num_of_map_hosts=${#map_hosts[@]}
	num_of_hlrc_hosts=${#hlrc_hosts[@]}

	#Extract the MAP groups names from UnitGroup
	set -A cur_map_groups `$parser $UnitGroup_file l/MAP//ParentGroup -U`
	num_groups=${#cur_map_groups[@]}
	

	#If there is only one MAP group no further action needed.
	#If there are more than 1 group, create array with only relevant for the current group MAP/HLRC hosts
	if [ ${num_groups} == 1 ];then
        	print "Only one MAP group" >> $activity_log
		set -A cur_map_hosts ${map_hosts[@]}
		if [  $hlrc_configured == true ];then
			set -A cur_hlrc_hosts ${hlrc_hosts[@]}
		fi	
	else
		#Extract from UnitGroup the current MAP host's group
		cur_map_group=`$parser $UnitGroup_file l/MAP/${hostname}/ParentGroup -U`
        	print "Current MAP group: ${cur_map_group}" >> $activity_log

        	set -A cur_hlrc_hosts

		if [ ${hlrc_configured} == true ];then
			#In the case there is 1 HLRC server per MAP group
			if [ ${num_groups} == ${num_of_hlrc_hosts} ]; then
				set -A cur_hlrc_hosts
				iter=0
				while [ $iter -lt $num_of_hlrc_hosts ]
				do
					hlrc_group=`$parser $UnitGroup_file l/HLRC/${hlrc_hosts[${iter}]}/ParentGroup -U`
			                if [ ${cur_map_group} ==  ${hlrc_group} ];then
						cur_hlrc_hosts[0]=${hlrc_hosts[${iter}]}
					fi
					((++iter))
				done	
				hlrc_configured=false

			elif [ ! ${num_of_map_hosts} == ${num_of_hlrc_hosts} ]; then
				exiting "Number of HLRC hosts is not equal neither to MAP hosts, nor to MAP groups" 
			fi
		fi
        	set -A cur_map_hosts
        	iter=0
		cur_map_iter=0
		cur_hlrc_iter=0
        	while [ $iter -lt $num_of_map_hosts ]
        	do
                	map_group=`$parser $UnitGroup_file l/MAP/${map_hosts[${iter}]}/ParentGroup -U`

	                if [ ${cur_map_group} ==  ${map_group} ];then
				cur_map_hosts[${cur_map_iter}]=${map_hosts[${iter}]}
				((++cur_map_iter))
                	fi

			if [ ${hlrc_configured} == true ];then
                		hlrc_group=`$parser $UnitGroup_file l/HLRC/${hlrc_hosts[${iter}]}/ParentGroup -U`
	                	if [ ${cur_map_group} ==  ${hlrc_group} ];then
					cur_hlrc_hosts[${cur_hlrc_iter}]=${hlrc_hosts[${iter}]}
					((++cur_hlrc_iter))
                		fi
			fi
                	((++iter))
        	done
	fi
}

# -----Main of the script -----

# Variable Definition

UnitGroup_file="/usr/cti/conf/autoconf/UnitGroup.xml"
parser="/home/smsc/autoconfig.all/scripts/parser.pl"
activity_log=/var/cti/logs/auto_config-MAP.log
hostname=`hostname`

#Collect relevant for a MAP group hosts only
collect_cur_map_hosts
print "Current MAP hosts group: ${cur_map_hosts[@]}" >> $activity_log

echo [`date +"%d-%m-%Y %H:%M:%S"`] '************ Starting MAP automatic configuration ************' >> $activity_log
configure_ces_instances
configure_sfes
delete_unused_files
configure_protocol
echo [`date +"%d-%m-%Y %H:%M:%S"`] '************* Ending MAP automatic configuration *************' >> $activity_log

exit 0
