#!/bin/bash
# Written by Gregory Danenberg, the script updates limits.conf (updated version)
#Updated to use /etc/security/limits.d intead of limits.conf


Date=`date '+%d%m%Y%H%M'`
limitDir=/etc/security/limits.d

while getopts ":u:f:p:h" opt; do
	case $opt in
		u)
			export APP_USER=$OPTARG; echo "INFO: user is set to $APP_USER";
			export APP_FILE=${limitDir}/${APP_USER}.conf
			;;
		f) 
			export NOFILE_DEF=$OPTARG; echo "INFO: nofile is set to $NOFILE_DEF";
			;;
		p) 
			export NPROC_DEF=$OPTARG; echo "INFO: nproc is set to $NPROC_DEF";
			;;
	    \?)
			echo "Invalid option: -$OPTARG"
			exit 1
			;;
		:)
			echo "Option -$OPTARG requires an argument"
			exit 1
			;;
		h) 
			echo "USAGE: $0 -u [user] -f <nofile value> -p <nproc value>"; 
			exit 1
			;;
		*)
			echo "USAGE: $0 -u [user] -f <nofile value> -p <nproc value>"; 
			exit 1 
			;;

	esac
done

if [ -z $APP_USER ]; then
	echo "USAGE: $0 -u [user] -f <nofile value> -p <nproc value>"
	exit 1
fi
	
getent passwd $APP_USER >/dev/null
if [ $? -ne 0 ]; then
	echo "INFO: User $APP_USER does not exist on this server..."
	exit 1
fi

if [[ "`hostname`" =~ "[oO][mM][Uu]" ]] && [ $APP_USER == "smsc" ] ; then
	echo "INFO: No need to update smsc user on OMU server"
	exit 0
fi

checkStatus() {
#get status
	rc=$1
	txt=$2
	
	if [ $rc -ne 0 ]; then
		echo "ERROR: Failed $2"
		exit 1
	else
		echo "INFO: Succeeded $2"
	fi
}

test_file() {

	if [ ! -f $APP_FILE ]; then
		touch $APP_FILE
		checkStatus $? "adding file $APP_FILE"
		
		echo "## The file created by SEM kit ##" >> $APP_FILE
	fi

}


add_value () {

	param=$1
	val=$2

	echo -e "$APP_USER\t-\t$param\t$val" >> $APP_FILE
	checkStatus $? "adding $param with $val value for $APP_USER user in $APP_FILE"	
	

}

update_value() {

	param=$1
	val=$2
	
	test_value $param $val
	if [ $? -eq 1 ]; then	
		sed -i 's/\('$APP_USER'.*'$param'\s*\)[0-9]\{1,\}/\1'$val'/' $APP_FILE
		checkStatus $? "updating $param with $val value for $APP_USER user in $APP_FILE"
	else
		echo "INFO: $param has already $val value for $APP_USER user in $APP_FILE"
	fi	

}

test_value() {

	param=$1
	val=$2
		
	if [ $val ]; then
		grep -P "^$APP_USER.*$param\s+$val" $APP_FILE > /dev/null
		rc=$?
	else
		grep -P "^$APP_USER.*$param\s+\d+" $APP_FILE > /dev/null
		rc=$?
	fi
	
	return $rc	

}


#####  MAIN
test_file

if [ ! -z $NOFILE_DEF ]; then
	
	test_value nofile
	test $? -eq 0 && update_value nofile $NOFILE_DEF || add_value nofile $NOFILE_DEF
fi

if [ ! -z $NPROC_DEF ]; then
	
	test_value nproc
	test $? -eq 0 && update_value nproc $NPROC_DEF || add_value nproc $NPROC_DEF

fi


