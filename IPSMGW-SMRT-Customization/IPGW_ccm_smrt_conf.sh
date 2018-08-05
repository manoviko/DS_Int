#!/bin/bash

#CCM configuration to support IPGW SMRT editor changes in /usr/cti/conf/ccm-app/ccmAppl.config file
file="/usr/cti/conf/ccm-app/ccmAppl.config"

Date=`date '+%d%m%Y%H%M'`
echo "WARN : /usr/cti/conf/ccm-app/ccmAppl.config exists. Backup it as /usr/cti/conf/ccm-app/ccmAppl.config.${Date}"
/bin/cp -f /usr/cti/conf/ccm-app/ccmAppl.config /usr/cti/conf/ccm-app/ccmAppl.config.${Date}

if [ ! "`grep "^CCM.*IPGW_SMRT.*fullFilePath" $file |grep "=IPGW"`" ]; then
  #sed -i '/^CCM.config_editor_list/s/CCS_Configuration_Tool,SCA_EX_EDITOR/CCS_Configuration_Tool,SCA_EX_EDITOR,IPGW_SMRT/' >> $file
  sed -i 's/CCS_Configuration_Tool,SCA_EX_EDITOR/CCS_Configuration_Tool,SCA_EX_EDITOR,IPGW_SMRT/' $file
  echo CCM.config_editor.IPGW_SMRT.type = remote_url >> $file
  echo "CCM.config_editor.IPGW_SMRT.path = /console/modules/controlPanel/smrt/index_ccmng.jsp?ccm=true&fullFilePath=IPGW" >> $file
  echo CCM.config_editor.IPGW_SMRT.port = 8030  >> $file
  echo CCM.config_editor.IPGW_SMRT.protocol = https  >> $file
  echo "CCM.config_editor.IPGW_SMRT.host = ##HOST##"  >> $file
  echo CCM.config_editor.IPGW_SMRT.create_reference_topic = false  >> $file
fi