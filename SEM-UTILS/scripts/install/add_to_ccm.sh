#!/bin/bash
# Written b Gregory Danenberg, 20/2012
# The script adds SEM component to the ccm

COMP_NAME=$1
MODE=$2
INST_ID=$3

if [ $# -lt 3  ] ; then
    echo "USAGE: $0 [COMPONENT NAME] [INSTALL MODE] [INSTANCE ID]"
    exit 1
fi

INST_ID=${INST_ID%%\.*}

COMP_DECL_NAME=$(echo ${COMP_NAME}|tr [:lower:] [:upper:])
DECL_DIR=/usr/cti/conf/${COMP_NAME}/${COMP_NAME}_declare
DECL_FILE=${DECL_DIR}/${COMP_DECL_NAME}_ccm-declare.xml

CCM_DECL_DIR=/usr/cti/conf/ccm-register/${COMP_NAME}_declare

if [ -z $COMP_NAME ]; then
	echo "	USAGE: $0 [component name] "
	exit 1
fi

if [ ! -d $DECL_DIR ]; then
	echo "ERROR: Not found ccm declarations for ${COMP_NAME} : $DECL_DIR "
	exit 1
fi

if [ ! -h $CCM_DECL_DIR ]; then
	test ! -d /usr/cti/conf/ccm-register && mkdir -p /usr/cti/conf/ccm-register && chmod 755 /usr/cti/conf/ccm-register
	ln -s $DECL_DIR $CCM_DECL_DIR
	if [ $? -eq 0 ]; then
		echo "INFO: Created link between $CCM_DECL_DIR and $DECL_DIR"
	else
		echo "ERROR: Failed to create link between $CCM_DECL_DIR and $DECL_DIR"
		exit 1
	fi
fi

if [ -f $DECL_FILE ]; then
	echo "INFO: $DECL_FILE exists,  assuming fresh installation"
	
	if [ $MODE == "Provisioning" ]; then
		echo "INFO: Creating ${DECL_DIR}/${COMP_DECL_NAME}PROV.${INST_ID}_ccm-declare.xml"
		/bin/mv -f $DECL_FILE ${DECL_DIR}/${COMP_DECL_NAME}PROV.${INST_ID}_ccm-declare.xml
		sed -i 's/name=\"'$COMP_DECL_NAME'\"/name=\"'$COMP_DECL_NAME'PROV.'$INST_ID'\"/' ${DECL_DIR}/${COMP_DECL_NAME}PROV.${INST_ID}_ccm-declare.xml
		chmod o+r ${DECL_DIR}/${COMP_DECL_NAME}PROV.${INST_ID}_ccm-declare.xml
	else
		echo "INFO: Creating ${DECL_DIR}/${COMP_DECL_NAME}.${INST_ID}_ccm-declare.xml"
		/bin/mv -f $DECL_FILE ${DECL_DIR}/${COMP_DECL_NAME}.${INST_ID}_ccm-declare.xml
		sed -i 's/name=\"'$COMP_DECL_NAME'\"/name=\"'$COMP_DECL_NAME'.'$INST_ID'\"/' ${DECL_DIR}/${COMP_DECL_NAME}.${INST_ID}_ccm-declare.xml
		chmod o+r ${DECL_DIR}/${COMP_DECL_NAME}.${INST_ID}_ccm-declare.xml
	fi
fi

 