#!/bin/bash

JAVA_DIR=$1

if [ -z $JAVA_DIR ]; then
	echo "USAGE: `basename $0` <Java home directory>"
	exit 1
fi

if [ -d $JAVA_DIR ]; then
	
	test -L /usr/local/java && unlink /usr/local/java
	ln -s $JAVA_DIR /usr/local/java || exit 1
	echo "INFO: Set link /usr/local/java to $JAVA_DIR"
	
	if [ ! -f /usr/local/java/bin/java ]; then
		echo "ERROR: Unable to find /usr/local/java/bin/java after link creation"
		exit 2
	fi
else
	echo "ERROR: $JAVA_DIR does not exist"
fi
