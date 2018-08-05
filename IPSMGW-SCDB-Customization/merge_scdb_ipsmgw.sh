#!/bin/bash

host=`hostname`
ipsm_system_type=HA

templ_temp_dir=/var/tmp/SCDB_Customization/IPSMGW
templ_dir=/usr/cti/apps/omap_maint/scdb/data/templates/IPSMGW
scdb_ha_name=IPSMGW_scdb.xml
scdb_ocs_name=IPSMGW_OCS_scdb.xml

scdb_loc=/usr/cti/apps/omap_maint/scdb/data/scdb.xml

cluster_res=TomcatSCDB

ds=`date '+%y%m%d-%H%M%S'`

##############################
check_if_install () {
##############################
	#test if scdb should be merged on this node
	if [ "`/opt/VRTS/bin/hares -state $cluster_res|grep -w ONLINE`" ]; then
		
		if [ "`/opt/VRTS/bin/hares -state $cluster_res|grep -w ONLINE|grep $host`" ]; then
			echo " -I- $cluster_res is running on this node, starting scdb merge"
		else
			echo " -I- $cluster_res is running on another node, nothing to do here"
			exit 0
		fi

	else

		echo " -E- $cluster_res seems to be down in cluster..."
		exit 1

	fi
}

##############################
check_var () {
##############################

	local name=$1
	local var=$2
	
	if [ "X$var" == "X" ]; then
		echo " -E- $name is not initialized in /root/.bash_profile"
		exit 1
	else
		echo " -I- $name has value $var"
	fi

}
	
##############################	
check_prereq () {
##############################

	if [ ! -f $scdb_loc ]; then
		echo " -E- Failed to find scdb.xml on $scdb_loc"
		exit 1
	fi
		
	if [ ! -d $templ_temp_dir ]; then
		echo " -E- $templ_temp_dir should exist and contain all template files"
		exit 1
	fi

	if [ ! -d $templ_dir ]; then
		echo " -I- $templ_dir does not exists, creating it"
		mkdir -p $templ_dir
	fi

	if [ $ipsm_system_type == "HA" ]; then
		echo " -I- Moving $templ_temp_dir/$scdb_ha_name to $templ_dir/scdb.xml"
		/bin/mv -f $templ_temp_dir/$scdb_ha_name $templ_dir/scdb.xml
	elif [ $ipsm_system_type == "OCS" ]; then
		echo " -I- Moving $templ_temp_dir/$scdb_ocs_name to $templ_dir/scdb.xml"
		/bin/mv -f $templ_temp_dir/$scdb_ocs_name $templ_dir/scdb.xml
	else
		echo " -E- $ipsm_system_type is not supported"
		exit 1
	fi
	
	if [ $? -ne 0 ]; then
		echo " -E- Failed to copy template from $templ_dir"
		exit 1
	fi
	
	##Get Shared MVAS system name
	`source /root/.bash_profile`
	
	check_var MVAS_DOMAIN_NAME $MVAS_DOMAIN_NAME
	mvas_domain=${MVAS_DOMAIN_NAME}
	
	check_var MVAS_SITE_NAME $MVAS_SITE_NAME
	check_var MVAS_NATCO_NAME $MVAS_NATCO_NAME
	mvas_system=${MVAS_SITE_NAME}-${MVAS_NATCO_NAME}
	
	check_var MVAS_NATCO_NAME $MVAS_NATCO_NAME
	customer=${MVAS_NATCO_NAME}

}
##############################	
update_templ () {
##############################
	
	sed -i.ipsm_${ds} -e 's/SYSTEM/'$mvas_system'/g' -e 's/comverse.com/'$mvas_domain'/g' -e 's/CUSTOMER/'$customer'/g' $templ_dir/scdb.xml
	if [ $? -ne 0 ]; then
		echo " -E- There was a problem to update $templ_dir/scdb.xml"
		exit 1
	else	
		echo " -I- Successfully updated $templ_dir/scdb.xml"
	fi
}

##############################
merge_scdb () {
##############################

	chown -R scdb_user:scdb $templ_dir
	
	echo " -I- Backup $scdb_loc to $scdb_loc.before_ipsm_megre.$ds"
	/bin/cp -f $scdb_loc $scdb_loc.before_ipsm_megre.$ds
	
	su - scdb_user -c "/usr/cti/apps/scdb/bin/scdb.sh Merge -to $scdb_loc -from $templ_dir/scdb.xml"
	if [ $? -ne 0 ]; then
		echo " -E- Merge from $templ_dir/scdb.xml to $scdb_loc FAILED!"
		exit 1
	else
		echo " -E- Merge from $templ_dir/scdb.xml to $scdb_loc succeeded"
	fi

}

#### main
check_if_install
check_prereq
update_templ
merge_scdb	
	