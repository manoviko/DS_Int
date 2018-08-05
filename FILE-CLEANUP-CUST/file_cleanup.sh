#!/bin/bash

#Written by Inna Kushner, 11/11/2012
#Updated on 17/06/2015: 


UnitType=$1

if [ -z $UnitType ]; then
	echo "ERROR: You have to supply UnitType, for example: ISU_Group,MAP_Group..."
fi

#execute on all type of servers


case $UnitType in

	 ISU_Group)
			echo "INFO : Executing customization clean up for $UnitType"
			/usr/cti/apps/CSPbase/csp_gen_filecleanup.pl --add --directory=/var/cti/smsc/site/trace/stats  --age=days=2 --pattern=* --action=delete --sub=yes --log=no
			/usr/cti/apps/CSPbase/csp_gen_filecleanup.pl --add --directory=/var/cti/smsc/site/trace/IPGW/stats --age=days=2 --pattern=stats.IPGW.* --action=delete --sub=yes --log=no
			/usr/cti/apps/CSPbase/csp_gen_filecleanup.pl --add --directory=/var/cti/smsc/site/trace/IPGW/logs --age=days=2 --pattern=IPGW.* --action=delete --sub=yes --log=no
			/usr/cti/apps/CSPbase/csp_gen_filecleanup.pl --add --directory=/var/cti/smsc/site/trace/cdr --age=days=2 --pattern=* --action=delete --sub=yes --log=no
			#/usr/cti/apps/CSPbase/csp_gen_filecleanup.pl --add --directory=/var/cti/smsc/site/trace/backup_dir  --age=days=3 --pattern=* --action=delete --sub=yes --log=no
			id=`cd /var/cti/smsc/site/trace/; ls -l|grep IPGW|grep -v IPGW_ |cut -d "." -f 2,3|grep -v log`
			#/usr/cti/apps/CSPbase/csp_gen_filecleanup.pl --add --directory=/var/cti/smsc/site/trace/IPGW.${id}/stats --age=days=2 --pattern=stats.IPGW.* --action=delete --sub=yes --log=no
			/usr/cti/apps/CSPbase/csp_gen_filecleanup.pl --add --directory=/var/cti/smsc/site/trace/IPGW/header --age=days=2 --pattern=msg_trace.log.header.IPGW.* --action=delete --sub=yes --log=no
			/usr/cti/apps/CSPbase/csp_gen_filecleanup.pl --add --directory=/var/cti/smsc/site/trace/IPGW/header/badFiles --age=days=2 --pattern=msg_trace.log.header.IPGW.* --action=delete --sub=yes --log=no
			/usr/cti/apps/CSPbase/csp_gen_filecleanup.pl --add --directory=/var/cti/smsc/site/trace/IPGW/event --age=days=2 --pattern=msg_trace.log.event.IPGW.* --action=delete --sub=yes --log=no
			/usr/cti/apps/CSPbase/csp_gen_filecleanup.pl --add --directory=/var/cti/smsc/site/trace/IPGW/event/badFiles --age=days=2 --pattern=msg_trace.log.event.IPGW.* --action=delete --sub=yes --log=no
			;;
	 MAP_Group) 
			echo "INFO : Executing customization clean up for $UnitType"
			/usr/cti/apps/CSPbase/csp_gen_filecleanup.pl --add --directory=/var/cti/smsc/site/trace/MAP/stats --age=days=2 --pattern=stats.MAP.* --action=delete --sub=yes --log=no
			#id=`cd /var/cti/smsc/site/trace/; ls -l|grep MAP|grep -v MAP_ |cut -d "." -f 2,3|grep -v log`
			#/usr/cti/apps/CSPbase/csp_gen_filecleanup.pl --add --directory=/var/cti/smsc/site/trace/MAP.${id}/header  --age=days=2 --pattern=msg_trace.log.header.MAP.* --action=delete --sub=yes --log=no
			#/usr/cti/apps/CSPbase/csp_gen_filecleanup.pl --add --directory=/var/cti/smsc/site/trace/MAP.${id}/header/badFiles  --age=days=2 --pattern=msg_trace.log.header.MAP.* --action=delete --sub=yes --log=no
			#/usr/cti/apps/CSPbase/csp_gen_filecleanup.pl --add --directory=/var/cti/smsc/site/trace/MAP.${id}/event  --age=days=2 --pattern=msg_trace.log.event.MAP.* --action=delete --sub=yes --log=no
			#/usr/cti/apps/CSPbase/csp_gen_filecleanup.pl --add --directory=/var/cti/smsc/site/trace/MAP.${id}/event/badFiles  --age=days=2 --pattern=msg_trace.log.event.MAP.* --action=delete --sub=yes --log=no
			#/usr/cti/apps/CSPbase/csp_gen_filecleanup.pl --add --directory=/var/cti/logs/sng/stats  --age=days=2 --pattern=* --action=delete --sub=yes --log=no
			;;
	 	 Shared_OMU_Group)
			echo "INFO : Executing customization clean up for OMU_Group"
			#/usr/cti/apps/CSPbase/csp_gen_filecleanup.pl --add --directory=/data/omap_stats --age=days=90 --pattern=* --action=delete --sub=yes --log=no
			#/usr/cti/apps/CSPbase/csp_gen_filecleanup.pl --add --directory=/data/omap_stats/MAP --age=days=7 --pattern=* --action=delete --sub=yes --log=no
			#/usr/cti/apps/CSPbase/csp_gen_filecleanup.pl --add --directory=/data/omap_stats/IPGW --age=days=7 --pattern=* --action=delete --sub=yes --log=no
			/usr/cti/apps/CSPbase/csp_gen_filecleanup.pl --add --directory=/data/cdrs/IPSMGW --age=days=2 --pattern=* --action=delete --sub=yes --log=no
			/usr/cti/apps/CSPbase/csp_gen_filecleanup.pl --add --directory=/data/cdrs/IPSMGW/input --age=days=7 --pattern=* --action=delete --sub=yes --log=no
			/usr/cti/apps/CSPbase/csp_gen_filecleanup.pl --add --directory=/data/cdrs/IPSMGW/output --age=days=2 --pattern=* --action=delete --sub=yes --log=no
			/usr/cti/apps/CSPbase/csp_gen_filecleanup.pl --add --directory=/data/cdrs/IPSMGW/ascii_output --age=days=1 --pattern=* --action=delete --sub=yes --log=no
			/usr/cti/apps/CSPbase/csp_gen_filecleanup.pl --add --directory=/data/cdrs/IPSMGW/bad_records -age=days=7 --pattern=* --action=delete --sub=yes --log=no
			/usr/cti/apps/CSPbase/csp_gen_filecleanup.pl --add --directory=/data/cdrs/IPSMGW/backup -age=days=90 --pattern=* --action=delete --sub=yes --log=no
			/usr/cti/apps/CSPbase/csp_gen_filecleanup.pl --add --directory=/data/cdrs/IPSMGW/backup -age=days=2 --pattern=* --action=gzip --sub=yes --log=no 
			/usr/cti/apps/CSPbase/csp_gen_filecleanup.pl --add --directory=/data/files/traces/IPSMGW --age=days=2 --pattern=* --action=delete --sub=yes --log=no
			/usr/cti/apps/CSPbase/csp_gen_filecleanup.pl --add --directory=/data/files/stat/IPSMGW --age=days=2 --pattern=* --action=delete --sub=yes --log=no
			# add the following in case statistics are loaded into statistics DB
			#/usr/cti/apps/CSPbase/csp_gen_filecleanup.pl --add --directory=/data/omap_stats/MW-format/backup_dir  --age=days=2 --pattern=* --action=delete --sub=yes --log=no
			#/usr/cti/apps/CSPbase/csp_gen_filecleanup.pl --add --directory=/data/omap_stats/MW-format/bad_dir  --age=days=7 --pattern=* --action=delete --sub=yes --log=no
			#/usr/cti/apps/CSPbase/csp_gen_filecleanup.pl --add --directory=/data/omap_stats/MW-format/backup_dir --age=days=1 --pattern=* --action=gzip --sub=yes --log=no
			#/usr/cti/apps/CSPbase/csp_gen_filecleanup.pl --add --directory=/data/omap_stats/SHU-format/backup_dir  --age=days=2 --pattern=* --action=delete --sub=yes --log=no
			#/usr/cti/apps/CSPbase/csp_gen_filecleanup.pl --add --directory=/data/omap_stats/SHU-format/bad_dir  --age=days=7 --pattern=* --action=delete --sub=yes --log=no
			#/usr/cti/apps/CSPbase/csp_gen_filecleanup.pl --add --directory=/data/omap_stats/SHU-format/backup_dir --age=days=1 --pattern=* --action=gzip --sub=yes --log=no
			# add the following in case Trace2CSV is enabled
			#usr/cti/apps/CSPbase/csp_gen_filecleanup.pl --add --directory=/data/omap_trace/SEM/backup  --age=days=2 --pattern=* --action=delete --sub=yes --log=no
			#usr/cti/apps/CSPbase/csp_gen_filecleanup.pl --add --directory=/data/omap_trace/SEM/csv  --age=days=7 --pattern=* --action=delete --sub=yes --log=no
			#usr/cti/apps/CSPbase/csp_gen_filecleanup.pl --add --directory=/data/omap_trace/SEM/error  --age=days=7 --pattern=* --action=delete --sub=yes --log=no
			#usr/cti/apps/CSPbase/csp_gen_filecleanup.pl --add --directory=/data/omap_trace/SEM/backup --age=days=1 --pattern=* --action=gzip --sub=yes --log=no
			;;
	 SCA_Group)
			echo "INFO : Executing customization clean up for SHU_Group"
			#/usr/cti/apps/CSPbase/csp_gen_filecleanup.pl --add --directory=/var/cti/logs/cms/stats  --age=days=2 --pattern=* --action=delete --sub=yes --log=no
			#/usr/cti/apps/CSPbase/csp_gen_filecleanup.pl --add --directory=/var/cti/logs/sca_sip/stats  --age=days=2 --pattern=* --action=delete --sub=yes --log=no
			;;
	*)
			echo "WARN : Failed to find instructions for $UnitType"
			;;
esac 
